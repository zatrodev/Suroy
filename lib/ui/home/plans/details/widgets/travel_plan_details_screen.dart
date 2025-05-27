import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/routing/routes.dart';
import 'package:app/ui/core/ui/app_snackbar.dart';
import 'package:app/ui/core/ui/error_indicator.dart';
import 'package:app/ui/home/plans/details/view_models/travel_plan_details_viewmodel.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TravelPlanDetailsScreen extends StatefulWidget {
  const TravelPlanDetailsScreen({super.key, required this.viewModel});

  final TravelPlanDetailsViewmodel viewModel;

  @override
  State<TravelPlanDetailsScreen> createState() =>
      _TravelPlanDetailsScreenState();
}

class _TravelPlanDetailsScreenState extends State<TravelPlanDetailsScreen> {
  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Travel Plan?'),
          content: const Text(
            'Are you sure you want to delete this travel plan? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // User cancelled
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(
                      dialogContext,
                    ).colorScheme.error, // Destructive action color
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return;
      widget.viewModel.deleteTravelPlan.execute();
    }
  }

  Future<void> _navigateToEditTravelPlan(BuildContext context) async {
    final dynamic result = await context.push<Result>(
      '${GoRouterState.of(context).matchedLocation}/edit',
    );

    if (result is Ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.show(
            context: context,
            content: Text("Travel plan details updated."),
            type: "success",
          ),
        );
      }
    }
  }

  @override
  void initState() {
    widget.viewModel.deleteTravelPlan.addListener(_onDeleteTravelPlanResult);
    super.initState();
  }

  @override
  void dispose() {
    widget.viewModel.deleteTravelPlan.addListener(_onDeleteTravelPlanResult);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.35;

    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.viewModel.loadTravelPlan,
        builder: (context, child) {
          if (widget.viewModel.loadTravelPlan.running) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.loadTravelPlan.error) {
            return Center(
              child: ErrorIndicator(
                title: "Failed loading travel plan.",
                label: "Go to Home",
                onPressed: () => context.go(Routes.plans),
              ),
            );
          }

          String dateRangeDisplay;
          try {
            final startDateFormatted = DateFormat.yMMMd().format(
              widget.viewModel.travelPlan!.startDate,
            );
            final endDateFormatted = DateFormat.yMMMd().format(
              widget.viewModel.travelPlan!.endDate,
            );
            if (widget.viewModel.travelPlan!.startDate.isAtSameMomentAs(
              widget.viewModel.travelPlan!.endDate,
            )) {
              dateRangeDisplay = startDateFormatted;
            } else {
              dateRangeDisplay = '$startDateFormatted - $endDateFormatted';
            }
          } catch (e) {
            dateRangeDisplay = "Dates not available";
          }

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: headerHeight,
                pinned: true, // Keeps a small app bar visible when scrolled
                stretch: true, // Allows image to stretch a bit on overscroll
                backgroundColor:
                    theme.scaffoldBackgroundColor, // Or a specific color
                iconTheme: IconThemeData(
                  color: Colors.white, // Color for back button if image is dark
                  shadows: [
                    Shadow(
                      blurRadius: 1.0,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ],
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                    StretchMode.fadeTitle,
                  ],
                  centerTitle:
                      true, // Or false if you want title left-aligned when collapsed
                  // Title when collapsed (optional, if different from expanded title)
                  // title: Text(
                  //   plan.name,
                  //   style: TextStyle(
                  //     color: Colors.white, // Ensure visibility
                  //     fontSize: 16.0,
                  //     shadows: [Shadow(blurRadius: 1.0, color: Colors.black.withOpacity(0.7))]
                  //   ),
                  // ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Header Image
                      if (widget.viewModel.travelPlan!.thumbnail.isNotEmpty)
                        Image.network(
                          widget.viewModel.travelPlan!.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 60,
                                ),
                              ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: colorScheme.surfaceContainerLowest,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          // Fallback if no thumbnail
                          color: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: colorScheme.onPrimaryContainer,
                            size: 80,
                          ),
                        ),

                      // Scrim/Gradient for text readability at the bottom
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Overlaid Title and Date Range
                      Positioned(
                        bottom: 16.0,
                        left: 16.0,
                        right: 16.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.viewModel.travelPlan!.name.isNotEmpty
                                  ? widget.viewModel.travelPlan!.name
                                  : "Travel Plan Details",
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              dateRangeDisplay,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                shadows: [
                                  Shadow(
                                    blurRadius: 1.0,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Details Section ---
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildDetailSectionTitle(context, "Primary Details"),
                    _buildDetailItem(
                      context,
                      icon: Icons.location_city_outlined,
                      label: "Destination",
                      value:
                          widget.viewModel.travelPlan!.location.name.isNotEmpty
                              ? widget.viewModel.travelPlan!.location.name
                              : "Not specified",
                      subtitle: widget.viewModel.travelPlan!.location.address,
                    ),
                    _buildDetailItem(
                      context,
                      icon: Icons.person_outline,
                      label: "Created By",
                      value:
                          "User: ${widget.viewModel.travelPlan!.ownerId.isNotEmpty ? widget.viewModel.travelPlan!.ownerId : 'Unknown'}",
                    ),
                    if (widget.viewModel.travelPlan!.sharedWith.isNotEmpty)
                      _buildDetailItem(
                        context,
                        icon: Icons.people_alt_outlined,
                        label: "Shared With",
                        value:
                            "${widget.viewModel.travelPlan!.sharedWith.length} participant${widget.viewModel.travelPlan!.sharedWith.length > 1 ? 's' : ''}",
                      ),

                    const SizedBox(height: 16),
                    // --- Placeholders for Optional Sections ---
                    if (widget.viewModel.travelPlan!.notes != null &&
                        widget.viewModel.travelPlan!.notes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailSectionTitle(context, "Notes"),
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerLowest,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            widget.viewModel.travelPlan!.notes!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],

                    if (widget.viewModel.travelPlan!.flightDetails != null) ...[
                      _buildDetailSectionTitle(context, "Flight Details"),
                      _buildFlightDetailsView(
                        context,
                        widget.viewModel.travelPlan!.flightDetails!,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- Accommodation ---
                    if (widget.viewModel.travelPlan!.accommodation != null) ...[
                      _buildDetailSectionTitle(context, "Accommodation"),
                      _buildAccommodationDetailsView(
                        context,
                        widget.viewModel.travelPlan!.accommodation!,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- Checklist ---
                    if (widget.viewModel.travelPlan!.checklist != null &&
                        widget.viewModel.travelPlan!.checklist!.isNotEmpty) ...[
                      _buildDetailSectionTitle(context, "Checklist"),
                      _buildChecklistView(
                        context,
                        widget.viewModel.travelPlan!.checklist!,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- Daily Itinerary ---
                    if (widget.viewModel.travelPlan!.itinerary != null &&
                        widget.viewModel.travelPlan!.itinerary!.isNotEmpty) ...[
                      _buildDetailSectionTitle(context, "Daily Itinerary"),
                      _buildItineraryView(
                        context,
                        widget.viewModel.travelPlan!.itinerary!,
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 40), // Extra space at the bottom
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 8.0,
        children: [
          FloatingActionButton.small(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
            heroTag: 'deleteFab',
            tooltip: 'View More Details',
            child: const Icon(Icons.delete_outlined),
          ),
          FloatingActionButton(
            heroTag: 'editFab',
            tooltip: 'Edit Plan',
            onPressed: () => _navigateToEditTravelPlan(context),
            child: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22.0, color: theme.colorScheme.secondary),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(value, style: theme.textTheme.bodyLarge),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Flight Details View ---
  Widget _buildFlightDetailsView(BuildContext context, FlightDetails details) {
    final theme = Theme.of(context);
    List<Widget> children = [];

    if (details.airline != null && details.airline!.isNotEmpty) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.flight_takeoff_outlined,
          label: "Airline",
          value: details.airline!,
        ),
      );
    }
    if (details.flightNumber != null && details.flightNumber!.isNotEmpty) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.confirmation_number_outlined,
          label: "Flight Number",
          value: details.flightNumber!,
        ),
      );
    }
    if (details.departureTime != null) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.schedule_outlined,
          label: "Departure Time",
          value: DateFormat.yMMMd().add_jm().format(details.departureTime!),
        ),
      );
    }
    if (details.departureAirport != null &&
        details.departureAirport!.isNotEmpty) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.connecting_airports_outlined,
          label: "Departure Airport",
          value: details.departureAirport!,
        ),
      );
    }
    if (details.arrivalTime != null) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.schedule_outlined,
          label: "Arrival Time",
          value: DateFormat.yMMMd().add_jm().format(details.arrivalTime!),
        ),
      );
    }
    if (details.arrivalAirport != null && details.arrivalAirport!.isNotEmpty) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.connecting_airports_outlined,
          label: "Arrival Airport",
          value: details.arrivalAirport!,
        ),
      );
    }
    if (details.bookingReference != null &&
        details.bookingReference!.isNotEmpty) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.bookmark_border_outlined,
          label: "Booking Reference",
          value: details.bookingReference!,
        ),
      );
    }

    if (children.isEmpty) {
      return Text(
        "No specific flight details provided.",
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(children: children);
  }

  // --- Accommodation Details View ---
  Widget _buildAccommodationDetailsView(
    BuildContext context,
    Accommodation details,
  ) {
    final theme = Theme.of(context);
    List<Widget> children = [];

    if (details.name != null && details.name!.isNotEmpty) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.hotel_outlined,
          label: "Name",
          value: details.name!,
        ),
      );
    }
    if (details.address != null && details.address!.isNotEmpty) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.location_on_outlined,
          label: "Address",
          value: details.address!,
        ),
      );
    }
    if (details.checkInDate != null) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.calendar_today_outlined,
          label: "Check-in",
          value: DateFormat.yMMMd().add_jm().format(details.checkInDate!),
        ),
      );
    }
    if (details.checkOutDate != null) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.calendar_today_outlined,
          label: "Check-out",
          value: DateFormat.yMMMd().add_jm().format(details.checkOutDate!),
        ),
      );
    }
    if (details.bookingReference != null &&
        details.bookingReference!.isNotEmpty) {
      children.add(
        _buildDetailItem(
          context,
          icon: Icons.bookmark_border_outlined,
          label: "Booking Reference",
          value: details.bookingReference!,
        ),
      );
    }

    if (children.isEmpty) {
      return Text(
        "No specific accommodation details provided.",
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(children: children);
  }

  // --- Checklist View ---
  Widget _buildChecklistView(BuildContext context, List<ChecklistItem> items) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Text(
        "Checklist is empty.",
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            item.isCompleted
                ? Icons.check_box_outlined
                : Icons.check_box_outline_blank_outlined,
            color:
                item.isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            item.task,
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              color:
                  item.isCompleted
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const Divider(height: 1),
    );
  }

  // --- Itinerary View ---
  Widget _buildItineraryView(
    BuildContext context,
    Map<String, List<ItineraryItem>> itinerary,
  ) {
    final theme = Theme.of(context);
    if (itinerary.isEmpty) {
      return Text(
        "No itinerary planned yet.",
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Sort itinerary days by date
    List<String> sortedDateKeys =
        itinerary.keys.toList()..sort(
          (a, b) => DateFormat(
            'yyyy-MM-dd',
          ).parse(a).compareTo(DateFormat('yyyy-MM-dd').parse(b)),
        );

    List<Widget> dayWidgets = [];
    for (String dateKey in sortedDateKeys) {
      final itemsForDay = itinerary[dateKey]!;
      // Sort items within the day by start time
      itemsForDay.sort((a, b) {
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      });

      dayWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            DateFormat.yMMMMEEEEd().format(
              DateFormat('yyyy-MM-dd').parse(dateKey),
            ), // e.g., Monday, September 12, 2023
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      );

      if (itemsForDay.isEmpty) {
        dayWidgets.add(
          Text(
            "No activities planned for this day.",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else {
        for (var item in itemsForDay) {
          dayWidgets.add(
            Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: _getIconForItineraryItemType(item.type, theme),
                title: Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.startTime != null)
                      Text(
                        "Time: ${DateFormat.jm().format(item.startTime!)}${item.endTime != null ? ' - ${DateFormat.jm().format(item.endTime!)}' : ''}",
                        style: theme.textTheme.bodySmall,
                      ),
                    if (item.location != null && item.location!.name.isNotEmpty)
                      Text(
                        "Location: ${item.location!.name}",
                        style: theme.textTheme.bodySmall,
                      ),
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          item.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                isThreeLine:
                    (item.description != null &&
                        item.description!.isNotEmpty &&
                        (item.startTime != null ||
                            (item.location != null &&
                                item.location!.name.isNotEmpty))),
              ),
            ),
          );
        }
      }
      dayWidgets.add(const SizedBox(height: 8)); // Space after each day's items
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dayWidgets,
    );
  }

  Icon? _getIconForItineraryItemType(String? type, ThemeData theme) {
    switch (type?.toLowerCase()) {
      case 'activity':
        return Icon(
          Icons.local_activity_outlined,
          color: theme.colorScheme.tertiary,
        );
      case 'meal':
        return Icon(
          Icons.restaurant_outlined,
          color: theme.colorScheme.tertiary,
        );
      case 'transport':
        return Icon(
          Icons.directions_bus_outlined,
          color: theme.colorScheme.tertiary,
        );
      case 'lodging':
        return Icon(Icons.hotel_outlined, color: theme.colorScheme.tertiary);
      default:
        return Icon(
          Icons.attractions_outlined,
          color: theme.colorScheme.tertiary,
        );
    }
  }

  void _onDeleteTravelPlanResult() {
    if (!mounted) return;
    final state = widget.viewModel.deleteTravelPlan;

    if (state.completed) {
      final result = state.result;
      state.clearResult();

      if (result == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.show(
              context: context,
              content: const Text(
                "An unexpected error occurred while deleting.",
              ),
              type: "error",
            ),
          );
        }

        return;
      }

      switch (result) {
        case Ok<void>():
          if (context.mounted) {
            context.go(Routes.plans);
          }
          return;
        case Error():
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppSnackBar.show(
                context: context,
                content: Text(
                  "Error while deleting your travel plan: ${result.error}",
                ),
                type: "error",
              ),
            );
          }
          return;
      }
    }
  }
}
