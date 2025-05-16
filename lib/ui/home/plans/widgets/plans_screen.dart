import 'package:app/ui/home/plans/widgets/create_travel_plan_sheet.dart';
import 'package:app/ui/home/plans/widgets/travel_plan_card.dart';
import 'package:flutter/material.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Sample travel plans data
  final List<Map<String, String>> _allTravelPlans = [
    {
      'id': '1',
      'name': 'Summer Vacation',
      'dateRange': '2024-07-01 - 2024-07-15',
      'location': 'Bali, Indonesia',
    },
    {
      'id': '2',
      'name': 'Business Trip',
      'dateRange': '2024-05-10 - 2024-05-12',
      'location': 'Tokyo, Japan',
    },
    {
      'id': '3',
      'name': 'Beach Getaway',
      'dateRange': '2024-08-15 - 2024-08-20',
      'location': 'Boracay, Philippines',
    },
    {
      'id': '4',
      'name': 'Mountain Retreat',
      'dateRange': '2024-06-01 - 2024-06-05',
      'location': 'Sagada, Philippines',
    },
  ];

  List<Map<String, String>> get _filteredTravelPlans {
    if (_searchQuery.isEmpty) {
      return _allTravelPlans;
    }

    final query = _searchQuery.toLowerCase();
    return _allTravelPlans.where((plan) {
      return plan['name']!.toLowerCase().contains(query) ||
          plan['location']!.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Travel Plans'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search trips by name or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
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
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body:
          _filteredTravelPlans.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No travel plans found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search or create a new plan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredTravelPlans.length,
                itemBuilder: (context, index) {
                  final plan = _filteredTravelPlans[index];
                  return TravelPlanCard(
                    id: plan['id']!,
                    name: plan['name']!,
                    dateRange: plan['dateRange']!,
                    location: plan['location']!,
                  );
                },
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            onPressed: () {
              // Placeholder button for edit screen
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('QR Scan feature')));
            },
            child: const Icon(Icons.qr_code_scanner),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const CreateTravelPlanSheet(),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
