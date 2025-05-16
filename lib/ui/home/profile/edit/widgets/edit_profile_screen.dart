import 'dart:async';
import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/ui/core/themes/dimens.dart';
import 'package:app/ui/core/ui/app_snackbar.dart';
import 'package:app/ui/core/ui/generic_list_tile.dart';
import 'package:app/ui/core/ui/listenable_button.dart';
import 'package:app/ui/core/ui/text_field_with_label.dart';
import 'package:app/ui/home/profile/edit/view_models/edit_profile_viewmodel.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.viewModel});

  final EditProfileViewModel viewModel;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  bool _isDiscoverable = false;
  List<Interest> _interests = [];
  List<TravelStyle> _travelStyles = [];

  Timer? _debounce;
  String? _usernameErrorText;

  @override
  void initState() {
    super.initState();

    _firstNameController.text = widget.viewModel.editableUser.firstName;
    _lastNameController.text = widget.viewModel.editableUser.lastName;
    _usernameController.text = widget.viewModel.editableUser.username;
    _phoneNumberController.text =
        widget.viewModel.editableUser.phoneNumber ?? '';
    _interests = widget.viewModel.editableUser.interests;
    _travelStyles = widget.viewModel.editableUser.travelStyles;
    _isDiscoverable = widget.viewModel.editableUser.isDiscoverable;

    widget.viewModel.saveChanges.addListener(_onSaveChangesResult);
    widget.viewModel.isUsernameUnique.addListener(
      _onCheckUsernameUniquenessResult,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneNumberController.dispose();

    widget.viewModel.saveChanges.removeListener(_onSaveChangesResult);
    widget.viewModel.isUsernameUnique.removeListener(
      _onCheckUsernameUniquenessResult,
    );
    super.dispose();
  }

  void _onUsernameChanged(String username) {
    final trimmedUsername = username.trim();
    widget.viewModel.updateUsername(username);

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (trimmedUsername.isEmpty) {
        if (_usernameErrorText != null) {
          setState(() {
            _usernameErrorText = null;
          });
        }
        _formKey.currentState?.validate();
        return;
      }
      widget.viewModel.isUsernameUnique.execute(trimmedUsername);
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      widget.viewModel.saveChanges.execute();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.show(
          context: context,
          content: const Text("Please correct the errors in the form."),
          type: "error",
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.0,
        title: Text(
          "Edit Profile",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.viewModel.hasUnsavedChanges) {
              showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Unsaved Changes'),
                      content: const Text(
                        'Do you want to discard your changes?',
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Discard'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
              );
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFieldWithLabel(
                label: "First Name",
                textFieldLabel: "Enter your first name",
                controller: _firstNameController,
                onChanged:
                    (firstName) => widget.viewModel.updateLastName(firstName),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name cannot be empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFieldWithLabel(
                label: "Last Name",
                textFieldLabel: "Enter your last name",
                controller: _lastNameController,
                onChanged:
                    (lastName) => widget.viewModel.updateLastName(lastName),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name cannot be empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: widget.viewModel.isUsernameUnique,
                builder: (context, child) {
                  final isLoading = widget.viewModel.isUsernameUnique.running;
                  return TextFieldWithLabel(
                    label: "Username",
                    textFieldLabel: "Enter your username",
                    controller: _usernameController,
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
                          trimmedValue == _usernameController.text.trim()) {
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              ),
                            )
                            : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFieldWithLabel(
                label: "Phone Number",
                textFieldLabel: "Enter your phone number",
                controller: _phoneNumberController,
                onChanged:
                    (phoneNumber) =>
                        widget.viewModel.updatePhoneNumber(phoneNumber),
                validator: (value) {
                  final trimmedValue = value?.trim() ?? '';
                  if (trimmedValue.isNotEmpty &&
                      !RegExp(
                        r'^\+?[0-9\s\-()]{11,}$',
                      ).hasMatch(trimmedValue)) {
                    return 'Enter a valid phone number.';
                  }

                  return null;
                },
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: Dimens.paddingVertical * 1.5),
              Text("Interests", style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children:
                    Interest.values.map((interest) {
                      final bool isSelected = _interests.contains(interest);
                      return GenericChipTile<Interest>(
                        value: interest,
                        isSelected: isSelected,
                        labelGetter: (i) => i.emoji,
                        nameGetter: (i) => i.displayName,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        onChanged: (selectedInterest) {
                          setState(() {
                            if (isSelected) {
                              _interests.remove(selectedInterest);
                            } else {
                              _interests.add(selectedInterest);
                            }

                            widget.viewModel.updateInterests(_interests);
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: Dimens.paddingVertical * 1.5),
              Text(
                "Travel Styles",
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children:
                    TravelStyle.values.map((travelStyle) {
                      final bool isSelected = _travelStyles.contains(
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
                              _travelStyles.remove(selectedTravelStyle);
                            } else {
                              _travelStyles.add(selectedTravelStyle);
                            }
                            widget.viewModel.updateTravelStyles(_travelStyles);
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: Dimens.paddingVertical * 1.5),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CheckboxListTile(
                    value: _isDiscoverable,
                    title: Text(
                      "Let other people view your profile and travel plans.",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    secondary: Icon(Icons.public),
                    onChanged: (isDiscoverable) {
                      setState(() {
                        _isDiscoverable = isDiscoverable!;
                      });
                      widget.viewModel.updateIsDiscoverable(isDiscoverable!);
                    },
                  ),
                ),
              ),
              const SizedBox(height: Dimens.paddingVertical * 2),
              ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListenableButton(
                        label: "Save Changes",
                        icon: Icons.check_circle_outlined,
                        command: widget.viewModel.saveChanges,
                        onPressed:
                            widget.viewModel.hasUnsavedChanges
                                ? _saveProfile
                                : null,
                      ),
                      if (widget.viewModel.hasUnsavedChanges)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton(
                            onPressed: () {
                              widget.viewModel.discardChanges();

                              _firstNameController.text =
                                  widget.viewModel.editableUser.firstName;
                              _lastNameController.text =
                                  widget.viewModel.editableUser.lastName;
                              _usernameController.text =
                                  widget.viewModel.editableUser.username;
                              _phoneNumberController.text =
                                  widget.viewModel.editableUser.phoneNumber ??
                                  '';

                              _formKey.currentState?.reset();
                              setState(() {
                                _usernameErrorText = null;
                              });
                            },
                            child: Text(
                              'Discard Changes',
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
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
    );
  }

  void _onSaveChangesResult() {
    if (!mounted) return;

    final state = widget.viewModel.saveChanges;

    if (state.completed) {
      final result = state.result;
      state.clearResult();

      if (result == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.show(
              context: context,
              content: const Text("An unexpected error occurred while saving."),
              type: "error",
            ),
          );
        }
        return;
      }

      switch (result) {
        case Ok<void>():
          if (context.mounted) {
            context.pop(result);
          }
          return;
        case Error():
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppSnackBar.show(
                context: context,
                content: Text(
                  "Error while updating your profile: ${result.error}",
                ),
                type: "error",
              ),
            );
          }
          return;
      }
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
              content: const Text("Error during username uniqueness check."),
              type: "error",
            ),
          );
        }
        return;
      }

      String? newErrorText;
      switch (result) {
        case Ok(value: final isUnique):
          if (isUnique) {
            newErrorText = null;
          } else {
            newErrorText =
                '"${_usernameController.text.trim()}" is already taken.';
          }
        case Error():
          newErrorText = 'Error: Failed to check username uniqueness.';
      }

      if (_usernameErrorText != newErrorText) {
        setState(() {
          _usernameErrorText = newErrorText;
        });
      }
    }
  }
}
