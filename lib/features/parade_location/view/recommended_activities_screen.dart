import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Add this import
import 'package:myparadefixed/core/constants/strings.dart';

import '../model/weather_model.dart'; // Ensure WeatherData import
import 'final_confirmation_screen.dart';

class RecommendedActivitiesScreen extends StatefulWidget {
  final String locationAddress;
  final DateTime selectedDateTime;
  final DateTime endTime;
  final WeatherData weatherData; // Change from dynamic to WeatherData
  final List<String>
  initialRecommendations; // NEW: Accept recommendations from AI
  final String aiError; // NEW: Accept AI error message

  const RecommendedActivitiesScreen({
    super.key,
    required this.locationAddress,
    required this.selectedDateTime,
    required this.endTime,
    required this.weatherData,
    required this.initialRecommendations,
    required this.aiError, // NEW: Add aiError to constructor
  });

  @override
  State<RecommendedActivitiesScreen> createState() =>
      _RecommendedActivitiesScreenState();
}

class _RecommendedActivitiesScreenState
    extends State<RecommendedActivitiesScreen> {
  // NEW: Use the initialRecommendations passed from WeatherForecastScreen
  late List<String> predefinedActivities;
  Set<String> selectedActivities = {};

  // NEW: State for AI suggestions triggered by custom activity
  List<String> _aiSuggestedActivities = [];
  bool _isAiSuggesting = false;
  String _aiSuggestionError = '';

  @override
  void initState() {
    super.initState();
    // NEW: Initialize with AI-generated recommendations
    predefinedActivities = List.from(widget.initialRecommendations);
    // Optional: Add a fallback if AI returned nothing or had an error
    if (predefinedActivities.isEmpty && widget.aiError.isNotEmpty) {
      predefinedActivities = [
        'No recommendations available',
        'Check internet connection',
      ];
    }
  }

  // NEW: Function to call the Gemini model for related activities
  Future<List<String>> _getRelatedActivitiesFromAI(
    String customActivity,
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
      You are a helpful assistant for planning vacations, and outdoor events.
      A user has added a custom activity: "$customActivity".
      Based on this custom activity, the following event details, and the existing activities, suggest 3 activities that would complement or be related to the custom activity.
      Consider the weather, time of day, and the type of location.
      Return ONLY the 3 related activities as a simple list, one activity per line. Do not include any introductory text, explanations, or conclusions.
      Format each line strictly as: "<number>. <activity name>"

      Location: $location
      Date: $date
      Time: $time
      Weather: $weather
    ''';

    try {
      final content = Content.text(prompt);
      final response = await model.generateContent([content]);
      // --- NEW: LOG THE RAW RESPONSE FOR DEBUGGING ---
      print('Raw AI Suggestion Response Text: ${response.text}');
      // print('Raw AI Suggestion Response Parts: ${response.parts}');

      String text = response.text ?? 'No related activities generated.';
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
      // Limit to 3 recommendations if more were generated
      if (recommendations.length > 3) {
        recommendations = recommendations.take(3).toList();
      }
      return recommendations;
    } catch (e, stackTrace) {
      print('Error calling Gemini for suggestions: $e');
      print('Stack Trace: $stackTrace'); // Print stack trace for more context
      return []; // Return an empty list on error
    }
  }

  // NEW: Function to handle adding a custom activity and getting AI suggestions
  Future<void> _addCustomActivity(String customActivity) async {
    // Add the custom activity immediately to the selected list
    setState(() {
      selectedActivities.add(customActivity);
    });

    // Now, get AI suggestions based on the custom activity
    setState(() {
      _isAiSuggesting = true;
      _aiSuggestionError = '';
    });

    // Prepare weather details string
    String weatherDetails =
        'Temperature: ${widget.weatherData.temperature}°C, '
        'Precipitation: ${widget.weatherData.precipitation}mm/h, '
        'Wind: ${widget.weatherData.windSpeed}m/s, '
        'Condition: ${widget.weatherData.condition}';

    List<String> aiSuggestions = await _getRelatedActivitiesFromAI(
      customActivity,
      widget.locationAddress,
      '${widget.selectedDateTime.toLocal().toString().split(' ')[0]}', // Date
      '${widget.selectedDateTime.hour}:${widget.selectedDateTime.minute.toString().padLeft(2, '0')} - ${widget.endTime.hour}:${widget.endTime.minute.toString().padLeft(2, '0')}', // Time Range
      weatherDetails,
    );

    setState(() {
      _aiSuggestedActivities = aiSuggestions;
      _isAiSuggesting = false;
      if (_aiSuggestedActivities.isEmpty) {
        _aiSuggestionError = 'AI did not generate any related suggestions.';
      }
    });

    // Add AI suggestions to the predefined list and selected list
    if (aiSuggestions.isNotEmpty) {
      setState(() {
        for (String suggestion in aiSuggestions) {
          if (!predefinedActivities.contains(suggestion) &&
              !selectedActivities.contains(suggestion)) {
            predefinedActivities.add(suggestion);
            // Optionally, select the AI suggestions by default
            // selectedActivities.add(suggestion);
          }
        }
      });
    }
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FinalConfirmationScreen(
                    locationAddress: widget.locationAddress,
                    selectedDateTime: widget.selectedDateTime,
                    endTime: widget.endTime,
                    weatherData: widget.weatherData, // Pass WeatherData object
                    selectedActivities: selectedActivities.toList(),
                  ),
                ),
              );
            },
            child: const Text('Next', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Recommended Activities for Your Vacation',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: primaryColor, // NEW: Use primary color
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to select. Press and hold to deselect.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            // NEW: Show AI error if it occurred during initial load
            if (widget.aiError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${widget.aiError}',
                style: const TextStyle(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            // NEW: Show AI suggestion error or loading state
            if (_isAiSuggesting)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('AI is suggesting related activities...'),
                  ],
                ),
              )
            else if (_aiSuggestionError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'AI Suggestion Error: $_aiSuggestionError',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
            else if (_aiSuggestedActivities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'AI Suggested: ${_aiSuggestedActivities.join(', ')}',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // NEW: Add gradient to custom activity button
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red[400]!,
                        Colors.pink[400]!,
                      ], // NEW: Use red/pink gradient
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddCustomActivityDialog(context),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add Custom Activity',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount:
                    predefinedActivities.length +
                    selectedActivities
                        .where(
                          (activity) =>
                              !predefinedActivities.contains(activity),
                        )
                        .length,
                itemBuilder: (context, index) {
                  if (index < predefinedActivities.length) {
                    final activity = predefinedActivities[index];
                    final isSelected = selectedActivities.contains(activity);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedActivities.remove(activity);
                          } else {
                            selectedActivities.add(activity);
                          }
                        });
                      },
                      onLongPress: () {
                        setState(() {
                          selectedActivities.remove(activity);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red[400] : Colors.red[200],
                          borderRadius: BorderRadius.circular(30),
                          border: isSelected
                              ? Border.all(color: Colors.red, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            activity,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                    );
                  } else {
                    final customActivities = selectedActivities
                        .where(
                          (activity) =>
                              !predefinedActivities.contains(activity),
                        )
                        .toList();
                    final customActivity =
                        customActivities[index - predefinedActivities.length];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedActivities.remove(customActivity);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            customActivity,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedActivities.clear();
                    });
                  },
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[200],
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'YOU',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomActivityDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Custom Activity'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter activity name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty && !selectedActivities.contains(value)) {
                _addCustomActivity(value); // Call the new function
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_controller.text.isNotEmpty &&
                    !selectedActivities.contains(_controller.text) &&
                    !_controller.text.contains(RegExp(r'^\d+\.\s*'))) {
                  // Avoid adding items that look like AI numbered lists accidentally
                  _addCustomActivity(_controller.text); // Call the new function
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
