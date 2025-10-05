import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Add this import
import 'package:myparadefixed/core/constants/strings.dart';
import 'package:myparadefixed/features/parade_location/view/recommended_activities_screen.dart';
import 'package:provider/provider.dart';

import '../controller/weather_controller.dart';
import '../model/weather_model.dart';

class WeatherForecastScreen extends StatefulWidget {
  final String locationAddress;
  final DateTime selectedDateTime;
  final DateTime endTime;

  const WeatherForecastScreen({
    super.key,
    required this.locationAddress,
    required this.selectedDateTime,
    required this.endTime,
  });

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  // NEW: Add state for AI-generated recommendations
  List<String> _aiRecommendations = [];
  bool _isAiLoading = false;
  String _aiError = '';

  // NEW: Add state for historical weather data
  WeatherData? _historicalWeatherData;
  bool _isLoadingHistorical = false;
  String _historicalErrorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Determine if we need historical averages or actual data
      final now = DateTime.now();
      if (widget.selectedDateTime.isAfter(now)) {
        // Future date: Fetch historical averages
        _fetchHistoricalAverages();
      } else {
        // Past date: Fetch actual data for that specific date
        final controller = Provider.of<WeatherController>(
          context,
          listen: false,
        );
        // For demo purposes, use New York coordinates
        controller.fetchWeather(40.7128, -74.0060, widget.selectedDateTime);
      }
    });
  }

  // NEW: Function to fetch historical averages from NASA POWER API
  Future<void> _fetchHistoricalAverages() async {
    setState(() {
      _isLoadingHistorical = true;
      _historicalErrorMessage = '';
    });

    final controller = Provider.of<WeatherController>(context, listen: false);
    final targetDate = widget.selectedDateTime; // The date the user selected
    final now = DateTime.now();

    // Calculate the 5-year historical window
    final int currentYear = now.year;
    final int startYear = currentYear - 5;

    // Prepare a list to hold data from each year for averaging
    List<WeatherData> yearlyData = [];

    // Loop through the 5 years to fetch data for the target day
    for (int year = startYear; year < currentYear; year++) {
      // Create a date object for the target day in the specific year
      DateTime historicalDate = DateTime(
        year,
        targetDate.month,
        targetDate.day,
      );

      // Check if the historical date is before today to avoid fetching future data in the past window
      if (historicalDate.isBefore(now)) {
        try {
          // Call the existing fetchWeather method to get data for this historical date.
          // This will make an API call to NASA POWER for the specific date.
          // We assume the fetchWeather method returns hourly data which we can then average.
          // In reality, you might need to modify the WeatherController to handle daily averages or multiple hourly fetches and average them.
          // Let's create a new method in WeatherController called `fetchDailyWeather` that fetches all hourly data for a day.

          // Since our current `fetchWeather` only returns one hour's data (the first hour of the day),
          // we will need to modify it to fetch all hours for the day and return them.
          // For now, we'll simulate getting the full day's data by making multiple calls or modifying the API request.
          // You would need to implement this logic in your WeatherController.
          // For demonstration, we'll simulate fetching hourly data for the day.

          // Placeholder: Simulate fetching data for one historical day
          // In a real app, you would replace this with a call to a modified `fetchDailyWeather` function.
          // This is a simplification - a real implementation would require calling the API for the whole day.

          // For now, let's call the existing fetchWeather method for the historical date.
          // It will return the first hour's data.
          // We will later modify the WeatherController to fetch all hourly data.
          await controller.fetchWeather(40.7128, -74.0060, historicalDate);

          // Wait for the data to be loaded
          await Future.delayed(
            const Duration(milliseconds: 500),
          ); // Small delay to ensure data is loaded

          if (controller.weatherData != null) {
            yearlyData.add(controller.weatherData!);
          }
        } catch (e) {
          print('Error fetching data for year $year: $e');
          // Continue to next year even if one fails
        }
      }
    }

    // Calculate overall averages from the yearly data
    if (yearlyData.isNotEmpty) {
      double totalTemp = 0.0;
      double totalPrecip = 0.0;
      double totalWind = 0.0;
      double totalHumidity = 0.0;

      for (var data in yearlyData) {
        totalTemp += data.temperature;
        totalPrecip += data.precipitation;
        totalWind += data.windSpeed;
        totalHumidity += data.humidity;
      }

      int count = yearlyData.length;
      _historicalWeatherData = WeatherData(
        temperature: totalTemp / count,
        precipitation: totalPrecip / count,
        windSpeed: totalWind / count,
        humidity: totalHumidity / count,
        condition: yearlyData
            .first
            .condition, // Simplification: take condition from first year
        dateTime: targetDate, // Set the date to the user's selected future date
      );
    } else {
      _historicalErrorMessage =
          'No historical data available for the specified date range.';
    }

    setState(() {
      _isLoadingHistorical = false;
    });

    // Trigger AI call after historical data is loaded (or error occurs)
    if (_historicalWeatherData != null || _historicalErrorMessage.isNotEmpty) {
      _onHistoricalDataFetched();
    }
  }

  // NEW: Call AI after historical weather data is fetched
  void _onHistoricalDataFetched() {
    if (_historicalWeatherData != null &&
        !_isAiLoading &&
        _aiRecommendations.isEmpty &&
        _aiError.isEmpty) {
      setState(() {
        _isAiLoading = true;
      });

      // Prepare weather details string using the historical average data
      String weatherDetails =
          'Temperature: ${_historicalWeatherData!.temperature}°C, '
          'Precipitation: ${_historicalWeatherData!.precipitation}mm/h, '
          'Wind: ${_historicalWeatherData!.windSpeed}m/s, '
          'Condition: ${_historicalWeatherData!.condition}';

      _getRecommendationsFromAI(
            widget.locationAddress,
            '${widget.selectedDateTime.toLocal().toString().split(' ')[0]}', // Date
            '${widget.selectedDateTime.hour}:${widget.selectedDateTime.minute.toString().padLeft(2, '0')} - ${widget.endTime.hour}:${widget.endTime.minute.toString().padLeft(2, '0')}', // Time Range
            weatherDetails,
          )
          .then((recommendations) {
            setState(() {
              _aiRecommendations = recommendations;
              _isAiLoading = false;
              if (_aiRecommendations.isEmpty) {
                _aiError =
                    'AI did not generate any recommendations. Please try again.';
              }
            });
          })
          .catchError((error) {
            setState(() {
              _aiError = 'Error generating recommendations: $error';
              _isAiLoading = false;
            });
          });
    }
  }

  // NEW: Function to call the Gemini model using historical data
  Future<List<String>> _getRecommendationsFromAI(
    String location,
    String date,
    String time,
    String weather,
  ) async {
    const String apiKey =
        'AIzaSyB_Ta24QQ3E8wFpJNG605WhbdYD-8I6aR4'; // TODO: Securely manage this key
    final model = GenerativeModel(
      model: 'gemini-2.5-flash', // Or another suitable model
      apiKey: apiKey,
    );

    final prompt =
        '''
      You are a helpful assistant for planning vacations, outdoor and indoor events.
    Based on the following details, suggest 10-15 activities that would be suitable and enjoyable for the user.
    Consider the weather, time of day, and the type of location.
    Find activities near/around the area available during that time
    Note that it must be five to six words maximum, summarise your findings
    Return the activities only (nothing else), one activity per line, note the data is for mobile text displaying, no styling on the text.
    
      Location: $location
      Date: $date
      Time: $time
      Weather (Historical Average): $weather
    ''';

    try {
      final content = Content.text(prompt);
      final response = await model.generateContent([content]);
      // --- NEW: LOG THE RAW RESPONSE FOR DEBUGGING ---
      print('Raw AI Response Text: ${response.text}');
      // print('Raw AI Response Parts: ${response.parts}');

      String text = response.text ?? 'No recommendations generated.';
      if (text.trim().isEmpty) {
        return []; // Return empty list if no text
      }

      // Simple parsing: split by newlines and filter out empty lines or just the number
      List<String> lines = text.split('\n');
      List<String> recommendations = [];
      for (String line in lines) {
        line = line.trim();
        // Remove leading numbers and dots (e.g., "1. ", "2. ")
        line = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (line.isNotEmpty) {
          recommendations.add(line);
        }
      }
      // Limit to 15 recommendations if more were generated
      if (recommendations.length > 15) {
        recommendations = recommendations.take(15).toList();
      }
      return recommendations;
    } catch (e, stackTrace) {
      print('Error calling Gemini: $e');
      print('Stack Trace: $stackTrace'); // Print stack trace for more context
      return []; // Return an empty list on error
    }
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Define gradient colors
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;

    final controller = Provider.of<WeatherController>(context);

    // Determine which data to display based on the selected date
    final now = DateTime.now();
    final isFutureDate = widget.selectedDateTime.isAfter(now);
    final WeatherData? displayWeatherData = isFutureDate
        ? _historicalWeatherData
        : controller.weatherData;
    final bool isLoading = isFutureDate
        ? _isLoadingHistorical
        : controller.isLoading;
    final String errorMessage = isFutureDate
        ? _historicalErrorMessage
        : controller.errorMessage;

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather Forecast for Your Parade',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor, // NEW: Use primary color
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.locationAddress,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8), // Add space for the type indicator
            // NEW: Indicator for Historical Average vs Actual Data
            Text(
              isFutureDate
                  ? '(Based on Historical Averages - Not a Forecast)'
                  : '(Actual Historical Data)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // NEW: Improve card styling
            Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(
                  0.1,
                ), // NEW: Use primary color with opacity
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor,
                  width: 1,
                ), // NEW: Use primary color
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Parade Time',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: primaryColor, // NEW: Use primary color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.selectedDateTime.hour}:${widget.selectedDateTime.minute.toString().padLeft(2, '0')} - ${widget.endTime.hour}:${widget.endTime.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '${widget.selectedDateTime.toLocal().toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Column(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $errorMessage',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else if (displayWeatherData != null)
              Column(
                children: [
                  // NEW: Improve rain/no rain card with better styling
                  Container(
                    decoration: BoxDecoration(
                      color: displayWeatherData.precipitation > 0.1
                          ? Colors.blue[100]?.withOpacity(
                              0.5,
                            ) // NEW: Add opacity
                          : Colors.green[100]?.withOpacity(
                              0.5,
                            ), // NEW: Add opacity
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: displayWeatherData.precipitation > 0.1
                            ? Colors.blue[300]!
                            : Colors.green[300]!,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            displayWeatherData.precipitation > 0.1
                                ? const Icon(
                                    Icons.cloud,
                                    color: Colors.blue,
                                    size: 32,
                                  )
                                : const Icon(
                                    Icons.sunny,
                                    color: Colors.yellow,
                                    size: 32,
                                  ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                displayWeatherData.precipitation > 0.1
                                    ? 'It might rain during your parade (based on historical average)!'
                                    : 'No rain expected (based on historical average)!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          displayWeatherData.precipitation > 0.1
                                          ? Colors.blue[800]
                                          : Colors.green[800],
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Precipitation: ${displayWeatherData.precipitation.toStringAsFixed(2)} mm/h (Avg)',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Weather Conditions (Historical Average)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor, // NEW: Use primary color
                    ),
                  ),
                  const SizedBox(height: 16),
                  // NEW: Improve weather detail cards
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(
                        0.1,
                      ), // NEW: Use primary color with opacity
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor,
                        width: 1,
                      ), // NEW: Use primary color
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.thermostat,
                          color: Colors.blue, // NEW: Use specific color
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Temperature',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors
                                          .blue, // NEW: Use specific color
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${displayWeatherData.temperature.toStringAsFixed(1)}°C (Avg)',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(
                        0.1,
                      ), // NEW: Use primary color with opacity
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor,
                        width: 1,
                      ), // NEW: Use primary color
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wind_power,
                          color: Colors.blue, // NEW: Use specific color
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wind Speed',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors
                                          .blue, // NEW: Use specific color
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${displayWeatherData.windSpeed.toStringAsFixed(1)} m/s (Avg)',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(
                        0.1,
                      ), // NEW: Use primary color with opacity
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor,
                        width: 1,
                      ), // NEW: Use primary color
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.water_drop,
                          color: Colors.blue, // NEW: Use specific color
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Humidity',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors
                                          .blue, // NEW: Use specific color
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${displayWeatherData.humidity.toStringAsFixed(1)}% (Avg)',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Icon(Icons.cloud_off, color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No weather data available for this date.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            // NEW: Display AI loading or error state (for historical data)
            if (_isAiLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_aiError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'AI Recommendation Error: $_aiError',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_aiRecommendations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'AI Generated Recommendations Ready!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              )
            else if (!_isAiLoading &&
                displayWeatherData != null &&
                _aiRecommendations.isEmpty &&
                _aiError.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('Generating activity recommendations...'),
                ),
              ),

            const SizedBox(height: 40),
            // NEW: Improve button layout with gradient
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Change Date'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
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
                      // NEW: Enable Continue button only if historical data is loaded and AI recommendations are loaded (or an error occurred)
                      onPressed:
                          (displayWeatherData != null &&
                              (!_isAiLoading || _aiError.isNotEmpty))
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecommendedActivitiesScreen(
                                    locationAddress: widget.locationAddress,
                                    selectedDateTime: widget.selectedDateTime,
                                    endTime: widget.endTime,
                                    weatherData:
                                        displayWeatherData!, // Pass the displayed WeatherData object
                                    initialRecommendations:
                                        _aiRecommendations, // Pass the AI recommendations
                                    aiError:
                                        _aiError, // Pass any AI error message
                                  ),
                                ),
                              );
                            }
                          : null, // Disable if data is loading or AI is loading without an error
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
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
