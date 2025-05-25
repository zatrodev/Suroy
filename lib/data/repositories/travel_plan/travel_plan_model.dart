import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // For checklist item IDs etc.

class LocationData {
  final String name; // Name from autocomplete/map selection
  final String? address; // Full address if available
  final double latitude;
  final double longitude;

  LocationData({
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
  });

  // Convert LocationData object to a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create LocationData object from a Firestore Map
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: json['name'] ?? 'Unknown Location',
      address: json['address'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
}

class FlightDetails {
  final String? airline;
  final String? flightNumber;
  final String? departureAirport;
  final String? arrivalAirport;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String? bookingReference;

  FlightDetails({
    this.airline,
    this.flightNumber,
    this.departureAirport,
    this.arrivalAirport,
    this.departureTime,
    this.arrivalTime,
    this.bookingReference,
  });

  Map<String, dynamic> toJson() {
    return {
      'airline': airline,
      'flightNumber': flightNumber,
      'departureAirport': departureAirport,
      'arrivalAirport': arrivalAirport,
      'departureTime':
          departureTime != null ? Timestamp.fromDate(departureTime!) : null,
      'arrivalTime':
          arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
      'bookingReference': bookingReference,
    };
  }

  factory FlightDetails.fromJson(Map<String, dynamic> json) {
    return FlightDetails(
      airline: json['airline'],
      flightNumber: json['flightNumber'],
      departureAirport: json['departureAirport'],
      arrivalAirport: json['arrivalAirport'],
      departureTime: (json['departureTime'] as Timestamp?)?.toDate(),
      arrivalTime: (json['arrivalTime'] as Timestamp?)?.toDate(),
      bookingReference: json['bookingReference'],
    );
  }
}

class Accommodation {
  final String? name;
  final String? address;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String? bookingReference;

  Accommodation({
    this.name,
    this.address,
    this.checkInDate,
    this.checkOutDate,
    this.bookingReference,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'checkInDate':
          checkInDate != null ? Timestamp.fromDate(checkInDate!) : null,
      'checkOutDate':
          checkOutDate != null ? Timestamp.fromDate(checkOutDate!) : null,
      'bookingReference': bookingReference,
    };
  }

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    return Accommodation(
      name: json['name'],
      address: json['address'],
      checkInDate: (json['checkInDate'] as Timestamp?)?.toDate(),
      checkOutDate: (json['checkOutDate'] as Timestamp?)?.toDate(),
      bookingReference: json['bookingReference'],
    );
  }
}

class ChecklistItem {
  final String id;
  String task;
  bool isCompleted;

  ChecklistItem({
    required this.id,
    required this.task,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'task': task, 'isCompleted': isCompleted};
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] ?? const Uuid().v4(), // Generate ID if missing (fallback)
      task: json['task'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class ItineraryItem {
  final String id; // Unique ID for this item
  String title;
  String? description;
  DateTime? startTime; // For detailed time schedule
  DateTime? endTime; // For detailed time schedule
  LocationData? location; // Optional specific location for this item
  String? type; // e.g., 'activity', 'transport', 'meal', 'lodging'

  ItineraryItem({
    required this.id,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.location,
    this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'location': location?.toJson(), // Store nested location map
      'type': type,
    };
  }

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] ?? const Uuid().v4(),
      title: json['title'] ?? 'Untitled Item',
      description: json['description'],
      startTime: (json['startTime'] as Timestamp?)?.toDate(),
      endTime: (json['endTime'] as Timestamp?)?.toDate(),
      location:
          json['location'] != null
              ? LocationData.fromJson(json['location'])
              : null,
      type: json['type'],
    );
  }
}

// --- Main TravelPlan Model ---

class TravelPlan {
  String? id; // Firestore Document ID
  String name;
  DateTime startDate;
  DateTime endDate;
  LocationData location; // Main trip location
  String ownerId; // User ID of the creator
  List<String> sharedWith; // List of User IDs it's shared with

  // Optional fields
  FlightDetails? flightDetails;
  Accommodation? accommodation;
  String? notes;
  List<ChecklistItem>? checklist;
  // Itinerary: Map where key is the Date (e.g., "YYYY-MM-DD")
  // and value is a list of itinerary items for that day.
  Map<String, List<ItineraryItem>>? itinerary;

  DateTime createdAt;
  DateTime updatedAt;

  TravelPlan({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.ownerId,
    this.sharedWith = const [],
    this.flightDetails,
    this.accommodation,
    this.notes,
    this.checklist,
    this.itinerary,
    required this.createdAt,
    required this.updatedAt,
  });

  TravelPlan copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    LocationData? location,
    String? ownerId,
    List<String>? sharedWith,
    // Use ValueGetter for explicit null setting on nullable fields if needed
    Maybe<FlightDetails?>? flightDetailsOrNull,
    Maybe<Accommodation?>? accommodationOrNull,
    Maybe<String?>? notesOrNull,
    Maybe<List<ChecklistItem>?>? checklistOrNull,
    Maybe<Map<String, List<ItineraryItem>>?>? itineraryOrNull,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TravelPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location:
          location ??
          this.location, // Assumes LocationData is immutable or has its own copyWith if needed for deep copies
      ownerId: ownerId ?? this.ownerId,
      sharedWith:
          sharedWith ??
          List.unmodifiable(
            this.sharedWith,
          ), // Create new list if provided, else use existing
      // Handle setting optional fields to null explicitly if needed
      flightDetails:
          flightDetailsOrNull != null ? flightDetailsOrNull() : flightDetails,
      accommodation:
          accommodationOrNull != null ? accommodationOrNull() : accommodation,
      notes: notesOrNull != null ? notesOrNull() : notes,
      checklist:
          checklistOrNull != null
              ? checklistOrNull()
              : (checklist != null ? List.unmodifiable(checklist!) : null),
      itinerary:
          itineraryOrNull != null
              ? itineraryOrNull()
              : (itinerary != null ? Map.unmodifiable(itinerary!) : null),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // --- Firestore Serialization ---

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location.toJson(), // Use helper model toJson
      'ownerId': ownerId,
      'sharedWith': sharedWith,
      'flightDetails':
          flightDetails?.toJson(), // Use helper model toJson or null
      'accommodation':
          accommodation?.toJson(), // Use helper model toJson or null
      'notes': notes,
      'checklist':
          checklist
              ?.map((item) => item.toJson())
              .toList(), // Convert list of items
      // Convert itinerary Map keys to String, values to List<Map>
      'itinerary': itinerary?.map(
        (dateStr, items) =>
            MapEntry(dateStr, items.map((item) => item.toJson()).toList()),
      ),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // --- Firestore Deserialization ---

  factory TravelPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for TravelPlan ID: ${snapshot.id}');
    }

    // Deserialize itinerary (handle potential null and type issues)
    Map<String, List<ItineraryItem>>? deserializedItinerary;
    final rawItinerary =
        data['itinerary'] as Map<String, dynamic>?; // Get raw map
    if (rawItinerary != null) {
      deserializedItinerary = rawItinerary.map((dateStr, itemsRaw) {
        final itemsList =
            (itemsRaw as List<dynamic>?)
                ?.map(
                  (itemRaw) =>
                      ItineraryItem.fromJson(itemRaw as Map<String, dynamic>),
                )
                .toList() ??
            []; // Handle null list or items
        return MapEntry(dateStr, itemsList);
      });
    }

    return TravelPlan(
      id: snapshot.id,
      name: data['name'] ?? 'Untitled Plan',
      // Handle Timestamp conversion safely
      startDate: (data['startDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      endDate: (data['endDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      location: LocationData.fromJson(
        data['location'] as Map<String, dynamic>? ?? {},
      ), // Handle null location map
      ownerId: data['ownerId'] ?? '', // Handle missing owner
      sharedWith: List<String>.from(
        data['sharedWith'] ?? [],
      ), // Handle missing sharedWith
      // Handle optional nested models
      flightDetails:
          data['flightDetails'] != null
              ? FlightDetails.fromJson(
                data['flightDetails'] as Map<String, dynamic>,
              )
              : null,
      accommodation:
          data['accommodation'] != null
              ? Accommodation.fromJson(
                data['accommodation'] as Map<String, dynamic>,
              )
              : null,
      notes: data['notes'],
      // Handle optional list of checklist items
      checklist:
          (data['checklist'] as List<dynamic>?)
              ?.map(
                (itemData) =>
                    ChecklistItem.fromJson(itemData as Map<String, dynamic>),
              )
              .toList(),
      // Use the deserialized itinerary map
      itinerary: deserializedItinerary,

      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}

typedef Maybe<T> = T Function();
