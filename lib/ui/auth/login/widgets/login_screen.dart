import 'package:app/ui/auth/login/view_models/login_viewmodel.dart';
import 'package:app/ui/core/themes/dimens.dart';
import 'package:app/ui/core/ui/text_field_with_label.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
            padding: Dimens.of(context).edgeInsetsScreenSymmetric,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFieldWithLabel(
                  label: "Email",
                  textFieldLabel: "email@example.com",
                  controller: _email,
                ),
                SizedBox(height: Dimens.paddingVertical),
                TextFieldWithLabel(
                  label: "Password",
                  textFieldLabel: "Password",
                  controller: _password,
                  obscureText: true,
                ),
                SizedBox(height: Dimens.paddingVertical),
                ListenableBuilder(
                  listenable: widget.viewModel.login,
                  builder: (context, _) {
                    return FilledButton(
                      onPressed: () {
                        widget.viewModel.login.execute((
                          _email.value.text,
                          _password.value.text,
                        ));
                      },
                      child: Text(AppLocalization.of(context).login),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
