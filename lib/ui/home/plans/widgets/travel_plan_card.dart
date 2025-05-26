import 'dart:ui';

import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TravelPlanCard extends StatefulWidget {
  final TravelPlan plan;

  const TravelPlanCard({super.key, required this.plan});

  @override
  State<TravelPlanCard> createState() => _TravelPlanCardState();
}

class _TravelPlanCardState extends State<TravelPlanCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String dateRangeDisplay;
    try {
      final startDateFormatted = DateFormat.yMMMd().format(
        widget.plan.startDate,
      );
      final endDateFormatted = DateFormat.yMMMd().format(widget.plan.endDate);
      if (widget.plan.startDate.year == widget.plan.endDate.year &&
          widget.plan.startDate.month == widget.plan.endDate.month &&
          widget.plan.startDate.day == widget.plan.endDate.day) {
        dateRangeDisplay = startDateFormatted; // Single day trip
      } else {
        dateRangeDisplay = '$startDateFormatted - $endDateFormatted';
      }
    } catch (e) {
      dateRangeDisplay = "Dates not available";
    }

    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.network(
              widget.plan.thumbnail,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey[400],
                      size: 60,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                  ),
                );
              },
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            top: 16.0,
            right: 16.0,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(
                      20.0,
                    ), // Make it pill-shaped
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14.0, // Adjusted size for pill
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4.0), // Slightly reduced spacing
                      Flexible(
                        child: Text(
                          widget.plan.location.name.isNotEmpty
                              ? widget.plan.location.name
                              : "Unknown Location",
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onSurface, // Contrasting color
                          ),
                          overflow: TextOverflow.ellipsis, // Good to keep
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12.0,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          dateRangeDisplay,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    widget.plan.name.isNotEmpty
                        ? widget.plan.name
                        : "Untitled Plan",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // const SizedBox(height: 6.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // return Card(
    //   color:
    //       Theme.of(context).brightness == Brightness.light
    //           ? Colors.transparent
    //           : Theme.of(context).colorScheme.surfaceContainer,
    //   elevation: 0,
    //   margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    //   clipBehavior: Clip.antiAlias,
    //   child: InkWell(
    //     onTap: widget.onTap,
    //     splashColor: colorScheme.primary.withValues(alpha: 0.1),
    //     highlightColor: colorScheme.primary.withValues(alpha: 0.05),
    //     child: Column(
    //       children: [
    //         SizedBox(
    //           height: 150,
    //           width: double.infinity,
    //           child:
    //               _isLoadingImage
    //                   ? Container(
    //                     color: Colors.grey[300],
    //                     child: const Center(
    //                       child: CircularProgressIndicator(strokeWidth: 2.0),
    //                     ),
    //                   )
    //                   : _imageError || _fetchedImage == null
    //                   ? Container(
    //                     color: Colors.grey[200],
    //                     child: Center(
    //                       child: Icon(
    //                         Icons.broken_image_outlined,
    //                         color: Colors.grey[400],
    //                         size: 40,
    //                       ),
    //                     ),
    //                   )
    //                   : Image.network(
    //                     _fetchedImage!.urls.regular,
    //                     fit: BoxFit.cover,
    //                     errorBuilder: (context, error, stackTrace) {
    //                       print(
    //                         "Image.network error for ${widget.plan.name}: $error",
    //                       );
    //                       return Container(
    //                         color: Colors.grey[200],
    //                         child: Center(
    //                           child: Icon(
    //                             Icons.error_outline,
    //                             color: Colors.grey[400],
    //                             size: 40,
    //                           ),
    //                         ),
    //                       );
    //                     },
    //                     loadingBuilder: (
    //                       BuildContext context,
    //                       Widget child,
    //                       ImageChunkEvent? loadingProgress,
    //                     ) {
    //                       if (loadingProgress == null) return child;
    //                       return Center(
    //                         child: CircularProgressIndicator(
    //                           value:
    //                               loadingProgress.expectedTotalBytes != null
    //                                   ? loadingProgress.cumulativeBytesLoaded /
    //                                       loadingProgress.expectedTotalBytes!
    //                                   : null,
    //                         ),
    //                       );
    //                     },
    //                   ),
    //         ),
    //         Padding(
    //           padding: const EdgeInsets.all(16.0),
    //           child: Column(
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: [
    //               // Dates
    //               Row(
    //                 children: [
    //                   Icon(
    //                     Icons.calendar_today_outlined,
    //                     size: 12.0,
    //                     color: colorScheme.primary,
    //                   ),
    //                   const SizedBox(width: 8.0),
    //                   Expanded(
    //                     child: Text(
    //                       dateRangeDisplay,
    //                       style: theme.textTheme.bodySmall?.copyWith(
    //                         color: colorScheme.onSurfaceVariant,
    //                       ),
    //                       overflow: TextOverflow.ellipsis,
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //               Text(
    //                 widget.plan.name.isNotEmpty
    //                     ? widget.plan.name
    //                     : "Untitled Plan",
    //                 style: theme.textTheme.titleMedium?.copyWith(),
    //                 maxLines: 2,
    //                 overflow: TextOverflow.ellipsis,
    //               ),
    //               const SizedBox(height: 12.0),
    //
    //               // Location
    //               Row(
    //                 children: [
    //                   Icon(
    //                     Icons.location_on_outlined,
    //                     size: 16.0,
    //                     color: colorScheme.secondary,
    //                   ),
    //                   const SizedBox(width: 8.0),
    //                   Expanded(
    //                     child: Text(
    //                       widget.plan.location.name.isNotEmpty
    //                           ? widget.plan.location.name
    //                           : "Unknown Location",
    //                       style: theme.textTheme.bodyMedium?.copyWith(
    //                         color: colorScheme.onSurfaceVariant,
    //                       ),
    //                       overflow: TextOverflow.ellipsis,
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ],
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}
