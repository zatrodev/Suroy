import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/data/services/geoapify/geoapify_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const MapPickerScreen({super.key, this.initialCenter});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final GeoapifyService _geoapifyService = GeoapifyService();

  LatLng? _currentMapCenter;
  LocationData? _selectedLocationData;
  bool _isGeocoding = false;
  String _displayAddress = "Move the map to select a location";

  @override
  void initState() {
    super.initState();
    _currentMapCenter =
        widget.initialCenter ??
        const LatLng(14.599512, 120.984222); // Default to London
    // Fetch initial address for the center point
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentMapCenter != null) {
        _reverseGeocodeAndUpdate(_currentMapCenter!);
      }
    });
  }

  Future<void> _reverseGeocodeAndUpdate(LatLng center) async {
    if (!mounted) return;
    setState(() {
      _isGeocoding = true;
      _displayAddress = "Fetching address...";
    });

    final locationData = await _geoapifyService.reverseGeocode(
      center.latitude,
      center.longitude,
    );

    if (!mounted) return;
    setState(() {
      _selectedLocationData = locationData;
      _displayAddress =
          locationData?.address ??
          locationData?.name ??
          "Could not find address. Try a different spot.";
      _isGeocoding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pick Location on Map',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.my_location),
        //     onPressed: () {
        //       if (_currentMapCenter != null) {
        //         _mapController.move(_currentMapCenter!, 13.0);
        //       }
        //     },
        //     tooltip: "Center on initial/my location",
        //   ),
        // ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentMapCenter!,
              initialZoom: 13.0,
              minZoom: 3,
              maxZoom: 18,
              onPositionChanged: (MapCamera position, bool hasGesture) {
                if (hasGesture) {
                  // Only update if user moved the map
                  if (mounted) {
                    setState(() {
                      _currentMapCenter = position.center;
                      // Debounce reverse geocoding or only do it on button press
                      // For now, let's make it less aggressive, only on explicit action or after settling
                    });
                  }
                }
              },
              // To trigger geocoding when map stops moving (more complex, requires debouncing)
              // For simplicity, we'll use a button or geocode on init and confirm.
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.app', // Replace with your app's package name
              ),
              // Consider adding attribution widget:
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap:
                        () => (
                          Uri.parse('https://openstreetmap.org/copyright'),
                        ),
                  ),
                ],
              ),
            ],
          ),
          const Center(
            child: Icon(Icons.location_pin, color: Colors.red, size: 40),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _selectedLocationData?.name ?? "Selected Location",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayAddress,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _currentMapCenter == null
                                    ? null
                                    : () {
                                      _reverseGeocodeAndUpdate(
                                        _currentMapCenter!,
                                      );
                                    },
                            child:
                                _isGeocoding
                                    ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Update Address'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                (_selectedLocationData != null && !_isGeocoding)
                                    ? () {
                                      Navigator.of(
                                        context,
                                      ).pop(_selectedLocationData);
                                    }
                                    : null,
                            child: const Text('Confirm Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
