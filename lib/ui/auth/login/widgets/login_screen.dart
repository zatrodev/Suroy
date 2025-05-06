import 'package:app/routing/routes.dart';
import 'package:app/ui/auth/login/view_models/login_viewmodel.dart';
import 'package:app/ui/core/themes/dimens.dart';
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
  final CarouselController _carouselController = CarouselController(
    initialItem: 1,
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.login.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.login.removeListener(_onResult);
    widget.viewModel.login.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.login.removeListener(_onResult);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height / 3),
            child: CarouselView.weighted(
              controller: _carouselController,
              itemSnapping: true,
              flexWeights: const <int>[1, 7, 1],
              children:
                  ImageInfo.values.map((ImageInfo image) {
                    return CarouselImageItem(imageInfo: image);
                  }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 60.0, left: 20, right: 20),
            child: RichText(
              textAlign: TextAlign.center, // Ensure the text itself is centered
              text: TextSpan(
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Suroy',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: '.',
                    style: TextStyle(
                      // Make the period stand out with the secondary color
                      // Or choose a specific vibrant color like Colors.tealAccent
                      color: Theme.of(context).colorScheme.secondary,
                      // Optionally make the dot even bolder or slightly different size/offset
                      fontWeight: FontWeight.w900, // Heavier weight for the dot
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: Dimens.of(context).edgeInsetsScreenSymmetric,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFieldWithLabel(
                    label: "Email",
                    textFieldLabel: "email@example.com",
                    controller: _emailController,
                  ),
                  SizedBox(height: Dimens.paddingVertical),
                  TextFieldWithLabel(
                    label: "Password",
                    textFieldLabel: "Password",
                    controller: _passwordController,
                    obscureText: true,
                  ),
                  SizedBox(height: Dimens.paddingVertical),
                  ListenableBuilder(
                    listenable: widget.viewModel.login,
                    builder: (context, _) {
                      final bool isLoading = widget.viewModel.login.running;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              label: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Sign In"),
                              ),
                              icon:
                                  isLoading
                                      ? Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4.0,
                                        ),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                      : null,
                              onPressed:
                                  isLoading
                                      ? null
                                      : () {
                                        widget.viewModel.login.execute((
                                          _emailController.value.text,
                                          _passwordController.value.text,
                                        ));
                                      },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onResult() {
    if (widget.viewModel.login.completed) {
      widget.viewModel.login.clearResult();
      context.go(Routes.home);
    }

    if (widget.viewModel.login.error) {
      widget.viewModel.login.clearResult();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error while trying to login"),
          action: SnackBarAction(
            label: "Try again",
            onPressed:
                () => widget.viewModel.login.execute((
                  _emailController.value.text,
                  _passwordController.value.text,
                )),
          ),
        ),
      );
    }
  }
}

class CarouselImageItem extends StatelessWidget {
  const CarouselImageItem({super.key, required this.imageInfo});

  final ImageInfo imageInfo;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        ClipRect(
          child: OverflowBox(
            maxWidth: width * 7 / 8,
            minWidth: width * 7 / 8,
            child: Image(
              fit: BoxFit.cover,
              image: NetworkImage(
                'https://flutter.github.io/assets-for-api-docs/assets/material/${imageInfo.url}',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                imageInfo.title,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                imageInfo.subtitle,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum ImageInfo {
  image0(
    'The Flow',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_1.png',
  ),
  image1(
    'Through the Pane',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_2.png',
  ),
  image2(
    'Iridescence',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_3.png',
  ),
  image3(
    'Sea Change',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_4.png',
  ),
  image4(
    'Blue Symphony',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_5.png',
  ),
  image5(
    'When It Rains',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_6.png',
  );

  const ImageInfo(this.title, this.subtitle, this.url);
  final String title;
  final String subtitle;
  final String url;
}
