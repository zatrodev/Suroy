import 'dart:async';

import 'package:app/routing/routes.dart';
import 'package:app/ui/auth/login/view_models/sign_in_viewmodel.dart';
import 'package:app/ui/auth/login/widgets/carousel_image_info.dart';
import 'package:app/ui/auth/login/widgets/carousel_image_item.dart';
import 'package:app/ui/core/themes/dimens.dart';
import 'package:app/ui/core/ui/app_snackbar.dart';
import 'package:app/ui/core/ui/text_field_with_label.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  bool _isSignIn = true;

  Timer? _debounce;
  String? _usernameErrorText;

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _toggleForm() async {
    setState(() {
      _isSignIn = !_isSignIn;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollDown();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.signIn.addListener(_onLoginResult);
    widget.viewModel.signUp.addListener(_onSignUpResult);
    widget.viewModel.isUsernameUniqueCommand.addListener(
      _onCheckUsernameUniquenessResult,
    );
  }

  @override
  void didUpdateWidget(covariant SignInScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.signIn.removeListener(_onLoginResult);
    oldWidget.viewModel.signUp.removeListener(_onSignUpResult);
    oldWidget.viewModel.isUsernameUniqueCommand.removeListener(
      _onCheckUsernameUniquenessResult,
    );
    widget.viewModel.signIn.addListener(_onLoginResult);
    widget.viewModel.signUp.addListener(_onSignUpResult);
    widget.viewModel.isUsernameUniqueCommand.addListener(
      _onCheckUsernameUniquenessResult,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.viewModel.signIn.removeListener(_onLoginResult);
    widget.viewModel.signUp.removeListener(_onSignUpResult);
    widget.viewModel.isUsernameUniqueCommand.removeListener(
      _onCheckUsernameUniquenessResult,
    );

    _signInIdentifierController.dispose();
    _signInPasswordController.dispose();
    _signUpFirstNameController.dispose();
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
        // Clear any error state in the command if username is now empty
        // This depends on how your command handles resetting state.
        // For instance, if command has a reset method or if setting its error to null clears it.
        // widget.viewModel.isUsernameUniqueCommand.clearError(); // Hypothetical
        _formKey.currentState?.validate(); // Re-validate
        return;
      }
      // Execute command. No need to await its result here if we are listening.
      widget.viewModel.isUsernameUniqueCommand.execute(trimmedUsername);
      // The ListenableBuilder will react to state changes within the command.
      // We might still need to trigger a form validation after the command execution
      // if the command doesn't directly set a ValueNotifier that the validator reads.
      // However, if the command updates a ValueNotifier for errorText, and the
      // ListenableBuilder rebuilds the TextFormField with that errorText,
      // the visual feedback might be enough. For _formKey.currentState.validate()
      // to pick up the error, the validator itself needs to return the error string.
    });
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      // Prevent keyboard overflow
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Dimens.paddingVertical * 2),
            ConstrainedBox(
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
            Padding(
              padding: Dimens.of(context).edgeInsetsScreenSymmetric,
              child: Padding(
                padding: const EdgeInsets.only(top: Dimens.paddingVertical * 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Suroy.",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "suroy (v.) - a Cebuano word meaning \"to wander around\"",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    SizedBox(height: Dimens.paddingVertical / 2),
                    Text(
                      "Plan your travels with ease.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    SizedBox(height: Dimens.paddingVertical),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        final offsetAnimation = Tween<Offset>(
                          begin: Offset(_isSignIn ? -1.0 : 1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUnfocus,
                        child:
                            _isSignIn
                                ? _buildSignInForm(context)
                                : _buildSignUpForm(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInForm(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey<bool>(true),
      child: Column(
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
          ListenableBuilder(
            listenable: widget.viewModel.signIn,
            builder: (context, _) {
              final bool isLoading = widget.viewModel.signIn.running;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      label: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Sign In"),
                      ),
                      icon:
                          isLoading
                              ? const Padding(
                                padding: EdgeInsets.only(right: 4.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              )
                              : null,
                      onPressed:
                          isLoading
                              ? null
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  widget.viewModel.signIn.execute((
                                    _signInIdentifierController.value.text,
                                    _signInPasswordController.value.text,
                                  ));
                                }
                              },
                    ),
                  ),
                ],
              );
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
      ),
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey<bool>(false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: Dimens.paddingHorizontal / 2,
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
            listenable: widget.viewModel.isUsernameUniqueCommand,
            builder: (context, child) {
              final isLoading =
                  widget.viewModel.isUsernameUniqueCommand.running;
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
                return 'Please enter your email.';
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
          ),
          SizedBox(height: Dimens.paddingVertical),
          ListenableBuilder(
            listenable: widget.viewModel.signUp,
            builder: (context, _) {
              final bool isLoading = widget.viewModel.signUp.running;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      label: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Sign Up"),
                      ),
                      icon:
                          isLoading
                              ? const Padding(
                                padding: EdgeInsets.only(right: 4.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                              : null,
                      onPressed:
                          isLoading
                              ? null
                              : () {
                                if (_signUpPasswordController.text !=
                                    _signUpConfirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    AppSnackBar.show(
                                      context: context,
                                      content: const Text(
                                        "Passwords do not match!",
                                      ),
                                      type: "error",

                                      onPressed: () {
                                        if (mounted) {
                                          widget.viewModel.signIn.execute((
                                            _signInIdentifierController
                                                .value
                                                .text,
                                            _signInPasswordController
                                                .value
                                                .text,
                                          ));
                                        }
                                      },
                                    ),
                                  );
                                  return;
                                }

                                if (_formKey.currentState!.validate()) {
                                  widget.viewModel.signUp.execute((
                                    _signUpFirstNameController.value.text,
                                    _signUpLastNameController.value.text,
                                    _signUpUsernameController.value.text,
                                    _signUpEmailController.value.text,
                                    _signUpPasswordController.value.text,
                                  ));
                                }
                              },
                    ),
                  ),
                ],
              );
            },
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
      ),
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
      loginState.clearResult();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.show(
            context: context,
            content: const Text("Error while trying to login"),
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
            content: Text("Sign up successful! "),
            type: "success",
          ),
        );

        context.go(Routes.home);
      }
    } else if (signUpState.error) {
      signUpState.clearResult();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.show(
            context: context,
            content: const Text("Error during sign up."),
            type: "error",
          ),
        );
      }
    }
  }

  void _onCheckUsernameUniquenessResult() {
    if (!mounted) return;

    final state = widget.viewModel.isUsernameUniqueCommand;
    if (state.completed) {
      final result = state.result;
      if (result == null) {
        state.clearResult();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.show(
              context: context,
              content: const Text("Error during check username uniquness."),
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
    }
  }
}
