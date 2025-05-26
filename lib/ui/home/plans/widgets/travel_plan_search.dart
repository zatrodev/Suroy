import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  bool _isDateMatch(String searchTerm, DateTime date) {
    // Try different date formats
    final dateFormats = [
      'yyyy-MM-dd', // 2024-03-20
      'MMMM d', // March 20
      'MMM d', // Mar 20
      'd MMMM', // 20 March
      'd MMM', // 20 Mar
    ];

    for (final format in dateFormats) {
      try {
        final formattedDate = DateFormat(format).format(date);
        if (formattedDate.toLowerCase().contains(searchTerm.toLowerCase())) {
          return true;
        }
      } catch (e) {
        // Skip invalid format
        continue;
      }
    }
    return false;
  }

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
          hintText: 'Search by name, location, or date',
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

              // Check name and location matches
              final nameOrLocationMatch =
                  name.contains(searchTerm) ||
                  locationName.contains(searchTerm);

              // Check date matches
              final startDateMatch = _isDateMatch(searchTerm, plan.startDate);
              final endDateMatch = _isDateMatch(searchTerm, plan.endDate);

              final matches =
                  nameOrLocationMatch || startDateMatch || endDateMatch;

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
          // Format dates for display
          final dateFormat = DateFormat('MMM d, yyyy');
          final startDate = dateFormat.format(plan.startDate);
          final endDate = dateFormat.format(plan.endDate);

          return ListTile(
            leading: const Icon(Icons.travel_explore),
            title: Text(plan.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.location.name),
                Text(
                  '$startDate - $endDate',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
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
