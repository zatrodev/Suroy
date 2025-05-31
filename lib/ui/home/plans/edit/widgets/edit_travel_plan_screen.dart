import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/data/services/geoapify/geoapify_service.dart';
import 'package:app/ui/core/ui/app_snackbar.dart';
import 'package:app/ui/core/ui/error_indicator.dart';
import 'package:app/ui/core/ui/listenable_button.dart';
import 'package:app/ui/core/ui/text_field_with_label.dart';
import 'package:app/ui/home/plans/add/widgets/map_picker_screen.dart';
import 'package:app/ui/home/plans/edit/view_models/edit_travel_plan_viewmodel.dart';
import 'package:app/ui/home/plans/widgets/add_edit_itinerary_item_dialog.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:uuid/uuid.dart';

class EditTravelPlanScreen extends StatefulWidget {
  const EditTravelPlanScreen({super.key, required this.viewModel});

  final EditTravelPlanViewmodel viewModel;

  @override
  State<EditTravelPlanScreen> createState() => _EditTravelPlanScreenState();
}

class _EditTravelPlanScreenState extends State<EditTravelPlanScreen> {
  final _formKey = GlobalKey<FormState>();

  final Uuid _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _notesController;
  DateTimeRange? _selectedDateRange;
  LocationData? _selectedLocation;
  late TextEditingController _locationTextController;

  FlightDetails? _flightDetails;
  late TextEditingController _flightAirlineController;
  late TextEditingController _flightNumberController;
  late TextEditingController _flightDepartureAirportController;
  late TextEditingController _flightArrivalAirportController;
  late TextEditingController _flightBookingRefController;
  DateTime? _flightDepartureDateTime;
  DateTime? _flightArrivalDateTime;

  Accommodation? _accommodation;
  late TextEditingController _accNameController;
  late TextEditingController _accAddressController;
  late TextEditingController _accBookingRefController;
  DateTime? _accCheckInDate;
  DateTime? _accCheckOutDate;

  List<ChecklistItem> _checklistItems = [];
  late TextEditingController _newChecklistItemController;

  Map<String, List<ItineraryItem>> _itineraryData = {};
  DateTime? _currentlySelectedDayForItinerary;
  String? _selectedItineraryDateKey;

  List<String> _sharedWithUsernames = [];

  final GeoapifyService _geoapifyService = GeoapifyService();
  final List<bool> _areOptionalSectionsExpanded = [
    false,
    false,
    false,
    false,
    false,
  ];

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadTravelPlan.addListener(_initializeFormFields);
    widget.viewModel.saveChanges.addListener(_onSaveChangesResult);
  }

  Future<void> _navigateToMapPicker() async {
    final result = await Navigator.of(context).push<LocationData>(
      MaterialPageRoute(
        builder:
            (context) => MapPickerScreen(
              initialCenter:
                  _selectedLocation != null
                      ? latlong2.LatLng(
                        _selectedLocation!.latitude,
                        _selectedLocation!.longitude,
                      )
                      : null, // Pass current selection to center map
            ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _locationTextController.text =
            result.address ?? result.name; // Update text field
      });
      _formKey.currentState?.validate(); // Re-validate form
    }
  }

  Future<DateTime?> _pickOptionalDate(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? now.subtract(const Duration(days: 30)),
      lastDate: lastDate ?? now.add(const Duration(days: 365 * 5)),
    );
  }

  Future<DateTime?> _pickOptionalDateTime(
    BuildContext context, {
    DateTime? initialDateTime,
  }) async {
    final date = await _pickOptionalDate(context, initialDate: initialDateTime);
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime ?? date),
    );

    if (time == null) return date;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _initializeFormFields() {
    final plan = widget.viewModel.initialTravelPlan!;

    _nameController = TextEditingController(text: plan.name);
    _notesController = TextEditingController(text: plan.notes ?? '');
    _selectedDateRange = DateTimeRange(
      start: plan.startDate,
      end: plan.endDate,
    );
    _selectedLocation = plan.location;
    _locationTextController = TextEditingController(
      text: plan.location.address ?? plan.location.name,
    );

    _flightDetails = plan.flightDetails;
    _flightAirlineController = TextEditingController(
      text: _flightDetails?.airline ?? '',
    );
    _flightNumberController = TextEditingController(
      text: _flightDetails?.flightNumber ?? '',
    );
    _flightDepartureAirportController = TextEditingController(
      text: _flightDetails?.departureAirport ?? '',
    );
    _flightArrivalAirportController = TextEditingController(
      text: _flightDetails?.arrivalAirport ?? '',
    );
    _flightBookingRefController = TextEditingController(
      text: _flightDetails?.bookingReference ?? '',
    );
    _flightDepartureDateTime = _flightDetails?.departureTime;
    _flightArrivalDateTime = _flightDetails?.arrivalTime;

    _accommodation = plan.accommodation;
    _accNameController = TextEditingController(
      text: _accommodation?.name ?? '',
    );
    _accAddressController = TextEditingController(
      text: _accommodation?.address ?? '',
    );
    _accBookingRefController = TextEditingController(
      text: _accommodation?.bookingReference ?? '',
    );
    _accCheckInDate = _accommodation?.checkInDate;
    _accCheckOutDate = _accommodation?.checkOutDate;

    _checklistItems = List<ChecklistItem>.from(
      plan.checklist?.map(
            (item) => ChecklistItem(
              id: item.id,
              task: item.task,
              isCompleted: item.isCompleted,
            ),
          ) ??
          [],
    );
    _newChecklistItemController = TextEditingController();

    _itineraryData =
        plan.itinerary != null
            ? Map<String, List<ItineraryItem>>.from(
              plan.itinerary!.map(
                (key, value) => MapEntry(
                  key,
                  List<ItineraryItem>.from(
                    value.map(
                      (item) => ItineraryItem(
                        id: item.id,
                        title: item.title,
                        description: item.description,
                        startTime: item.startTime,
                        endTime: item.endTime,
                        location: item.location,
                        type: item.type,
                      ),
                    ),
                  ),
                ),
              ),
            )
            : {};

    _sharedWithUsernames = List<String>.from(
      plan.sharedWith,
    ); // Assuming sharedWith stores usernames/IDs

    if (_selectedDateRange != null && _itineraryData.isNotEmpty) {
      _currentlySelectedDayForItinerary = _selectedDateRange!.start;
      _selectedItineraryDateKey = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDateRange!.start);
    } else if (_selectedDateRange != null) {
      _currentlySelectedDayForItinerary = _selectedDateRange!.start;
      _selectedItineraryDateKey = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDateRange!.start);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _locationTextController.dispose();
    _flightAirlineController.dispose();
    _flightNumberController.dispose();
    _flightDepartureAirportController.dispose();
    _flightArrivalAirportController.dispose();
    _flightBookingRefController.dispose();
    _accNameController.dispose();
    _accAddressController.dispose();
    _accBookingRefController.dispose();
    _newChecklistItemController.dispose();

    widget.viewModel.loadTravelPlan.removeListener(_initializeFormFields);
    widget.viewModel.saveChanges.removeListener(_onSaveChangesResult);
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: widget.viewModel.initialTravelPlan!.startDate,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (pickedDateRange != null) {
      setState(() {
        _selectedDateRange = pickedDateRange;
        _currentlySelectedDayForItinerary = _selectedDateRange!.start;
        _itineraryData = {};
      });
    }
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.')),
      );
      return;
    }

    FlightDetails? updatedFlightDetails;
    if (_flightAirlineController.text.isNotEmpty ||
        _flightArrivalDateTime != null) {
      updatedFlightDetails = FlightDetails(
        airline: _flightAirlineController.text.trim().nullIfEmpty,
        flightNumber: _flightNumberController.text.trim().nullIfEmpty,
        departureAirport:
            _flightDepartureAirportController.text.trim().nullIfEmpty,
        arrivalAirport: _flightArrivalAirportController.text.trim().nullIfEmpty,
        departureTime: _flightDepartureDateTime,
        arrivalTime: _flightArrivalDateTime,
        bookingReference: _flightBookingRefController.text.trim().nullIfEmpty,
      );
    }

    Accommodation? updatedAccommodation;
    if (_accNameController.text.isNotEmpty || /* ... other acc fields ... */
        _accCheckOutDate != null) {
      updatedAccommodation = Accommodation(
        name: _accNameController.text.trim().nullIfEmpty,
        address: _accAddressController.text.trim().nullIfEmpty,
        checkInDate: _accCheckInDate,
        checkOutDate: _accCheckOutDate,
        bookingReference: _accBookingRefController.text.trim().nullIfEmpty,
      );
    }

    final updatedPlan = widget.viewModel.initialTravelPlan!.copyWith(
      name: _nameController.text.trim(),
      startDate: _selectedDateRange!.start,
      endDate: _selectedDateRange!.end,
      location: _selectedLocation!,
      notesOrNull: () => _notesController.text.trim().nullIfEmpty,
      flightDetailsOrNull: () => updatedFlightDetails,
      accommodationOrNull: () => updatedAccommodation,
      checklistOrNull:
          () => _checklistItems.isNotEmpty ? List.from(_checklistItems) : null,
      itineraryOrNull:
          () => _itineraryData.isNotEmpty ? Map.from(_itineraryData) : null,
      updatedAt: DateTime.now(),
      sharedWith: _sharedWithUsernames,
    );

    widget.viewModel.saveChanges.execute(updatedPlan);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Travel Plan')),
      body: ListenableBuilder(
        listenable: widget.viewModel.loadTravelPlan,
        builder: (context, _) {
          if (widget.viewModel.loadTravelPlan.running) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.loadTravelPlan.error) {
            return Center(
              child: ErrorIndicator(
                title: "Failed loading travel plan.",
                label: "Go to Home",
                onPressed: () => context.pop(),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    "Plan Essentials",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Plan Name*',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? 'Plan name is required.'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  _buildFormFieldWrapper(
                    label: "Trip Dates*",
                    child: InkWell(
                      onTap: () => _pickDateRange(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDateRange != null
                              ? '${DateFormat.yMMMd().format(_selectedDateRange!.start)} - ${DateFormat.yMMMd().format(_selectedDateRange!.end)}'
                              : 'Select Dates',
                        ),
                      ),
                    ),
                    validator:
                        () =>
                            _selectedDateRange == null
                                ? 'Trip dates are required.'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  TypeAheadField<GeoapifySuggestion>(
                    controller: _locationTextController,
                    builder: (context, controller, focusNode) {
                      return TextFieldWithLabel(
                        label: "Main Destination*",
                        textFieldLabel: "e.g. Manila, Philippines",
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (value) {
                          if (_selectedLocation != null &&
                              value !=
                                  (_selectedLocation!.address ??
                                      _selectedLocation!.name)) {
                            setState(() {
                              _selectedLocation = null;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please select a location.';
                          }

                          if (_selectedLocation == null) {
                            return "Please select a location from the suggestions.";
                          }
                          return null;
                        },
                      );
                    },
                    hideOnEmpty: true,
                    suggestionsCallback: (pattern) async {
                      if (pattern.length < 3) {
                        return [];
                      }

                      return await _geoapifyService
                          .fetchAutocompleteSuggestions(pattern);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        leading: const Icon(Icons.location_city),
                        title: Text(suggestion.name),
                        subtitle: Text(
                          suggestion.displayText.replaceFirst(
                            "${suggestion.name}, ",
                            "",
                          ),
                        ),
                      );
                    },
                    onSelected: (suggestion) {
                      _locationTextController.text = suggestion.displayText;
                      setState(() {
                        _selectedLocation = suggestion.toLocationData();
                      });
                      _formKey.currentState?.validate();
                    },
                    emptyBuilder:
                        (context) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'No locations found. Try a different search.',
                          ),
                        ),
                    loadingBuilder:
                        (context) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    errorBuilder:
                        (context, error) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Error fetching suggestions: $error',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                  ),
                  if (_selectedLocation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                      child: Text(
                        'Selected: ${_selectedLocation!.name}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Or Pick Location on Map'),
                    onPressed: _navigateToMapPicker,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Optional Details",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ExpansionPanelList(
                    expansionCallback: (int index, bool isExpanded) {
                      setState(() {
                        _areOptionalSectionsExpanded[index] = isExpanded;
                      });
                    },
                    animationDuration: const Duration(milliseconds: 300),
                    children: [
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          int totalItems = 0;
                          for (var list in _itineraryData.values) {
                            totalItems += list.length;
                          }
                          return ListTile(
                            title: Text(
                              'Daily Itinerary ($totalItems items) (Optional)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        },
                        body: _buildItinerarySection(),
                        isExpanded: _areOptionalSectionsExpanded[0],
                        canTapOnHeader: true,
                      ),
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(
                              'Flight Details (Optional)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        },
                        body: _buildFlightDetailsSection(),
                        isExpanded: _areOptionalSectionsExpanded[1],
                        canTapOnHeader: true,
                      ),
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(
                              'Accommodation (Optional)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        },
                        body: _buildAccommodationSection(),
                        isExpanded: _areOptionalSectionsExpanded[2],
                        canTapOnHeader: true,
                      ),
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(
                              'Checklist (${_checklistItems.length} items) (Optional)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        },
                        body: _buildChecklistSection(),
                        isExpanded: _areOptionalSectionsExpanded[3],
                        canTapOnHeader: true,
                      ),
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(
                              'Shared With (${_sharedWithUsernames.length} users) (Optional)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        },
                        body: _buildSharedWithSection(),
                        isExpanded:
                            _areOptionalSectionsExpanded[4], // Adjust index
                        canTapOnHeader: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ListenableButton(
                    label: "Save Changes",
                    command: widget.viewModel.saveChanges,
                    onPressed: _saveChanges,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlightDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFieldWithLabel(
            controller: _flightAirlineController,
            label: 'Airline',
            textFieldLabel: "",
          ),
          const SizedBox(height: 12),
          TextFieldWithLabel(
            controller: _flightNumberController,
            label: 'Flight Number',
            textFieldLabel: "",
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOptionalDateTimeField(
                  label: 'Departure Time',
                  selectedDateTime: _flightDepartureDateTime,
                  onTap: () async {
                    final dt = await _pickOptionalDateTime(
                      context,
                      initialDateTime: _flightDepartureDateTime,
                    );
                    if (dt != null) {
                      setState(() => _flightDepartureDateTime = dt);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOptionalDateTimeField(
                  label: 'Arrival Time',
                  selectedDateTime: _flightArrivalDateTime,
                  onTap: () async {
                    final dt = await _pickOptionalDateTime(
                      context,
                      initialDateTime: _flightArrivalDateTime,
                    );
                    if (dt != null) setState(() => _flightArrivalDateTime = dt);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFieldWithLabel(
            controller: _flightDepartureAirportController,
            label: 'Departure Airport',
            textFieldLabel: "(e.g., LHR)",
          ),
          const SizedBox(height: 12),
          TextFieldWithLabel(
            controller: _flightArrivalAirportController,
            label: 'Arrival Airport',
            textFieldLabel: "e.g. JFK",
          ),
          const SizedBox(height: 12),
          TextFieldWithLabel(
            controller: _flightBookingRefController,
            label: 'Booking Reference',
            textFieldLabel: "",
          ),
        ],
      ),
    );
  }

  Widget _buildAccommodationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFieldWithLabel(
            controller: _accNameController,
            label: 'Accommodation Name',
            textFieldLabel: "",
          ),
          const SizedBox(height: 12),
          TextFieldWithLabel(
            controller: _accAddressController,
            label: 'Address',
            textFieldLabel: "",
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOptionalDateField(
                  label: 'Check-in Date',
                  selectedDate: _accCheckInDate,
                  onTap: () async {
                    final d = await _pickOptionalDate(
                      context,
                      initialDate: _accCheckInDate,
                    );
                    if (d != null) setState(() => _accCheckInDate = d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOptionalDateField(
                  label: 'Check-out Date',
                  selectedDate: _accCheckOutDate,
                  firstDate: _accCheckInDate,
                  onTap: () async {
                    final d = await _pickOptionalDate(
                      context,
                      initialDate: _accCheckOutDate,
                      firstDate: _accCheckInDate,
                    );
                    if (d != null) setState(() => _accCheckOutDate = d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFieldWithLabel(
            controller: _accBookingRefController,
            label: 'Booking Reference',
            textFieldLabel: "",
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _checklistItems.length,
            itemBuilder: (context, index) {
              final item = _checklistItems[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(
                  value: item.isCompleted,
                  onChanged: (bool? value) {
                    setState(() {
                      item.isCompleted = value ?? false;
                    });
                  },
                ),
                title: Text(item.task),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _checklistItems.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8.0,
            children: [
              Expanded(
                child: TextFieldWithLabel(
                  controller: _newChecklistItemController,
                  label: "Add new task",
                  textFieldLabel: 'e.g. Bring passports',
                  onSubmit: (_) => _addChecklistItem(),
                ),
              ),
              ElevatedButton(
                onPressed: _addChecklistItem,
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarySection() {
    if (_selectedDateRange == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "Please select trip dates first to add itinerary items.",
          textAlign: TextAlign.center,
        ),
      );
    }

    List<DateTime> tripDays = [];
    DateTime currentDate = _selectedDateRange!.start;
    while (currentDate.isBefore(_selectedDateRange!.end) ||
        currentDate.isAtSameMomentAs(_selectedDateRange!.end)) {
      tripDays.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDaySelector(tripDays),
          const SizedBox(height: 16),

          if (_currentlySelectedDayForItinerary != null) ...[
            Text(
              "Itinerary for ${DateFormat.yMMMd().format(_currentlySelectedDayForItinerary!)}:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildItineraryListForSelectedDay(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Add Item to this Day"),
                onPressed:
                    () => _showAddEditItineraryItemDialog(
                      context,
                      _currentlySelectedDayForItinerary!,
                    ),
              ),
            ),
          ] else ...[
            const Text("Select a day above to view or add itinerary items."),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySelector(List<DateTime> tripDays) {
    if (tripDays.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<DateTime>(
      decoration: const InputDecoration(
        labelText: "Select Day for Itinerary",
        border: OutlineInputBorder(),
      ),
      value: _currentlySelectedDayForItinerary,
      hint: const Text("Choose a day"),
      items:
          tripDays.map((day) {
            return DropdownMenuItem<DateTime>(
              value: day,
              child: Text(DateFormat('EEE, MMM d, yyyy').format(day)),
            );
          }).toList(),
      onChanged: (DateTime? newValue) {
        setState(() {
          _currentlySelectedDayForItinerary = newValue;
          if (newValue != null) {
            _selectedItineraryDateKey = DateFormat(
              'yyyy-MM-dd',
            ).format(newValue);
          } else {
            _selectedItineraryDateKey = null;
          }
        });
      },
    );
  }

  Widget _buildItineraryListForSelectedDay() {
    if (_selectedItineraryDateKey == null ||
        _itineraryData[_selectedItineraryDateKey] == null ||
        _itineraryData[_selectedItineraryDateKey]!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          "No items for this day yet. Click 'Add Item' below.",
          textAlign: TextAlign.center,
        ),
      );
    }

    List<ItineraryItem> items = _itineraryData[_selectedItineraryDateKey]!;

    items.sort((a, b) {
      if (a.startTime == null && b.startTime == null) return 0;
      if (a.startTime == null) return 1;
      if (b.startTime == null) return -1;
      return a.startTime!.compareTo(b.startTime!);
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(item.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.startTime != null)
                  Text(
                    "Time: ${DateFormat.jm().format(item.startTime!)}${item.endTime != null ? ' - ${DateFormat.jm().format(item.endTime!)}' : ''}",
                  ),
                if (item.location != null)
                  Text("Location: ${item.location!.name}"),
                if (item.type != null) Text("Type: ${item.type}"),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  onPressed:
                      () => _showAddEditItineraryItemDialog(
                        context,
                        _currentlySelectedDayForItinerary!,
                        initialItem: item,
                      ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteItineraryItem(item),
                ),
              ],
            ),
            onTap:
                () => _showAddEditItineraryItemDialog(
                  context,
                  _currentlySelectedDayForItinerary!,
                  initialItem: item,
                ),
          ),
        );
      },
    );
  }

  void _deleteItineraryItem(ItineraryItem itemToDelete) {
    if (_selectedItineraryDateKey == null) return;
    setState(() {
      _itineraryData[_selectedItineraryDateKey]?.removeWhere(
        (item) => item.id == itemToDelete.id,
      );
      if (_itineraryData[_selectedItineraryDateKey]?.isEmpty ?? false) {
        _itineraryData.remove(_selectedItineraryDateKey);
      }
    });
  }

  Future<void> _showAddEditItineraryItemDialog(
    BuildContext context,
    DateTime dayOfItinerary, {
    ItineraryItem? initialItem,
  }) async {
    final result = await showDialog<ItineraryItem>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AddEditItineraryItemDialog(
          initialItem: initialItem,
          dayOfItinerary: dayOfItinerary,
        );
      },
    );

    if (result != null && _selectedItineraryDateKey != null) {
      setState(() {
        _itineraryData.putIfAbsent(_selectedItineraryDateKey!, () => []);

        final listForDay = _itineraryData[_selectedItineraryDateKey]!;
        final existingIndex = listForDay.indexWhere(
          (item) => item.id == result.id,
        );

        if (existingIndex != -1) {
          listForDay[existingIndex] = result;
        } else {
          listForDay.add(result);
        }
      });
    }
  }

  Widget _buildOptionalDateField({
    required String label,
    DateTime? selectedDate,
    required VoidCallback onTap,
    DateTime? firstDate,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        child: Text(
          selectedDate != null
              ? DateFormat.yMMMd().format(selectedDate)
              : 'Not set',
          style: TextStyle(
            color: selectedDate == null ? Theme.of(context).hintColor : null,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionalDateTimeField({
    required String label,
    DateTime? selectedDateTime,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        child: Text(
          selectedDateTime != null
              ? DateFormat.yMMMd().add_jm().format(selectedDateTime)
              : 'Not set',
          style: TextStyle(
            color:
                selectedDateTime == null ? Theme.of(context).hintColor : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFormFieldWrapper({
    required String label,
    required Widget child,
    required String? Function() validator,
    EdgeInsetsGeometry padding = const EdgeInsets.only(bottom: 0),
  }) {
    return FormField<String>(
      validator: (_) => validator(),
      builder: (FormFieldState<String> field) {
        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              child,
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 5.0),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSharedWithSection() {
    final theme = Theme.of(context);
    final List<String> allFriendsUsernames = widget.viewModel.friends;

    if (allFriendsUsernames.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Text(
          "You have no friends to share this plan with yet. Connect with friends first!",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Share with Friends:",
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (allFriendsUsernames.isNotEmpty)
          Wrap(
            spacing: 8.0, // Horizontal space between chips
            runSpacing: 8.0, // Vertical space between chip lines
            children:
                allFriendsUsernames.map((friendUsername) {
                  final bool isSelected = _sharedWithUsernames.contains(
                    friendUsername,
                  );
                  return ChoiceChip(
                    label: Text(friendUsername),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          if (!_sharedWithUsernames.contains(friendUsername)) {
                            _sharedWithUsernames.add(friendUsername);
                          }
                        } else {
                          _sharedWithUsernames.remove(friendUsername);
                        }
                      });
                    },
                    avatar:
                        isSelected
                            ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.onPrimary,
                            )
                            : null, // Or CircleAvatar(child: Text(friendUsername[0]))
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                    ),
                    // backgroundColor: theme.colorScheme.surfaceContainer, // Optional: background for unselected
                    pressElevation: 2.0,
                  );
                }).toList(),
          )
        else
          const Text(
            "No friends available to share with.",
          ), // Should be caught by the check above

        const SizedBox(height: 16),
        Text(
          "Currently sharing with:",
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        _sharedWithUsernames.isEmpty
            ? const Text(
              "Not shared with anyone yet.",
              style: TextStyle(fontStyle: FontStyle.italic),
            )
            : Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children:
                  _sharedWithUsernames.map((username) {
                    return Chip(
                      label: Text(username),
                      avatar: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Text(
                          username[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      onDeleted: () {
                        setState(() {
                          _sharedWithUsernames.remove(username);
                        });
                      },
                      deleteIconColor: theme.colorScheme.error,
                    );
                  }).toList(),
            ),
      ],
    );
  }

  void _addChecklistItem() {
    final taskText = _newChecklistItemController.text.trim();
    if (taskText.isNotEmpty) {
      setState(() {
        _checklistItems.add(
          ChecklistItem(id: _uuid.v4(), task: taskText, isCompleted: false),
        );
        _newChecklistItemController.clear();
      });
    }
  }

  void _onSaveChangesResult() {
    if (!mounted) return;

    final state = widget.viewModel.saveChanges;

    if (state.completed) {
      final result = state.result;
      state.clearResult();

      if (result == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.show(
              context: context,
              content: const Text("An unexpected error occurred while saving."),
              type: "error",
            ),
          );
        }
        return;
      }

      switch (result) {
        case Ok<void>():
          if (context.mounted) {
            context.pop(result);
          }
          return;
        case Error():
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppSnackBar.show(
                context: context,
                content: Text(
                  "Error while updating your profile: ${result.error}",
                ),
                type: "error",
              ),
            );
          }
          return;
      }
    }
  }
}

extension StringNullIfEmptyExtension on String {
  String? get nullIfEmpty => trim().isEmpty ? null : this;
}
