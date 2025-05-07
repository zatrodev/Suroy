import 'package:flutter/material.dart';
import 'package:app/ui/screens/home/widgets/travel_plan_card.dart';
import 'package:app/ui/screens/home/widgets/create_travel_plan_sheet.dart';
import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

// TEMPORARY: Logout button
  Future<void> _handleLogout(BuildContext context) async {
    final authRepository = context.read<AuthRepository>();
    final result = await authRepository.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // TEMPORARY: Sample travel plans
    final sampleTravelPlans = [
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Travel Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // TODO: Implement QR code scanning
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sampleTravelPlans.length,
        itemBuilder: (context, index) {
          final plan = sampleTravelPlans[index];
          return TravelPlanCard(
            id: plan['id']!,
            name: plan['name']!,
            dateRange: plan['dateRange']!,
            location: plan['location']!,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const CreateTravelPlanSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
