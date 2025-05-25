import 'dart:convert';

import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:http/http.dart' as http;

// Replace with your actual Geoapify API Key
const String _geoapifyApiKey =
    '0489b0942304447f9009aba75c8e7784'; // <-- IMPORTANT: PUT YOUR KEY HERE

class GeoapifySuggestion {
  final String displayText; // A user-friendly display string
  final String name;
  final String? street;
  final String? city;
  final String? country;
  final double latitude;
  final double longitude;
  final String placeId; // Geoapify's internal ID

  GeoapifySuggestion({
    required this.displayText,
    required this.name,
    this.street,
    this.city,
    this.country,
    required this.latitude,
    required this.longitude,
    required this.placeId,
  });

  factory GeoapifySuggestion.fromJson(Map<String, dynamic> jsonFeature) {
    final properties = jsonFeature['properties'] as Map<String, dynamic>;
    final geometry = jsonFeature['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;

    return GeoapifySuggestion(
      displayText:
          properties['formatted'] ?? properties['name'] ?? 'Unknown location',
      name: properties['name'] ?? 'N/A',
      street: properties['street'],
      city: properties['city'],
      country: properties['country'],
      latitude:
          (coordinates[1] as num)
              .toDouble(), // GeoJSON is [longitude, latitude]
      longitude:
          (coordinates[0] as num)
              .toDouble(), // GeoJSON is [longitude, latitude]
      placeId: properties['place_id'] ?? '',
    );
  }

  LocationData toLocationData() {
    return LocationData(
      name:
          name, // Or displayText, depending on what you prefer as primary name
      address: displayText, // The formatted address is good here
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  String toString() => displayText;
}

class GeoapifyService {
  static const String _baseUrl = 'api.geoapify.com';

  Future<List<GeoapifySuggestion>> fetchAutocompleteSuggestions(
    String query,
  ) async {
    final uri = Uri.https(_baseUrl, '/v1/geocode/autocomplete', {
      'text': query,
      'apiKey': _geoapifyApiKey,
      'limit': '5', // Limit number of suggestions
    });

    print(uri);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        return features
            .map(
              (feature) =>
                  GeoapifySuggestion.fromJson(feature as Map<String, dynamic>),
            )
            .toList();
      } else {
        print(
          'Geoapify Autocomplete Error: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Geoapify Autocomplete Exception: $e');
      return [];
    }
  }

  Future<LocationData?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https(_baseUrl, '/v1/geocode/reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'apiKey': _geoapifyApiKey,
    });

    print(uri);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          // Use the first, most relevant result
          final suggestion = GeoapifySuggestion.fromJson(
            features.first as Map<String, dynamic>,
          );
          return suggestion.toLocationData();
        }
        return null;
      } else {
        print(
          'Geoapify Reverse Geocode Error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Geoapify Reverse Geocode Exception: $e');
      return null;
    }
  }
}
