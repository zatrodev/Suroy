import 'dart:convert';
import 'package:http/http.dart' as http;

const String _unsplashAccessKey = 'XxO_Zrl-9NeYUxHhBQlQbUFNz_o3z1bjdNvPaYDYEtU';

class UnsplashImage {
  final String id;
  final String? description;
  final UnsplashImageUrls urls;

  UnsplashImage({required this.id, this.description, required this.urls});

  factory UnsplashImage.fromJson(Map<String, dynamic> json) {
    return UnsplashImage(
      id: json['id'],
      description: json['alt_description'] ?? json['description'],
      urls: UnsplashImageUrls.fromJson(json['urls']),
    );
  }
}

class UnsplashImageUrls {
  final String raw;
  final String full;
  final String regular;
  final String small;
  final String thumb;

  UnsplashImageUrls({
    required this.raw,
    required this.full,
    required this.regular,
    required this.small,
    required this.thumb,
  });

  factory UnsplashImageUrls.fromJson(Map<String, dynamic> json) {
    return UnsplashImageUrls(
      raw: json['raw'],
      full: json['full'],
      regular: json['regular'],
      small: json['small'],
      thumb: json['thumb'],
    );
  }
}

class UnsplashService {
  static const String _baseUrl = 'api.unsplash.com';

  Future<List<UnsplashImage>> fetchImagesForLocation(
    String locationName, {
    int count = 1,
    String orientation = 'landscape',
  }) async {
    if (locationName.trim().isEmpty) {
      print('UnsplashService: Location name is empty.');
      return [];
    }

    final queryParameters = {
      'query': locationName,
      'per_page': count.toString(),
      'orientation': orientation,
    };

    final uri = Uri.https(_baseUrl, '/search/photos', queryParameters);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Client-ID $_unsplashAccessKey',
          'Accept-Version': 'v1',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        return results
            .map(
              (imageData) =>
                  UnsplashImage.fromJson(imageData as Map<String, dynamic>),
            )
            .toList();
      } else {
        print('Unsplash API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching Unsplash images: $e');
      return [];
    }
  }
}
