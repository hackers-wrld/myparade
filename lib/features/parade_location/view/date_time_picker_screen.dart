import 'package:flutter/material.dart';
import 'package:myparadefixed/core/constants/strings.dart';

class DateTimePickerScreen extends StatefulWidget {
  final String locationAddress;

  const DateTimePickerScreen({super.key, required this.locationAddress});

  @override
  State<DateTimePickerScreen> createState() => _DateTimePickerScreenState();
}

class _DateTimePickerScreenState extends State<DateTimePickerScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isDateSelected = false;
  bool _isTimeSelected = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current date and time
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.appName), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header text
            Text(
              'Hi, when do you plan to have your parade at: ${widget.locationAddress}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Date Picker (Green area)
            Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[300]!, width: 2),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Select Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[300],
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

            // Time Picker (Blue areas)
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[300]!, width: 2),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Hour',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _selectTime(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[300],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            _selectedTime != null
                                ? _selectedTime!.hour.toString().padLeft(2, '0')
                                : 'Pick hour',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[300]!, width: 2),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Minute',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _selectTime(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[300],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            _selectedTime != null
                                ? _selectedTime!.minute.toString().padLeft(
                                    2,
                                    '0',
                                  )
                                : 'Pick minute',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isDateSelected && _isTimeSelected
                    ? () => _navigateToWeatherScreen(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _isTimeSelected = true;
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
            _selectedTime!.hour,
            _selectedTime!.minute,
          ),
        ),
      ),
    );
  }
}

// Weather Forecast Screen (placeholder for next step)
class WeatherForecastScreen extends StatelessWidget {
  final String locationAddress;
  final DateTime selectedDateTime;

  const WeatherForecastScreen({
    super.key,
    required this.locationAddress,
    required this.selectedDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.appName), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Weather forecast for $locationAddress',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Date: ${selectedDateTime.toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Time: ${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Location Selection'),
            ),
          ],
        ),
      ),
    );
  }
}
