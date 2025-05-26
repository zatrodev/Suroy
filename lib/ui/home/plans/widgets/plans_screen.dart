import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/routing/routes.dart';
import 'package:app/ui/home/plans/view_models/plans_viewmodel.dart';
import 'package:app/ui/home/plans/widgets/shared_travel_plan_card.dart';
import 'package:app/ui/home/plans/widgets/travel_plan_card.dart';
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
    initialItem: 1,
  );
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
            child: TextField(
              controller: _searchController,
              onChanged:
                  (value) => widget.viewModel.updateSearchText(value.trim()),
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search your trips by name or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    widget.viewModel.searchText.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
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
                  if (widget.viewModel.searchText.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40.0,
                        horizontal: 16.0,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No plans match your search',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term or clear the search.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else {
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
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
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
                }

                final travelPlans = snapshot.data!;
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
                            "Your travel plans",
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: CarouselView(
                            onTap: (index) {
                              context.go(
                                Routes.travelPlanWithId(travelPlans[index].id!),
                              );
                            },
                            itemExtent: double.infinity,
                            controller: _carouselController,
                            itemSnapping: true,
                            children:
                                travelPlans
                                    .map((plan) => TravelPlanCard(plan: plan))
                                    .toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
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
                          return SharedTravelPlanCard(plan: plan);
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
          SizedBox(height: 16),
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
