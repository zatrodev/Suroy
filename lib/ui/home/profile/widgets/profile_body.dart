import 'package:app/data/repositories/user/user_model.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/ui/core/themes/dimens.dart';
import 'package:app/ui/core/ui/generic_list_tile.dart';
import 'package:flutter/material.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({
    super.key,
    required this.user,
    required this.navigateToEditProfile,
  });

  final User user;
  final VoidCallback navigateToEditProfile;

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
        top: 64,
        left: 20.0,
        right: 20.0,
        bottom: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "${user.firstName} ${user.lastName}",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimens.paddingVertical / 4),
          Text(
            "@${user.username}",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimens.paddingVertical / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                label: Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.labelMedium?.fontSize,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainer,
                ),
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: navigateToEditProfile,
              ),
            ],
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
                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                fontStyle:
                    user.phoneNumber != null
                        ? FontStyle.normal
                        : FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: Dimens.paddingVertical),

          _buildChipSection<Interest>(
            context,
            'Interests',
            user.interests.map((interest) {
              return GenericChipTile<Interest>(
                value: interest,
                isSelected: false,
                labelGetter: (t) => t.emoji,
                nameGetter: (t) => t.displayName,
                selectedColor: Theme.of(context).colorScheme.primary,
                onChanged: (_) {},
              );
            }).toList(),
          ),

          SizedBox(height: Dimens.paddingVertical * 1.5),

          _buildChipSection(
            context,
            'Travel Styles',
            user.travelStyles.map((travelStyle) {
              return GenericChipTile<TravelStyle>(
                value: travelStyle,
                isSelected: false,
                labelGetter: (t) => t.emoji,
                nameGetter: (t) => t.displayName,
                selectedColor: Theme.of(context).colorScheme.primary,
                onChanged: (_) {},
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required Text text}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: Dimens.paddingVertical / 1.5,
            bottom: Dimens.paddingVertical / 1.5,
          ),
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

  Widget _buildChipSection<T>(BuildContext context, title, List<Widget> items) {
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8.0, runSpacing: 8.0, children: items),
        ],
      ),
    );
  }
}
