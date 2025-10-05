import 'package:flutter/material.dart';
import 'package:myparadefixed/core/constants/strings.dart';
import 'package:myparadefixed/features/parade_location/view/weather_forecast_screen.dart';

class DateTimePickerScreen extends StatefulWidget {
  final String locationAddress;
  const DateTimePickerScreen({super.key, required this.locationAddress});

  @override
  State<DateTimePickerScreen> createState() => _DateTimePickerScreenState();
}

class _DateTimePickerScreenState extends State<DateTimePickerScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isDateSelected = false;
  bool _isStartTimeSelected = false;
  bool _isEndTimeSelected = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current date and time
    _selectedDate = DateTime.now();
    _selectedStartTime = TimeOfDay.fromDateTime(DateTime.now());
    _selectedEndTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Define gradient colors
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appName),
        centerTitle: true,
        // NEW: Add gradient background to app bar
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        // Make the entire content scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header text
            Text(
              'When do you plan to have your vacation at: ${widget.locationAddress}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor, // NEW: Use primary color
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Date Picker (Green area) - NEW: Use primary color
            Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(
                  0.1,
                ), // NEW: Use primary color with opacity
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor,
                  width: 2,
                ), // NEW: Use primary color
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Select Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: primaryColor, // NEW: Use primary color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // NEW: Use primary color
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Pick a date',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Time Pickers (Blue areas) - NEW: Use primary color
            Text(
              'Select Parade Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor, // NEW: Use primary color
              ),
            ),
            const SizedBox(height: 16),
            // Start Time
            Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(
                  0.1,
                ), // NEW: Use primary color with opacity
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor,
                  width: 2,
                ), // NEW: Use primary color
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Start Time',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: primaryColor, // NEW: Use primary color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Start Hour
                      ElevatedButton(
                        onPressed: () => _selectStartTime(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              primaryColor, // NEW: Use primary color
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          _selectedStartTime != null
                              ? _selectedStartTime!.hour.toString().padLeft(
                                  2,
                                  '0',
                                )
                              : 'HH',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Start Minute
                      ElevatedButton(
                        onPressed: () => _selectStartTime(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              primaryColor, // NEW: Use primary color
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          _selectedStartTime != null
                              ? _selectedStartTime!.minute.toString().padLeft(
                                  2,
                                  '0',
                                )
                              : 'MM',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // End Time
            Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(
                  0.1,
                ), // NEW: Use primary color with opacity
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor,
                  width: 2,
                ), // NEW: Use primary color
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'End Time',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: primaryColor, // NEW: Use primary color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // End Hour
                      ElevatedButton(
                        onPressed: () => _selectEndTime(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              primaryColor, // NEW: Use primary color
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          _selectedEndTime != null
                              ? _selectedEndTime!.hour.toString().padLeft(
                                  2,
                                  '0',
                                )
                              : 'HH',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // End Minute
                      ElevatedButton(
                        onPressed: () => _selectEndTime(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              primaryColor, // NEW: Use primary color
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          _selectedEndTime != null
                              ? _selectedEndTime!.minute.toString().padLeft(
                                  2,
                                  '0',
                                )
                              : 'MM',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Continue Button - NEW: Add gradient
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, secondaryColor],
                ),
              ),
              child: ElevatedButton(
                onPressed: () => _navigateToWeatherScreen(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Add some space at the bottom
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isDateSelected = true;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedStartTime) {
      setState(() {
        _selectedStartTime = picked;
        _isStartTimeSelected = true;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
        _isEndTimeSelected = true;
      });
    }
  }

  void _navigateToWeatherScreen(BuildContext context) {
    // Navigate to weather screen with selected date and time
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeatherForecastScreen(
          locationAddress: widget.locationAddress,
          selectedDateTime: DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedStartTime!.hour,
            _selectedStartTime!.minute,
          ),
          endTime: DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedEndTime!.hour,
            _selectedEndTime!.minute,
          ),
        ),
      ),
    );
  }
}
