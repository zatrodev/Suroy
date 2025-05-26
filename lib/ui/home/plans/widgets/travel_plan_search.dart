import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TravelPlanSearch extends StatelessWidget {
  const TravelPlanSearch({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.travelPlans,
  });

  final SearchController searchController;
  final Function(String) onSearchChanged;
  final List<TravelPlan> travelPlans;

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      searchController: searchController,
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          controller: controller,
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0),
          ),
          hintText: 'Search your trips by name or location',
          leading: const Icon(Icons.search),
          trailing: [
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                },
              ),
          ],
          onTap: () {
            controller.openView();
          },
          onChanged: (value) {
            onSearchChanged(value.trim());
            controller.openView();
          },
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        print('Search text: ${controller.text}');
        print('Number of travel plans: ${travelPlans.length}');

        if (controller.text.isEmpty) {
          return const [];
        }

        final searchTerm = controller.text.toLowerCase();
        final suggestions =
            travelPlans.where((plan) {
              final name = plan.name.toLowerCase();
              final locationName = plan.location.name.toLowerCase();
              final matches =
                  name.contains(searchTerm) ||
                  locationName.contains(searchTerm);
              print('Checking plan: $name, $locationName - Matches: $matches');
              return matches;
            }).toList();

        print('Number of suggestions: ${suggestions.length}');

        if (suggestions.isEmpty) {
          return [
            ListTile(
              leading: const Icon(Icons.search_off),
              title: Text('No matches found for "$searchTerm"'),
            ),
          ];
        }

        return suggestions.map((plan) {
          return ListTile(
            leading: const Icon(Icons.travel_explore),
            title: Text(plan.name),
            subtitle: Text(plan.location.name),
            onTap: () {
              controller.closeView(plan.name);
              onSearchChanged(plan.name);
              context.go('/plans/${plan.id}');
            },
          );
        }).toList();
      },
    );
  }
}
