import 'package:app/domain/models/user.dart';
import 'package:app/routing/routes.dart';
import 'package:app/ui/core/ui/app_snackbar.dart';
import 'package:app/ui/home/profile/view_models/profile_viewmodel.dart';
import 'package:app/ui/home/profile/widgets/profile_body.dart';
import 'package:app/ui/home/profile/widgets/profile_header.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.viewModel});

  final ProfileViewModel viewModel;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadUser.addListener(_onViewModelUpdate);
    widget.viewModel.changeAvatar.addListener(_onViewModelUpdate);
    widget.viewModel.signOut.addListener(_onViewModelUpdate);
  }

  @override
  void dispose() {
    widget.viewModel.loadUser.removeListener(_onViewModelUpdate);
    widget.viewModel.changeAvatar.removeListener(_onViewModelUpdate);
    widget.viewModel.signOut.removeListener(_onViewModelUpdate);
    super.dispose();
  }

  void _onViewModelUpdate() {
    if (mounted) {
      setState(() {});
    }

    if (widget.viewModel.signOut.completed) {
      if (context.mounted) {
        context.go(Routes.signIn);
      }
    } else if (widget.viewModel.signOut.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.show(
          context: context,
          content: const Text("Error while trying to sign out"),
          actionLabel: "Try again",
          type: "error",
          onPressed: () {
            if (mounted) {
              widget.viewModel.signOut.execute();
            }
          },
        ),
      );
    }
  }

  Future<void> _navigateToEditProfile(
    BuildContext context,
    User currentUser,
  ) async {
    final dynamic result = await context.push<Ok?>(
      '${GoRouterState.of(context).matchedLocation}/edit',
      extra: currentUser,
    );

    if (result is Ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.show(
            context: context,
            content: Text("Profile details updated."),
            type: "success",
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceActionSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.viewModel.changeAvatar.execute(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.viewModel.changeAvatar.execute(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel.loadUser,
    builder: (context, child) {
      if (widget.viewModel.loadUser.running) {
        return Scaffold(body: const Center(child: CircularProgressIndicator()));
      }

      if (widget.viewModel.user == null) {
        return Scaffold(
          body: const Center(child: Text('Error loading profile.')),
        );
      }

      return Scaffold(body: _buildProfileView(context, widget.viewModel.user!));
    },
  );

  Widget _buildProfileView(BuildContext context, User user) {
    // NOTE: refactor to use ListenableBuilder instead
    return CustomScrollView(
      slivers: <Widget>[
        SliverPersistentHeader(
          delegate: ProfileHeaderDelegate(
            user: user,
            showImageSourceActionSheet:
                () => _showImageSourceActionSheet(context),
            signOut: widget.viewModel.signOut.execute,
            isPickingImage: widget.viewModel.changeAvatar.running,
          ),
          pinned: true,
        ),
        SliverToBoxAdapter(
          child: ProfileBody(
            user: user,
            navigateToEditProfile: () => _navigateToEditProfile(context, user),
          ),
        ),
      ],
    );
  }
}
