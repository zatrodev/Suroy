import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/routing/routes.dart';
import 'package:app/ui/home/plans/view_models/plans_viewmodel.dart';
import 'package:app/ui/home/plans/widgets/shared_travel_plan_card.dart';
import 'package:app/ui/home/plans/widgets/travel_plan_card.dart';
import 'package:app/ui/home/plans/widgets/travel_plan_search.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key, required this.viewModel});

  final TravelPlanViewmodel viewModel;

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final CarouselController _carouselController = CarouselController(
    initialItem: 0,
  );
  final SearchController _searchController = SearchController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      widget.viewModel.updateSearchText(_searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Suroy',
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.go(Routes.notifications);
            },
            icon: Icon(Icons.notifications),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: StreamBuilder<List<TravelPlan>>(
              stream: widget.viewModel.watchMyTravelPlans(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                return TravelPlanSearch(
                  searchController: _searchController,
                  onSearchChanged: widget.viewModel.updateSearchText,
                  travelPlans: snapshot.data!,
                );
              },
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<List<TravelPlan>>(
              stream: widget.viewModel.watchMyTravelPlans(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Oops! Something went wrong.'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40.0,
                        horizontal: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.luggage_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 20),
                          Column(
                            children: [
                              Text(
                                'You have no travel plans yet.',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Tap the "+" button to create one!',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final travelPlans = snapshot.data!;

                final sortedPlans = List<TravelPlan>.from(travelPlans)
                  ..sort((a, b) => a.startDate.compareTo(b.startDate));

                // Get upcoming trips (max 2)
                final upcomingTrips = sortedPlans.take(2).toList();
                final remainingPlans = sortedPlans.skip(2).toList();

                print("TRAVEL PLANS: $travelPlans");

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: Text(
                            "Upcoming",
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: CarouselView(
                            itemExtent:
                                upcomingTrips.length == 1
                                    ? double.infinity
                                    : 360,
                            onTap: (index) {
                              context.go(
                                Routes.travelPlanWithId(travelPlans[index].id!),
                              );
                            },
                            controller: _carouselController,
                            itemSnapping: true,
                            children:
                                upcomingTrips
                                    .map((plan) => TravelPlanCard(plan: plan))
                                    .toList(),
                          ),
                        ),
                      ],
                    ),

                    // All Travel Plans List
                    remainingPlans.isNotEmpty
                        ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 16,
                            children: [
                              Text(
                                "Your Travel Plans",
                                style: Theme.of(context).textTheme.titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: remainingPlans.length,
                                itemBuilder: (context, index) {
                                  final plan = remainingPlans[index];
                                  return SharedTravelPlanCard(
                                    plan: plan,
                                    onTap: () {
                                      context.go('/plans/${plan.id}');
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                        : SizedBox.shrink(),
                  ],
                );
              },
            ),

            // Shared Travel Plans Section
            StreamBuilder<List<TravelPlan>>(
              stream: widget.viewModel.watchSharedTravelPlans(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Oops! Something went wrong.'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox.shrink();
                }

                final sharedTravelPlans = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      Text(
                        "Shared with you",
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sharedTravelPlans.length,
                        itemBuilder: (context, index) {
                          final plan = sharedTravelPlans[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SharedTravelPlanCard(plan: plan),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 8.0,
        children: [
          FloatingActionButton.small(
            heroTag: "qrFab",
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('QR Scan feature')));
            },
            child: const Icon(Icons.qr_code_scanner),
          ),
          FloatingActionButton(
            heroTag: null,
            onPressed: () {
              context.go(Routes.addPlan);
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
