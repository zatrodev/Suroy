import 'package:app/routing/routes.dart';
import 'package:app/ui/auth/login/view_models/login_viewmodel.dart';
import 'package:app/ui/auth/login/widgets/carousel_image_info.dart';
import 'package:app/ui/auth/login/widgets/carousel_images.dart';
import 'package:app/ui/core/themes/dimens.dart';
import 'package:app/ui/core/ui/app_snackbar.dart';
import 'package:app/ui/core/ui/text_field_with_label.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final CarouselController _carouselController = CarouselController(
    initialItem: 1,
  );

  final TextEditingController _signInEmailController = TextEditingController();
  final TextEditingController _signInPasswordController =
      TextEditingController();

  final TextEditingController _signUpFirstNameController =
      TextEditingController();
  final TextEditingController _signUpLastNameController =
      TextEditingController();
  final TextEditingController _signUpEmailController = TextEditingController();
  final TextEditingController _signUpPasswordController =
      TextEditingController();
  final TextEditingController _signUpConfirmPasswordController =
      TextEditingController();

  bool _isSignIn = true;

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
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.signIn.removeListener(_onLoginResult);
    oldWidget.viewModel.signUp.removeListener(_onSignUpResult);
    widget.viewModel.signIn.addListener(_onLoginResult);
    widget.viewModel.signUp.addListener(_onSignUpResult);
  }

  @override
  void dispose() {
    // Remove listeners
    widget.viewModel.signIn.removeListener(_onLoginResult);
    widget.viewModel.signUp.removeListener(_onSignUpResult);

    // Dispose all controllers
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpFirstNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();

    _scrollController.dispose();
    _carouselController.dispose();

    super.dispose();
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
                    // Keep Title outside the changing part
                    Text(
                      "Suroy.",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Plan your travels with ease.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    SizedBox(height: Dimens.paddingVertical),

                    // --- Animated Form Area ---
                    AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 200,
                      ), // Animation duration
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        // Define the slide transition
                        final offsetAnimation = Tween<Offset>(
                          begin: Offset(
                            _isSignIn ? -1.0 : 1.0,
                            0.0,
                          ), // Come from left if signing IN, from right if signing UP
                          end: Offset.zero,
                        ).animate(animation);

                        // Use SlideTransition
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

  // --- Sign In Form Widget ---
  Widget _buildSignInForm(BuildContext context) {
    // Use ValueKey to uniquely identify this widget for AnimatedSwitcher
    return KeyedSubtree(
      key: const ValueKey<bool>(true), // Key for Sign In state
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFieldWithLabel(
            label: "Email",
            textFieldLabel: "email@example.com",
            controller: _signInEmailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
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
                                if (_formKey.currentState!.validate())
                                  widget.viewModel.signIn.execute((
                                    _signInEmailController.value.text,
                                    _signInPasswordController.value.text,
                                  ));
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

  // --- Sign Up Form Widget ---
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
                      return 'Please enter your first name';
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
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: Dimens.paddingVertical / 2),
          TextFieldWithLabel(
            label: "Email",
            textFieldLabel: "email@example.com",
            controller: _signUpEmailController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email cannot be empty';
              }

              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email address';
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
          ),
          SizedBox(height: Dimens.paddingVertical / 2),
          TextFieldWithLabel(
            label: "Confirm Password",
            textFieldLabel: "Confirm Password",
            controller: _signUpConfirmPasswordController,
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
                                        // Check if still mounted before accessing controllers/viewModel
                                        if (mounted) {
                                          widget.viewModel.signIn.execute((
                                            _signInEmailController.value.text,
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

  // Handle login result
  void _onLoginResult() {
    if (!mounted) return; // Check if widget is still in the tree

    final loginState =
        widget.viewModel.signIn; // Use local variable for clarity

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
            type: "error",
            onPressed: () {
              if (mounted) {
                widget.viewModel.signIn.execute((
                  _signInEmailController.value.text,
                  _signInPasswordController.value.text,
                ));
              }
            },
          ),
        );
      }
    }
  }

  // Handle potential sign up result (optional based on requirements)
  void _onSignUpResult() {
    if (!mounted) return;

    final signUpState = widget.viewModel.signUp;

    if (signUpState.completed) {
      signUpState.clearResult();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.show(
            context: context,
            content: Text("Sign up successful! Please sign in."),
            type: "success",
            onPressed: () {
              if (mounted) {
                widget.viewModel.signIn.execute((
                  _signInEmailController.value.text,
                  _signInPasswordController.value.text,
                ));
              }
            },
          ),
        );
        _toggleForm();
      }
    } else if (signUpState.error) {
      signUpState.clearResult();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.show(
            context: context,
            content: const Text("Error during sign up."),
            type: "error",
            onPressed: () {
              // Check if still mounted before accessing controllers/viewModel
              if (mounted) {
                widget.viewModel.signIn.execute((
                  _signInEmailController.value.text,
                  _signInPasswordController.value.text,
                ));
              }
            },
          ),
        );
      }
    }
  }
}
