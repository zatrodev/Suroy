import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Home extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  // final HomeViewModel viewModel; // Example

  const Home({
    super.key,
    required this.navigationShell,
    // required this.viewModel, // Example
  });

  void _onTabTapped(int index) {
    // Use the navigationShell to switch tabs.
    // This will navigate to the GOROUTE path of the new branch
    // and preserve its state.
    navigationShell.goBranch(
      index,
      // If 'initialLocation' is true, it will reset the state of the branch to its initial route.
      // If 'initialLocation' is false (default), it will restore the last visited route in that branch.
      initialLocation: index == navigationShell.currentIndex,
    );
    // viewModel.onTabChanged(index); // If using a ViewModel for index
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  // Implement drawer opening or other menu action
                  // e.g., Scaffold.of(context).openDrawer();
                  print("Menu button tapped");
                },
              ),
        ),
        title: const TextField(
          decoration: InputDecoration(
            hintText: 'Search plans',
            border: InputBorder.none,
            isDense: true,
          ),
          // style: TextStyle(fontSize: 16), // Adjust style as needed
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search action
              print("Search icon tapped");
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: CircleAvatar(
                radius: 16, // Adjust size to match Figma
                backgroundColor: Colors.deepPurple, // Example color
                child: const Text(
                  "A", // Placeholder, replace with user initials/avatar
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
        // backgroundColor: Colors.white, // Or another color from Figma
        // elevation: 1.0, // Or as per Figma design
      ),
      // drawer: YourAppDrawer(), // If you have a drawer
      body: navigationShell, // This widget displays the current tab's page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border_outlined), // Figma has star for Plans
            activeIcon: Icon(Icons.star), // Filled star for active
            label: 'Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined), // Using a 'social' icon
            activeIcon: Icon(Icons.group),
            label: 'Social',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Theme.of(context).primaryColor, // Match your theme
        unselectedItemColor: Theme.of(context).primaryColor,
        showUnselectedLabels: true, // Recommended for clarity
        type:
            BottomNavigationBarType.fixed, // Ensures labels are always visible
      ),
    );
  }
}
