import 'dart:ui';

import 'package:app/domain/models/user.dart';
import 'package:flutter/material.dart';

class UserCard extends StatefulWidget {
  const UserCard({super.key, required this.user, required this.colorScheme});

  final User user;
  final ColorScheme colorScheme;

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 64.0,
      shadowColor: widget.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child:
                widget.user.avatarBytes != null
                    ? Image.memory(
                      widget.user.avatarBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    )
                    : Container(
                      color:
                          Colors
                              .primaries[widget.user.username.hashCode %
                                  Colors.primaries.length]
                              .shade100,
                      child: Center(
                        child: Text(
                          widget.user.username.isNotEmpty
                              ? widget.user.username[0].toUpperCase()
                              : "?",
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color:
                                Colors
                                    .primaries[widget.user.username.hashCode %
                                        Colors.primaries.length]
                                    .shade700,
                          ),
                        ),
                      ),
                    ),
          ),

          Positioned.fill(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    widget.colorScheme.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20.0,
            left: 20.0,
            right: 20.0,
            child: Column(
              spacing: 4.0,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "${widget.user.firstName} ${widget.user.lastName}",
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "@${widget.user.username}",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.0),
                //ClipRRect(
                //  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                //  child: BackdropFilter(
                //    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                //    child: Container(
                //      decoration: BoxDecoration(
                //        color: Theme.of(
                //          context,
                //        ).colorScheme.primaryContainer.withValues(alpha: 0.1),
                //        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                //      ),
                //      child: Padding(
                //        padding: EdgeInsets.all(16.0),
                //        child: Column(
                //          spacing: 8.0,
                //          crossAxisAlignment: CrossAxisAlignment.stretch,
                //          children: [
                //            Text(
                //              "Interests that you have in common",
                //              style: Theme.of(
                //                context,
                //              ).textTheme.bodyMedium!.copyWith(
                //                color: colorScheme!.onSurfaceVariant,
                //              ),
                //            ),
                //            Wrap(
                //              children:
                //                  widget.user.interests.map((interest) {
                //                    return BackdropFilter(
                //                      filter: ImageFilter.blur(
                //                        sigmaX: 0.5,
                //                        sigmaY: 0.5,
                //                      ),
                //                    );
                //                  }).toList(),
                //            ),
                //          ],
                //        ),
                //      ),
                //    ),
                //  ),
                //),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
