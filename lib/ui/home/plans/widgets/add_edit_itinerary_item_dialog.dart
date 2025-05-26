import 'package:app/data/repositories/travel_plan/travel_plan_model.dart';
import 'package:app/data/services/geoapify/geoapify_service.dart';
import 'package:app/ui/core/ui/app_snackbar.dart';
import 'package:app/ui/core/ui/text_field_with_label.dart';
import 'package:app/ui/home/plans/add/widgets/map_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class AddEditItineraryItemDialog extends StatefulWidget {
  final ItineraryItem? initialItem;
  final DateTime dayOfItinerary;

  const AddEditItineraryItemDialog({
    super.key,
    this.initialItem,
    required this.dayOfItinerary,
  });

  @override
  State<AddEditItineraryItemDialog> createState() =>
      _AddEditItineraryItemDialogState();
}

class _AddEditItineraryItemDialogState
    extends State<AddEditItineraryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationTextController = TextEditingController();

  DateTimeRange? _selectedTimeRange;
  LocationData? _selectedLocation;
  String? _selectedType;

  final GeoapifyService _geoapifyService = GeoapifyService();
  final Uuid _uuid = const Uuid();

  final List<Map<String, dynamic>> _itemTypes = [
    {'value': 'activity', 'label': 'Activity', 'icon': Icons.local_activity},
    {'value': 'meal', 'label': 'Meal', 'icon': Icons.restaurant},
    {'value': 'transport', 'label': 'Transport', 'icon': Icons.directions_bus},
    {'value': 'lodging', 'label': 'Lodging', 'icon': Icons.hotel},
    {'value': 'other', 'label': 'Other', 'icon': Icons.edit_note},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      _titleController.text = widget.initialItem!.title;
      _descriptionController.text = widget.initialItem!.description ?? '';
      if (widget.initialItem!.startTime != null &&
          widget.initialItem!.endTime != null) {
        _selectedTimeRange = DateTimeRange(
          start: widget.initialItem!.startTime!,
          end: widget.initialItem!.endTime!,
        );
      } else if (widget.initialItem!.startTime != null) {
        _selectedTimeRange = DateTimeRange(
          start: widget.initialItem!.startTime!,
          end: widget.initialItem!.startTime!.add(const Duration(hours: 1)),
        );
      }
      _selectedLocation = widget.initialItem!.location;
      if (_selectedLocation != null) {
        _locationTextController.text =
            _selectedLocation!.address ?? _selectedLocation!.name;
      }
      _selectedType = widget.initialItem!.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationTextController.dispose();
    super.dispose();
  }

  Future<void> _pickTimeRange() async {
    TimeOfDay? startTimeOfDay =
        _selectedTimeRange != null
            ? TimeOfDay.fromDateTime(_selectedTimeRange!.start)
            : const TimeOfDay(hour: 9, minute: 0);

    final pickedStartTime = await showTimePicker(
      context: context,
      initialTime: startTimeOfDay,
      helpText: 'SELECT START TIME',
    );
    if (pickedStartTime == null || !mounted) return;

    TimeOfDay? endTimeOfDay =
        _selectedTimeRange != null
            ? TimeOfDay.fromDateTime(_selectedTimeRange!.end)
            : TimeOfDay(
              hour: startTimeOfDay.hour + 1,
              minute: startTimeOfDay.minute,
            ); // Default end

    final pickedEndTime = await showTimePicker(
      context: context,
      initialTime: endTimeOfDay,
      helpText: 'SELECT END TIME',
    );
    if (pickedEndTime == null || !mounted) return;

    // Combine with widget.dayOfItinerary
    final startDateTime = DateTime(
      widget.dayOfItinerary.year,
      widget.dayOfItinerary.month,
      widget.dayOfItinerary.day,
      pickedStartTime.hour,
      pickedStartTime.minute,
    );
    final endDateTime = DateTime(
      widget.dayOfItinerary.year,
      widget.dayOfItinerary.month,
      widget.dayOfItinerary.day,
      pickedEndTime.hour,
      pickedEndTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.show(
          context: context,
          content: Text("End time cannot be before start time."),
          type: "error",
        ),
      );
      return;
    }

    setState(() {
      _selectedTimeRange = DateTimeRange(
        start: startDateTime,
        end: endDateTime,
      );
    });
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
                      : null,
            ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _locationTextController.text = result.address ?? result.name;
      });
    }
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newItem = ItineraryItem(
      id: widget.initialItem?.id ?? _uuid.v4(),
      title: _titleController.text.trim(),
      description:
          _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
      startTime: _selectedTimeRange?.start,
      endTime: _selectedTimeRange?.end,
      location: _selectedLocation,
      type: _selectedType,
    );
    Navigator.of(context).pop(newItem);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialItem == null
            ? 'Add Itinerary Item'
            : 'Edit Itinerary Item',
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title*'),
                  validator:
                      (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickTimeRange,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Time Range (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedTimeRange != null
                          ? '${DateFormat.jm().format(_selectedTimeRange!.start)} - ${DateFormat.jm().format(_selectedTimeRange!.end)}'
                          : 'Set time range',
                      style: TextStyle(
                        color:
                            _selectedTimeRange == null
                                ? Theme.of(context).hintColor
                                : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TypeAheadField<GeoapifySuggestion>(
                  controller: _locationTextController,
                  builder: (context, controller, focusNode) {
                    return TextFieldWithLabel(
                      label: "Location (Optional)",
                      textFieldLabel: "Search or pick on map",
                      controller: controller,
                      focusNode: focusNode,
                      suffixIcon:
                          _locationTextController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _locationTextController.clear();
                                  setState(() => _selectedLocation = null);
                                },
                              )
                              : null,
                      onChanged: (value) {
                        if (_selectedLocation != null &&
                            value !=
                                (_selectedLocation!.address ??
                                    _selectedLocation!.name)) {
                          setState(() {
                            _selectedLocation = null;
                          });
                          _formKey.currentState?.validate();
                        }
                      },
                    );
                  },
                  hideOnEmpty: true,
                  suggestionsCallback: (pattern) async {
                    if (pattern.length < 3) {
                      return [];
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
                    _locationTextController.text = suggestion.displayText;
                    setState(
                      () => _selectedLocation = suggestion.toLocationData(),
                    );
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
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Selected: ${_selectedLocation!.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text(
                    'Pick on Map',
                    style: TextStyle(fontSize: 13),
                  ),
                  onPressed: _navigateToMapPicker,
                ),
                const SizedBox(height: 16),

                // Type Radio Buttons
                Text(
                  'Type (Optional)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      _itemTypes.map((typeMap) {
                        return ChoiceChip(
                          label: Text(typeMap['label']),
                          avatar: Icon(
                            typeMap['icon'],
                            size: 16,
                            color:
                                _selectedType == typeMap['value']
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                          ),
                          selected: _selectedType == typeMap['value'],
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedType =
                                  selected ? typeMap['value'] as String : null;
                            });
                          },
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color:
                                _selectedType == typeMap['value']
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : null,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveItem, child: const Text('Save Item')),
      ],
    );
  }
}
