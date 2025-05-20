import 'dart:math' as math;
import 'dart:ui';

import 'package:app/domain/models/user.dart';
import 'package:app/ui/core/themes/dimens.dart';
import 'package:app/utils/convert_to_base64.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ProfileHeaderAction { signOut }

class ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight = 256.0;
  final double collapsedHeight = kToolbarHeight + 80;

  late final Uint8List? _avatarBytes;
  late final ImageProvider? _avatarImageProvider;

  ProfileHeaderDelegate({
    required this.user,
    required this.showImageSourceActionSheet,
    required this.signOut,
    required this.isPickingImage,
  }) {
    _avatarBytes = convertBase64ToImage(user.avatar);
    if (_avatarBytes != null) {
      _avatarImageProvider = MemoryImage(_avatarBytes);
    } else {
      _avatarImageProvider = null;
    }
  }

  final User user;
  final GestureTapCallback showImageSourceActionSheet;
  final AsyncCallback signOut;
  final bool isPickingImage;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double avatarSize = 160.0;
    final double avatarTopOffset =
        (expandedHeight - shrinkOffset - avatarSize / 1.5).clamp(
          kToolbarHeight - avatarSize / 2, // Min top (when collapsed)
          expandedHeight - avatarSize / 3, // Max top (when expanded)
        );

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Container(
          child:
              _avatarBytes != null
                  ? Image.memory(
                    _avatarBytes,
                    fit: BoxFit.cover,
                    key: ValueKey(user.avatar),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5),
                      );
                    },
                  )
                  : Container(color: Theme.of(context).colorScheme.primary),
        ),

        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.0),
              ),
            ),
          ),
        ),

        Positioned(
          top: Dimens.paddingVertical * 2.5,
          right: Dimens.paddingHorizontal,
          child: PopupMenuButton<ProfileHeaderAction>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (ProfileHeaderAction result) async {
              switch (result) {
                case ProfileHeaderAction.signOut:
                  await signOut();
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<ProfileHeaderAction>>[
                  PopupMenuItem<ProfileHeaderAction>(
                    value: ProfileHeaderAction.signOut,
                    child: TextButton.icon(
                      label: Text(
                        "Sign Out",
                        style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.labelMedium?.fontSize,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      icon: Icon(
                        Icons.exit_to_app,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () async {
                        await signOut();
                      },
                    ),
                  ),
                ],
          ),
        ),

        Positioned(
          top: avatarTopOffset,
          left: MediaQuery.of(context).size.width / 2 - avatarSize / 2,
          child: GestureDetector(
            onTap: showImageSourceActionSheet,
            child: Stack(
              children: [
                SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Border Layer (Outer Hexagon)
                      ClipPath(
                        clipper: HexagonClipper(),
                        child: Badge(
                          alignment: Alignment(1, -0.75),
                          smallSize: 64,
                          backgroundColor:
                              user.isDiscoverable
                                  ? Colors.greenAccent
                                  : Colors.grey.withValues(alpha: 0.5),
                          child: Container(
                            width: avatarSize,
                            height: avatarSize,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: ClipPath(
                          clipper: HexagonClipper(),
                          child: Container(
                            decoration:
                                _avatarImageProvider != null
                                    ? BoxDecoration(
                                      image: DecorationImage(
                                        image: _avatarImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : BoxDecoration(
                                      // For initials
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                            child:
                                _avatarImageProvider == null
                                    ? Center(
                                      // Center the initials text
                                      child: Text(
                                        user.initials,
                                        style: TextStyle(
                                          // Adjust font size if needed to fit smaller inner hexagon
                                          fontSize: (avatarSize / 3).clamp(
                                            10,
                                            38,
                                          ),
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                    : null, // No child if image is shown
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPickingImage)
                  const Positioned(
                    // Adjust if needed for aesthetics with border
                    right: 4,
                    bottom: 4,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
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
  bool shouldRebuild(covariant ProfileHeaderDelegate oldDelegate) {
    return user.username != oldDelegate.user.username ||
        user.avatar != oldDelegate.user.avatar ||
        user.initials != oldDelegate.user.initials || // If initials can change
        isPickingImage != oldDelegate.isPickingImage ||
        showImageSourceActionSheet != oldDelegate.showImageSourceActionSheet;
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Calculate dimensions for a "pointy-top" regular hexagon
    // 'r' is the radius of the circumscribing circle, and also the side length of the hexagon.
    // We want the hexagon's height to be size.height.
    // For a pointy-top hexagon, height = 2 * r. So, r = size.height / 2.
    final double r = size.height / 2;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // The horizontal distance from center to the points where the angled sides meet the vertical center line of side edges.
    // This is r * cos(30 degrees) or r * (sqrt(3)/2)
    final double hexWidthSegment =
        r * math.cos(math.pi / 6); // pi/6 is 30 degrees

    path.moveTo(centerX, centerY - r); // Top center point (Point A)
    path.lineTo(
      centerX + hexWidthSegment,
      centerY - r / 2,
    ); // Top right point (Point B)
    path.lineTo(
      centerX + hexWidthSegment,
      centerY + r / 2,
    ); // Bottom right point (Point C)
    path.lineTo(centerX, centerY + r); // Bottom center point (Point D)
    path.lineTo(
      centerX - hexWidthSegment,
      centerY + r / 2,
    ); // Bottom left point (Point E)
    path.lineTo(
      centerX - hexWidthSegment,
      centerY - r / 2,
    ); // Top left point (Point F)
    path.close(); // Connects Point F back to Point A

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false; // The shape is static, so no need to reclip unless clipper parameters change
}
