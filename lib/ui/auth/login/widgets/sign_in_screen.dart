import 'dart:async';

import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/routing/routes.dart';
import 'package:app/ui/auth/login/view_models/sign_in_viewmodel.dart';
import 'package:app/ui/auth/login/widgets/carousel_image_info.dart';
import 'package:app/ui/auth/login/widgets/carousel_image_item.dart';
import 'package:app/ui/core/themes/dimens.dart';
import 'package:app/ui/core/ui/app_snackbar.dart';
import 'package:app/ui/core/ui/generic_list_tile.dart';
import 'package:app/ui/core/ui/listenable_button.dart';
import 'package:app/ui/core/ui/text_field_with_label.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SignUpPage { credentials, interests, travelStyles }

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.viewModel});

  final SignInViewModel viewModel;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final CarouselController _carouselController = CarouselController(
    initialItem: 1,
  );

  final TextEditingController _signInIdentifierController =
      TextEditingController();
  final TextEditingController _signInPasswordController =
      TextEditingController();

  final TextEditingController _signUpFirstNameController =
      TextEditingController();
  final TextEditingController _signUpLastNameController =
      TextEditingController();
  final TextEditingController _signUpUsernameController =
      TextEditingController();
  final TextEditingController _signUpEmailController = TextEditingController();
  final TextEditingController _signUpPasswordController =
      TextEditingController();
  final TextEditingController _signUpConfirmPasswordController =
      TextEditingController();
  final List<Interest> _signUpInterests = [];
  final List<TravelStyle> _signUpTravelStyles = [];

  bool _isSignIn = true;
  SignUpPage currentPage = SignUpPage.credentials;

  Timer? _debounce;
  String? _usernameErrorText;

  final _autoPlayDuration = const Duration(seconds: 4);
  bool scrollBackwards = false;

  void _scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _toggleForm() async {
    setState(() {
      _isSignIn = !_isSignIn;
      if (!_isSignIn) {
        currentPage = SignUpPage.credentials;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollDown();
      }
    });
  }

  void _navigateToSignUpPage(SignUpPage page) {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        currentPage = page;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollDown();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.signIn.addListener(_onLoginResult);
    widget.viewModel.signUp.addListener(_onSignUpResult);
    widget.viewModel.isUsernameUnique.addListener(
      _onCheckUsernameUniquenessResult,
    );
    Timer.periodic(_autoPlayDuration, (_) => _animateToNextItem());
  }

  @override
  void didUpdateWidget(covariant SignInScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.signIn.removeListener(_onLoginResult);
    oldWidget.viewModel.signUp.removeListener(_onSignUpResult);
    oldWidget.viewModel.isUsernameUnique.removeListener(
      _onCheckUsernameUniquenessResult,
    );
    widget.viewModel.signIn.addListener(_onLoginResult);
    widget.viewModel.signUp.addListener(_onSignUpResult);
    widget.viewModel.isUsernameUnique.addListener(
      _onCheckUsernameUniquenessResult,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.viewModel.signIn.removeListener(_onLoginResult);
    widget.viewModel.signUp.removeListener(_onSignUpResult);
    widget.viewModel.isUsernameUnique.removeListener(
      _onCheckUsernameUniquenessResult,
    );
    _signInIdentifierController.dispose();
    _signInPasswordController.dispose();
    _signUpFirstNameController.dispose();
    _signUpLastNameController.dispose();
    _signUpUsernameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    _scrollController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String username) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      final trimmedUsername = username.trim();
      if (trimmedUsername.isEmpty) {
        _formKey.currentState?.validate();
        return;
      }
      widget.viewModel.isUsernameUnique.execute(trimmedUsername);
    });
  }

  void _animateToNextItem() {
    if (_carouselController.offset > 200) {
      scrollBackwards = true;
    } else if (_carouselController.offset < 50) {
      scrollBackwards = false;
    }

    _carouselController.animateTo(
      scrollBackwards
          ? _carouselController.offset - 50
          : _carouselController.offset + 50,
      duration: const Duration(milliseconds: 500),
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height / 3),
                child: CarouselView.weighted(
                  controller: _carouselController,
                  itemSnapping: true,
                  flexWeights: const <int>[1, 7, 1],
                  children:
                      CarouselImageInfo.values.map((CarouselImageInfo image) {
                        return CarouselImageItem(imageInfo: image);
                      }).toList(),
                ),
              ),
            ),
            Padding(
              padding: Dimens.of(context).edgeInsetsScreenSymmetric,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: Offset(_isSignIn ? -1.0 : 1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                child: _buildAnimatedContent(context),
              ),
            ),
            SizedBox(height: Dimens.paddingVertical * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedContent(BuildContext context) {
    Key currentKey;
    String title;
    String subtitle1;
    String subtitle2;
    Widget formContent;

    if (_isSignIn) {
      currentKey = const ValueKey('signInView');
      title = "Suroy.";
      subtitle1 = "suroy (v.) - a Cebuano word meaning \"to wander around\"";
      subtitle2 = "Sign in to plan your travels with ease.";
      formContent = _buildSignInForm(context);
    } else {
      switch (currentPage) {
        case SignUpPage.credentials:
          currentKey = const ValueKey('signUpCredentialsView');
          title = "Create Account";
          subtitle1 = "Let's get you started on your Suroy journey!";
          subtitle2 = "Please fill in your details below.";
          formContent = _buildSignUpForm(context);
          break;
        case SignUpPage.interests:
          currentKey = const ValueKey('signUpInterestsView');
          title = "Your Interests";
          subtitle1 = "Tell us what you love to do.";
          subtitle2 = "This helps personalize your Suroy experience.";
          formContent = _buildInterestsForm(context);
          break;
        case SignUpPage.travelStyles:
          currentKey = const ValueKey('signUpTravelStylesView');
          title = "Travel Styles";
          subtitle1 = "How do you prefer to explore?";
          subtitle2 = "Almost there! Define your travel preferences.";
          formContent = _buildTravelStylesForm(context);
          break;
      }
    }

    return Column(
      key: currentKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Dimens.paddingVertical * 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).hintColor,
                ),
              ),
              SizedBox(height: Dimens.paddingVertical / 2),
              Text(
                subtitle2,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              SizedBox(height: Dimens.paddingVertical),
              Form(key: _formKey, child: formContent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignInForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFieldWithLabel(
          label: "Username or Email",
          textFieldLabel: "test@example.com or test",
          controller: _signInIdentifierController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Identifier cannot be empty.';
            }
            return null;
          },
        ),
        SizedBox(height: Dimens.paddingVertical / 2),
        TextFieldWithLabel(
          label: "Password",
          textFieldLabel: "Password",
          controller: _signInPasswordController,
          obscureText: true,
          isPasswordType: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password.';
            }
            return null;
          },
        ),
        SizedBox(height: Dimens.paddingVertical),

        ListenableButton(
          label: "Sign In",
          command: widget.viewModel.signIn,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.viewModel.signIn.execute((
                _signInIdentifierController.value.text,
                _signInPasswordController.value.text,
              ));
            }
          },
        ),
        SizedBox(height: Dimens.paddingVertical / 2),
        TextButton(
          onPressed: _toggleForm,
          child: Text(
            "Don't have an account? Sign up!",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).hintColor,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFieldWithLabel(
                label: "First Name",
                textFieldLabel: "Juan",
                controller: _signUpFirstNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name.';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: Dimens.paddingHorizontal / 2),
            Expanded(
              child: TextFieldWithLabel(
                label: "Last Name",
                textFieldLabel: "Dela Cruz",
                controller: _signUpLastNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: Dimens.paddingVertical / 2),
        ListenableBuilder(
          listenable: widget.viewModel.isUsernameUnique,
          builder: (context, child) {
            final isLoading = widget.viewModel.isUsernameUnique.running;
            return TextFieldWithLabel(
              label: "Username",
              textFieldLabel: "Enter your username",
              controller: _signUpUsernameController,
              onChanged: _onUsernameChanged,
              validator: (value) {
                final trimmedValue = value?.trim() ?? '';
                if (trimmedValue.isEmpty) {
                  return 'Username cannot be empty.';
                }
                if (trimmedValue.length < 3) {
                  return 'Username must be at least 3 characters.';
                }
                if (_usernameErrorText != null &&
                    trimmedValue == _signUpUsernameController.text.trim()) {
                  return _usernameErrorText;
                }
                return null;
              },
              suffixIcon:
                  isLoading
                      ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                      )
                      : null,
            );
          },
        ),
        SizedBox(height: Dimens.paddingVertical / 2),
        TextFieldWithLabel(
          label: "Email",
          textFieldLabel: "email@example.com",
          controller: _signUpEmailController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email cannot be empty.';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Please enter a valid email address.';
            }
            return null;
          },
        ),
        SizedBox(height: Dimens.paddingVertical / 2),
        TextFieldWithLabel(
          label: "Password",
          textFieldLabel: "Password",
          controller: _signUpPasswordController,
          obscureText: true,
          isPasswordType: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password.';
            }
            if (value.length < 6) {
              return 'Password length should be at least 6.';
            }
            return null;
          },
        ),
        SizedBox(height: Dimens.paddingVertical / 2),
        TextFieldWithLabel(
          label: "Confirm Password",
          textFieldLabel: "Confirm Password",
          controller: _signUpConfirmPasswordController,
          isPasswordType: true,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password.';
            }
            if (value != _signUpPasswordController.text) {
              return 'Passwords do not match.';
            }
            return null;
          },
        ),
        SizedBox(height: Dimens.paddingVertical),
        FilledButton(
          onPressed: () => _navigateToSignUpPage(SignUpPage.interests),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Continue"),
          ),
        ),
        SizedBox(height: Dimens.paddingVertical / 2),
        TextButton(
          onPressed: _toggleForm,
          child: Text(
            "Already have an account? Sign in!",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).hintColor,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              Interest.values.map((interest) {
                final bool isSelected = _signUpInterests.contains(interest);
                return GenericChipTile<Interest>(
                  value: interest,
                  isSelected: isSelected,
                  labelGetter: (i) => i.emoji,
                  nameGetter: (i) => i.displayName,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  onChanged: (selectedInterest) {
                    setState(() {
                      if (isSelected) {
                        _signUpInterests.remove(selectedInterest);
                      } else {
                        _signUpInterests.add(selectedInterest);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        SizedBox(height: Dimens.paddingVertical * 2),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  currentPage = SignUpPage.credentials;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: const Text("Back"),
              ),
            ),
            Spacer(),
            FilledButton(
              onPressed: () {
                _navigateToSignUpPage(SignUpPage.travelStyles);
              },
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(_signUpInterests.isEmpty ? "Skip" : "Continue"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTravelStylesForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: Dimens.paddingVertical / 2),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              TravelStyle.values.map((travelStyle) {
                final bool isSelected = _signUpTravelStyles.contains(
                  travelStyle,
                );
                return GenericChipTile<TravelStyle>(
                  value: travelStyle,
                  isSelected: isSelected,
                  labelGetter: (t) => t.emoji,
                  nameGetter: (t) => t.displayName,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  onChanged: (selectedTravelStyle) {
                    setState(() {
                      if (isSelected) {
                        _signUpTravelStyles.remove(selectedTravelStyle);
                      } else {
                        _signUpTravelStyles.add(selectedTravelStyle);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        SizedBox(height: Dimens.paddingVertical * 2),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  currentPage = SignUpPage.interests;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: const Text("Back"),
              ),
            ),
            Spacer(),
            ListenableButton(
              label: "Finish Sign Up",
              icon: Icons.check_circle_outlined,
              command: widget.viewModel.signUp,
              onPressed: () {
                widget.viewModel.signUp.execute(
                  User(
                    firstName: _signUpFirstNameController.text.trim(),
                    lastName: _signUpLastNameController.text.trim(),
                    username: _signUpUsernameController.text.trim(),
                    email: _signUpEmailController.text.trim(),
                    password: _signUpPasswordController.text,
                    interests: _signUpInterests,
                    travelStyles: _signUpTravelStyles,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _onLoginResult() {
    if (!mounted) return;
    final loginState = widget.viewModel.signIn;
    if (loginState.completed) {
      loginState.clearResult();
      if (context.mounted) {
        context.go(Routes.home);
      }
    } else if (loginState.error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.show(
            context: context,
            content: Text((loginState.result as Error).toString()),
            actionLabel: "Try again",
            type: "error",
            onPressed: () {
              if (mounted) {
                widget.viewModel.signIn.execute((
                  _signInIdentifierController.value.text,
                  _signInPasswordController.value.text,
                ));
              }
            },
          ),
        );
      }
    }
  }

  void _onSignUpResult() {
    if (!mounted) return;
    final signUpState = widget.viewModel.signUp;
    if (signUpState.completed) {
      signUpState.clearResult();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.show(
            context: context,
            content: const Text("Sign up successful! "),
            type: "success",
          ),
        );
        context.go(Routes.home);
      }
    } else if (signUpState.error) {
      final errorMessage = (signUpState.result as Error).error;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.show(
            context: context,
            content: Text("Error during sign up: $errorMessage"),
            type: "error",
          ),
        );
      }
      signUpState.clearResult();
    }
  }

  void _onCheckUsernameUniquenessResult() {
    if (!mounted) return;
    final state = widget.viewModel.isUsernameUnique;
    if (state.completed) {
      final result = state.result;
      state.clearResult();
      if (result == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.show(
              context: context,
              content: const Text("Error during check username uniqueness."),
              type: "error",
            ),
          );
        }
        return;
      }
      switch (result) {
        case Ok():
          if (result.value) {
            _usernameErrorText = null;
          } else {
            _usernameErrorText =
                '"${_signUpUsernameController.text.trim()}" is already taken.';
          }
        case Error():
          _usernameErrorText = 'Error: Check username failed.';
      }
      if (_formKey.currentState?.validate() ?? false) {}
      setState(() {});
    }
  }
}
