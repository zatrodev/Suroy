import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/data/services/geoapify/geoapify_service.dart';
import 'package:app/ui/core/ui/app_snackbar.dart';
import 'package:app/ui/core/ui/text_field_with_label.dart';
import 'package:app/ui/home/plans/add/widgets/map_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:uuid/uuid.dart';

class AddTravelPlanScreen extends StatefulWidget {
  // When you create your ViewModel, you'll pass it here:
  // final AddTravelPlanViewModel viewModel;

  const AddTravelPlanScreen({
    super.key,
    // required this.viewModel,
  });

  @override
  State<AddTravelPlanScreen> createState() => _AddTravelPlanScreenState();
}

class _AddTravelPlanScreenState extends State<AddTravelPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _notesController = TextEditingController();

  final _locationTextController = TextEditingController(); // For TypeAhead
  final GeoapifyService _geoapifyService = GeoapifyService();
  LocationData? _selectedLocation; // This will hold the final chosen location;

  DateTimeRange? _selectedDateRange;

  bool _isLoading = false;
  final Uuid _uuid = const Uuid();

  List<bool> _areOptionalSectionsExpanded = [
    false,
    false,
    false,
  ]; // Flight, Accommodation, Checklist

  // --- Flight Details State ---
  FlightDetails? _flightDetails;
  final _flightAirlineController = TextEditingController();
  final _flightNumberController = TextEditingController();
  final _flightDepartureAirportController = TextEditingController();
  final _flightArrivalAirportController = TextEditingController();
  final _flightBookingRefController = TextEditingController();
  DateTime? _flightDepartureDateTime;
  DateTime? _flightArrivalDateTime;

  // --- Accommodation Details State ---
  Accommodation? _accommodation;
  final _accNameController = TextEditingController();
  final _accAddressController = TextEditingController();
  final _accBookingRefController = TextEditingController();
  DateTime? _accCheckInDate;
  DateTime? _accCheckOutDate;

  // --- Checklist State ---
  List<ChecklistItem> _checklistItems = [];
  final _newChecklistItemController = TextEditingController();

  // In a real app, this would come from your authentication service
  final String _currentUserId = "dummy_user_id_123";

  @override
  void dispose() {
    _nameController.dispose();
    _locationNameController.dispose();
    _notesController.dispose();
    // Flight Details
    _flightAirlineController.dispose();
    _flightNumberController.dispose();
    _flightDepartureAirportController.dispose();
    _flightArrivalAirportController.dispose();
    _flightBookingRefController.dispose();

    // Accommodation
    _accNameController.dispose();
    _accAddressController.dispose();
    _accBookingRefController.dispose();

    // Checklist
    _newChecklistItemController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = now; // Users can't pick past dates for a new trip range
    final lastDate = now.add(
      const Duration(days: 365 * 5),
    ); // e.g., 5 years into the future

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Trip Dates',
      saveText: 'Done',
    );

    if (pickedDateRange != null) {
      setState(() {
        _selectedDateRange = pickedDateRange;
      });
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
      firstDate:
          firstDate ??
          now.subtract(
            const Duration(days: 30),
          ), // Allow picking slightly in past
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

    if (time == null) return date; // User might only pick date

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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

  Future<void> _saveTravelPlan() async {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.show(
          context: context,
          content: Text('Please select a date range.'),
          type: "error",
        ),
      );
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.show(
          context: context,
          content: Text('Please enter and confirm the main destination.'),
          type: "error",
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();

    final newPlan = TravelPlan(
      name: _nameController.text.trim(),
      startDate: _selectedDateRange!.start,
      endDate: _selectedDateRange!.end,
      location: _selectedLocation!,
      ownerId: _currentUserId, // Replace with actual authenticated user ID
      sharedWith: [], // Initialize as empty
      notes:
          _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
      // Optional fields initialized to null or default
      flightDetails: null,
      accommodation: null,
      checklist:
          [], // Initialize as empty list or null based on your model's preference
      itinerary: {}, // Initialize as empty map or null
      createdAt: now,
      updatedAt: now,
    );

    // In your final version, this will be:
    // final result = await widget.viewModel.addTravelPlan(newPlan);
    // final result = await widget.travelPlanRepository.addTravelPlan(newPlan);
    //
    // if (!mounted) return;
    //
    // setState(() {
    //   _isLoading = false;
    // });
    //
    // if (result.isSuccess) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Travel plan added successfully!'),
    //       backgroundColor: Colors.green,
    //     ),
    //   );
    //   Navigator.of(context).pop(true); // Pop and indicate success
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(
    //         'Failed to add travel plan: ${result.error.toString()}',
    //       ),
    //       backgroundColor: Theme.of(context).colorScheme.error,
    //     ),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Travel Plan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveTravelPlan,
              tooltip: 'Save Plan',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFieldWithLabel(
                controller: _nameController,
                label: 'Plan Name*',
                textFieldLabel: 'e.g., Trip to Paris',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a plan name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date
              _buildDateRangeSelector(
                context: context,
                label: 'Trip Dates*',
                selectedDateRange: _selectedDateRange,
                onTap: () => _pickDateRange(context),
                validator:
                    () =>
                        _selectedDateRange == null
                            ? 'Please select trip dates.'
                            : null,
              ),
              const SizedBox(height: 20),

              // Location Name
              TypeAheadField<GeoapifySuggestion>(
                controller: _locationTextController,
                builder: (context, controller, focusNode) {
                  return TextFieldWithLabel(
                    label: "Main Destination",
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
                        _formKey.currentState?.validate(); // Re-validate
                      }
                    },
                  );
                },
                suggestionsCallback: (pattern) async {
                  if (pattern.length < 3) {
                    return []; // Don't search for very short patterns
                  }

                  return await _geoapifyService.fetchAutocompleteSuggestions(
                    pattern,
                  );
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
                  _locationTextController.text =
                      suggestion.displayText; // Or suggestion.name
                  setState(() {
                    _selectedLocation = suggestion.toLocationData();
                  });
                  _formKey.currentState
                      ?.validate(); // Re-validate after selection
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
                    'Selected: ${_selectedLocation!.name} (Lat: ${_selectedLocation!.latitude.toStringAsFixed(2)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(2)})',
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
              const SizedBox(height: 20),

              // Notes
              TextFieldWithLabel(
                controller: _notesController,
                label: 'Notes (Optional)',
                textFieldLabel:
                    'e.g., Visa requirements, packing list items...',
              ),
              const SizedBox(height: 24),

              ExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _areOptionalSectionsExpanded[index] = isExpanded;
                  });
                },
                animationDuration: const Duration(milliseconds: 300),
                elevation: 1, // Optional: style as you like
                dividerColor: Colors.grey.shade300, // Optional
                children: [
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
                    isExpanded: _areOptionalSectionsExpanded[0],
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
                    isExpanded: _areOptionalSectionsExpanded[1],
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
                    isExpanded: _areOptionalSectionsExpanded[2],
                    canTapOnHeader: true,
                  ),
                ],
              ),
              // --- END OPTIONAL SECTIONS ---
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save_alt_outlined),
                label: Text(_isLoading ? 'Saving...' : 'Create Travel Plan'),
                onPressed: _isLoading ? null : _saveTravelPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for date selectors
  Widget _buildDateRangeSelector({
    required BuildContext context,
    required String label,
    DateTimeRange? selectedDateRange,
    required VoidCallback onTap,
    required String? Function() validator,
  }) {
    return FormField<DateTimeRange>(
      initialValue: selectedDateRange,
      validator: (value) => validator(),
      builder: (FormFieldState<DateTimeRange> field) {
        String displayText;
        if (selectedDateRange == null) {
          displayText = 'Select Dates';
        } else {
          final startDateFormatted = DateFormat.yMMMd().format(
            selectedDateRange.start,
          );
          final endDateFormatted = DateFormat.yMMMd().format(
            selectedDateRange.end,
          );
          displayText = '$startDateFormatted - $endDateFormatted';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        field.hasError
                            ? Theme.of(context).colorScheme.error
                            : Colors.grey.shade400,
                    width: field.hasError ? 1.5 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      // Added Expanded to prevent overflow if date range string is long
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              selectedDateRange == null
                                  ? Theme.of(context).hintColor
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Handle long date strings
                      ),
                    ),
                    Icon(
                      Icons.calendar_month_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
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
        );
      },
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
                    if (dt != null)
                      setState(() => _flightDepartureDateTime = dt);
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
                  firstDate:
                      _accCheckInDate, // Ensure checkout is not before checkin
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
}
