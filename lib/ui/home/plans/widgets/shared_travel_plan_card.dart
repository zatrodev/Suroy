import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SharedTravelPlanCard extends StatelessWidget {
  final TravelPlan plan;
  final VoidCallback? onTap;

  const SharedTravelPlanCard({super.key, required this.plan, this.onTap});

  @override
  Widget build(BuildContext context) {
    String dateRangeDisplay;
    try {
      final startDateFormatted = DateFormat.yMMMd().format(plan.startDate);
      final endDateFormatted = DateFormat.yMMMd().format(plan.endDate);
      if (plan.startDate.year == plan.endDate.year &&
          plan.startDate.month == plan.endDate.month &&
          plan.startDate.day == plan.endDate.day) {
        dateRangeDisplay = startDateFormatted; // Single day trip
      } else {
        dateRangeDisplay = '$startDateFormatted - $endDateFormatted';
      }
    } catch (e) {
      dateRangeDisplay = "Dates not available";
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0)),
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    child: Image.network(
                      plan.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: Colors.grey[800],
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey[600],
                              size: 30,
                            ),
                          ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[850],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Text Content Section
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 12.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            dateRangeDisplay,
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.name.isNotEmpty
                                ? plan.name
                                : "Shared Plan Activity",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                (plan.location.name.isNotEmpty
                                    ? "Exploring ${plan.location.name}"
                                    : "An exciting new adventure."),
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      top: 0,
                      right: 0,
                      child:
                          plan.ownerAvatar != null
                              ? CircleAvatar(
                                radius: 16,
                                backgroundImage: MemoryImage(plan.ownerAvatar!),
                              )
                              : Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceBright,
                                ),
                                child: Center(
                                  child: Text(
                                    plan.ownerId[0],
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall!.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
