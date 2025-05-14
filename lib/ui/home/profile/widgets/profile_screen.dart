// lib/ui/home/profile/profile_screen.dart
import 'package:app/domain/models/user.dart'; // Your domain User model
import 'package:app/ui/home/profile/view_models/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/utils/result.dart' as R; // Aliased to avoid conflict

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
    // Add listeners to the commands
    widget.viewModel.loadUser.addListener(_onViewModelUpdate);
    widget.viewModel.changeAvatar.addListener(_onViewModelUpdate);
    widget.viewModel.signOut.addListener(_onViewModelUpdate); // Or a specific handler for sign-out
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    widget.viewModel.loadUser.removeListener(_onViewModelUpdate);
    widget.viewModel.changeAvatar.removeListener(_onViewModelUpdate);
    widget.viewModel.signOut.removeListener(_onViewModelUpdate);
    // If the ViewModel was created by this screen (not typical with Provider/DI),
    // you might call widget.viewModel.dispose(); here.
    // But typically, ViewModel lifecycle is managed by DI.
    super.dispose();
  }

  void _onViewModelUpdate() {
    // When a command notifies, trigger a rebuild of the screen
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showImageSourceActionSheet(BuildContext context) async {
    // Access viewModel via widget.viewModel
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
    final viewModel = widget.viewModel; // For convenience

    // Handle initial loading state
    if (viewModel.loadUser.running && viewModel.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Handle error state for initial profile load
    if (viewModel.loadUser.error && viewModel.user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading profile: ${(viewModel.loadUser.result as R.Error).error.toString()}',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  viewModel.clearError(); // This will trigger a notify via commands if state changes
                  viewModel.loadUser.execute();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // If user is still null after load attempt (and not error reported above)
    if (viewModel.user == null) {
      // This could also happen if signOut was successful
      return const Scaffold(
        body: Center(child: Text("No profile data available or user signed out.")),
      );
    }

    // If we have user data, display it
    final User user = viewModel.user!;

    return Scaffold(
      // appBar: AppBar(title: const Text('Profile')), // Assuming shell has Appbar
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => viewModel.loadUser.execute(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceActionSheet(context),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage:
                            user.avatar != null && user.avatar!.isNotEmpty
                                ? NetworkImage(user.avatar!)
                                : null,
                        child:
                            (user.avatar == null || user.avatar!.isEmpty) &&
                                    user.initials.isNotEmpty
                                ? Text(
                                  user.initials,
                                  style: const TextStyle(fontSize: 40),
                                )
                                : null,
                      ),
                      if (viewModel.changeAvatar.running)
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
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12), // Reduced spacing a bit
              if (viewModel.changeAvatar.error)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                  child: Text(
                    "Failed to update picture: ${(viewModel.changeAvatar.result as R.Error).error.toString()}",
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),

              _buildProfileDetailRow(context, 'First Name:', user.firstName),
              _buildProfileDetailRow(context, 'Last Name:', user.lastName),
              _buildProfileDetailRow(context, 'Username:', user.username),
              _buildProfileDetailRow(context, 'Email:', user.email),
              _buildProfileDetailRow(context, 'Phone Number:', user.phoneNumber ?? 'Not set'),
              const SizedBox(height: 16),

              _buildProfileSectionTitle(context, 'Interests:'),
              user.interests.isNotEmpty
                  ? Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: user.interests.map((interest) => Chip(label: Text(interest.displayName))).toList(),
                    )
                  : const Text('No interests set.', style: TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),

              _buildProfileSectionTitle(context, 'Travel Styles:'),
              user.travelStyles.isNotEmpty
                  ? Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: user.travelStyles.map((style) => Chip(label: Text(style.displayName))).toList(),
                    )
                  : const Text('No travel styles set.', style: TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: viewModel.signOut.running ? null : () {
                  viewModel.signOut.execute();
                  // Navigation should be handled by go_router based on AuthRepository state change
                },
                child: viewModel.signOut.running
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Sign Out"),
              ),
              if (viewModel.signOut.error)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Sign out failed: ${(viewModel.signOut.result as R.Error).error.toString()}",
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildProfileSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}
