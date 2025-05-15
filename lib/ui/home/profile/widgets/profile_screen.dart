import 'package:app/domain/models/user.dart';
import 'package:app/ui/core/themes/dimens.dart';
import 'package:app/ui/home/profile/view_models/profile_viewmodel.dart';
import 'package:app/utils/convert_to_base64.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  Widget build(BuildContext context) {
    if (widget.viewModel.loadUser.running) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    if (widget.viewModel.user == null) {
      return Scaffold(
        body: const Center(child: Text('Error loading profile.')),
      );
    }

    return Scaffold(body: _buildProfileView(context, widget.viewModel.user!));
  }

  Widget _buildProfileView(BuildContext context, User user) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverPersistentHeader(
          delegate: ProfileHeaderDelegate(
            user: user,
            showImageSourceActionSheet:
                () => _showImageSourceActionSheet(context),
            isPickingImage: widget.viewModel.changeAvatar.running,
          ),
          pinned: true,
        ),
        SliverToBoxAdapter(child: BodyWidget(user: user)),
      ],
    );
  }
}

class ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight = 200.0;
  final double collapsedHeight = kToolbarHeight + 80;

  ProfileHeaderDelegate({
    required this.user,
    required this.showImageSourceActionSheet,
    required this.isPickingImage,
  });

  final User user;
  final GestureTapCallback showImageSourceActionSheet;
  final bool isPickingImage;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double avatarSize = 120.0;
    final double top = expandedHeight - shrinkOffset - avatarSize / 1.5;
    final avatarBytes = convertBase64ToImage(user.avatar);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Container(
          child:
              avatarBytes != null
                  ? Image.memory(
                    avatarBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print(
                        "Error displaying memory image for background: $error",
                      );
                      return Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5),
                      );
                    },
                  )
                  : Container(color: Theme.of(context).colorScheme.primary),
        ),

        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.25)),
        ),

        Positioned(
          top: top.clamp(
            kToolbarHeight - avatarSize / 2,
            expandedHeight - avatarSize / 3,
          ),
          left: MediaQuery.of(context).size.width / 2 - avatarSize / 2,
          child: GestureDetector(
            onTap: showImageSourceActionSheet,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundImage:
                      avatarBytes != null ? MemoryImage(avatarBytes) : null,
                  child:
                      avatarBytes == null
                          ? Text(
                            user.initials,
                            style: const TextStyle(fontSize: 40),
                          )
                          : null,
                ),
                if (isPickingImage)
                  const Positioned(
                    right: 4,
                    bottom: 4,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black54,
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}

class BodyWidget extends StatelessWidget {
  final User user;

  const BodyWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      padding: const EdgeInsets.only(
        top: 52.0,
        left: 20.0,
        right: 20.0,
        bottom: 20.0,
      ), // Increased top padding for avatar overlap
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            user.username,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimens.paddingVertical),
          // Google Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                // TODO: change to Google
                icon: const FaIcon(FontAwesomeIcons.google),
                iconSize: 28,
                onPressed: () {
                  // TODO: Handle Google profile link
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google icon tapped!')),
                  );
                },
              ),
            ],
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              label: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.labelMedium?.fontSize,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inverseSurface,
              ),
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
              onPressed: () => {},
            ),
          ),

          SizedBox(height: Dimens.paddingVertical),

          Divider(),
          _buildInfoRow(icon: Icons.email_outlined, text: Text(user.email)),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            text: Text(
              user.phoneNumber == null || user.phoneNumber!.isEmpty
                  ? "No phone number"
                  : user.phoneNumber!,
              style: TextStyle(
                fontStyle:
                    user.phoneNumber != null
                        ? FontStyle.italic
                        : FontStyle.normal,
              ),
            ),
          ),
          SizedBox(height: Dimens.paddingVertical),

          _buildChipSection(
            context,
            'Interests',
            user.interests.map((interest) => interest.displayName).toList(),
          ),

          SizedBox(height: Dimens.paddingVertical),

          _buildChipSection(
            context,
            'Travel Styles',
            user.travelStyles
                .map((travelStyle) => travelStyle.displayName)
                .toList(),
          ),
          SizedBox(height: Dimens.paddingVertical * 2),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              label: Text(
                "Sign Out",
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.labelMedium?.fontSize,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              icon: Icon(
                Icons.exit_to_app,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required Text text}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: Dimens.paddingHorizontal / 2),
              Expanded(child: text),
            ],
          ),
        ),
        Divider(),
      ],
    );
  }

  Widget _buildChipSection(BuildContext context, title, List<String> items) {
    if (items.isEmpty) {
      return Text("No $title", style: TextStyle(fontStyle: FontStyle.italic));
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children:
                items
                    .map(
                      (item) => Chip(
                        label: Text(item),
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}
