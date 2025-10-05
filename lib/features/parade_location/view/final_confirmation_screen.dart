import 'dart:convert'; // Add this import
import 'dart:io'; // Add this import

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Add this import
import 'package:google_generative_ai/google_generative_ai.dart'; // Add this import
import 'package:myparadefixed/core/constants/strings.dart';
// NEW: Import the initial screen
import 'package:myparadefixed/features/parade_location/view/parade_location_screen.dart'; // Adjust path if needed
import 'package:open_file/open_file.dart'; // Optional: to open the file after download
// NEW: Add imports for file handling
import 'package:path_provider/path_provider.dart';

import '../model/weather_model.dart'; // Add this import

class FinalConfirmationScreen extends StatefulWidget {
  final String locationAddress;
  final DateTime selectedDateTime;
  final DateTime endTime;
  final WeatherData weatherData; // Change from dynamic to WeatherData
  final List<String> selectedActivities;

  const FinalConfirmationScreen({
    super.key,
    required this.locationAddress,
    required this.selectedDateTime,
    required this.endTime,
    required this.weatherData,
    required this.selectedActivities,
  });

  @override
  State<FinalConfirmationScreen> createState() =>
      _FinalConfirmationScreenState();
}

class _FinalConfirmationScreenState extends State<FinalConfirmationScreen> {
  // NEW: State variables for AI-generated content
  String _funFacts = '';
  String _suggestions = '';
  String _dosAndDonts = '';
  String _daySummary = ''; // NEW: State for the day summary
  bool _isAiLoading = true; // Initially loading
  String _aiError = '';

  @override
  void initState() {
    super.initState();
    // NEW: Fetch AI content when the widget initializes
    _fetchAiContent();
  }

  // NEW: Function to call the Gemini model for all content
  Future<void> _fetchAiContent() async {
    const String apiKey =
        'AIzaSyB_Ta24QQ3E8wFpJNG605WhbdYD-8I6aR4'; // TODO: Securely manage this key
    final model = GenerativeModel(
      model: 'gemini-2.5-flash', // Or another suitable model
      apiKey: apiKey,
    );

    // Prepare weather details string
    String weatherDetails =
        'Temperature: ${widget.weatherData.temperature}°C, '
        'Precipitation: ${widget.weatherData.precipitation}mm/h, '
        'Wind: ${widget.weatherData.windSpeed}m/s, '
        'Condition: ${widget.weatherData.condition}';

    // Prepare selected activities string
    String activitiesString = widget.selectedActivities.join(', ');

    final prompt =
        '''
      You are a helpful assistant for planning vacation and outdoor events.
      Provide a concise, interesting, and relevant summary and other information based on the following details.
      Format the response clearly with distinct sections for Day Summary, Fun Facts, Suggestions, and Do's & Don'ts.
      Use markdown formatting where appropriate (e.g., **bold** for emphasis, *italic* for details, - for bullet points, # for headers if needed).

      Location: ${widget.locationAddress}
      Date: ${widget.selectedDateTime.toLocal().toString().split(' ')[0]}
      Time: ${widget.selectedDateTime.hour}:${widget.selectedDateTime.minute.toString().padLeft(2, '0')} - ${widget.endTime.hour}:${widget.endTime.minute.toString().padLeft(2, '0')}
      Weather: $weatherDetails
      Selected Activities: $activitiesString

      1. Day Summary (a short, engaging paragraph summarizing the event, mentioning the weather, and setting the scene):
         - Write one paragraph that captures the essence of the day.
         - Mention the weather and how it might affect the event positively or what to expect.
         - Briefly hint at the types of activities planned.
         - Keep it positive and exciting.
         - Use markdown for emphasis if needed.

      2. Fun Facts (about the location, historical events on this date, notable people born on this date, interesting weather patterns for this day/month historically):
         - Provide 3-5 interesting points. Keep them brief and engaging.
         - Format as bullet points using markdown: - Fact 1

      3. Suggestions (nice-to-have items/products/equipment for the event based on location, weather, and activities):
         - Provide 3-5 suggestions. Be specific if possible (e.g., "Portable heaters for cold weather", "Umbrellas for rain", "Pop-up tents for shade").
         - Format as bullet points using markdown: - Suggestion 1

      4. Do's & Don'ts (based on weather, location, and activities):
         - Provide 3-5 Do's and 3-5 Don'ts. Keep them short and actionable.
         - Example Do: "Do bring sunscreen if sunny."
         - Example Don't: "Don't forget to check permits for street events."
         - Format as bullet points using markdown: - **Do:** Do 1
         - Format as bullet points using markdown: - **Don't:** Don't 1

      Return the information in a structured text format, clearly separating the sections.
      Use markers like "DAY_SUMMARY:", "FUN_FACTS:", "SUGGESTIONS:", "DOS:", "DONTS:" to separate the content for easy parsing.
    ''';

    try {
      final content = Content.text(prompt);
      final response = await model.generateContent([content]);
      String text = response.text ?? 'No content generated.';

      // --- NEW: LOG THE RAW RESPONSE FOR DEBUGGING ---
      print('Raw AI Content Response Text: $text');

      if (text.trim().isEmpty) {
        setState(() {
          _aiError = 'AI returned empty content.';
          _isAiLoading = false;
        });
        return;
      }

      // --- NEW: Parse the response based on markers ---
      String parseSection(String marker, String fullText) {
        int startIndex = fullText.indexOf(marker);
        if (startIndex == -1) return '';
        startIndex += marker.length;
        int endIndex = fullText.indexOf(
          '\n\n',
          startIndex,
        ); // Find next double newline
        if (endIndex == -1)
          endIndex = fullText.length; // If no double newline, take to end
        return fullText.substring(startIndex, endIndex).trim();
      }

      String daySummaryRaw = parseSection(
        'DAY_SUMMARY:',
        text,
      ); // NEW: Parse day summary
      String funFactsRaw = parseSection('FUN_FACTS:', text);
      String suggestionsRaw = parseSection('SUGGESTIONS:', text);
      String dosDontsRaw = parseSection('DOS:', text);
      String dontsRaw = parseSection('DONTS:', text);

      // Combine Do's and Don'ts into a single string for the card, using markdown
      String dosAndDontsFormatted = '';
      if (dosDontsRaw.isNotEmpty) {
        dosAndDontsFormatted += '**Do\'s:**\n$dosDontsRaw\n\n';
      }
      if (dontsRaw.isNotEmpty) {
        dosAndDontsFormatted += '**Don\'ts:**\n$dontsRaw';
      }
      dosAndDontsFormatted = dosAndDontsFormatted.trim();

      setState(() {
        _daySummary = daySummaryRaw; // NEW: Set the day summary state
        _funFacts = funFactsRaw;
        _suggestions = suggestionsRaw;
        _dosAndDonts = dosAndDontsFormatted;
        _isAiLoading = false;
        if (_daySummary.isEmpty &&
            _funFacts.isEmpty &&
            _suggestions.isEmpty &&
            _dosAndDonts.isEmpty) {
          _aiError = 'AI did not generate any content.';
        }
      });
    } catch (e, stackTrace) {
      print('Error calling Gemini for content: $e');
      print('Stack Trace: $stackTrace'); // Print stack trace for more context
      setState(() {
        _aiError = 'Error generating content: $e';
        _isAiLoading = false;
      });
    }
  }

  // NEW: Function to save parade plan as JSON
  Future<void> _saveParadePlanAsJson() async {
    try {
      // Create a map containing all the data to be saved
      Map<String, dynamic> paradePlanData = {
        'locationAddress': widget.locationAddress,
        'selectedDateTime': widget.selectedDateTime
            .toIso8601String(), // Convert DateTime to string
        'endTime': widget.endTime
            .toIso8601String(), // Convert DateTime to string
        'weatherData': {
          'temperature': widget.weatherData.temperature,
          'precipitation': widget.weatherData.precipitation,
          'windSpeed': widget.weatherData.windSpeed,
          'humidity': widget.weatherData.humidity,
          'condition': widget.weatherData.condition,
          'dateTime': widget.weatherData.dateTime
              .toIso8601String(), // Convert DateTime to string
        },
        'selectedActivities': widget.selectedActivities,
        // NEW: Include AI-generated content
        'daySummary': _daySummary,
        'funFacts': _funFacts,
        'suggestions': _suggestions,
        'dosAndDonts': _dosAndDonts,
      };

      // Convert the map to a JSON string
      String jsonString = jsonEncode(paradePlanData);

      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      String fileName =
          'parade_plan_${DateTime.now().millisecondsSinceEpoch}.json'; // Unique filename
      String filePath = '${directory.path}/$fileName';

      // Write the JSON string to a file
      File file = File(filePath);
      await file.writeAsString(jsonString);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vacation plan saved as $fileName'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFile.open(
              filePath,
            ), // NEW: Optional: Open the file after saving
          ),
        ),
      );

      print('Vaction plan saved to: $filePath'); // Log the file path
    } catch (e) {
      print('Error saving vacation plan: $e');
      // Show an error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving parade plan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Define gradient colors
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      // NEW: Replace AppBar with custom leading widget
      // appBar: AppBar(title: Text(AppStrings.appName), centerTitle: true),
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
        // NEW: Replace back button with '+' button
        leading: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            // Navigate back to the start of the flow (ParadeLocationScreen)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ParadeLocationScreen(), // Navigate to the initial screen
              ),
              (Route<dynamic> route) =>
                  false, // This removes all previous routes
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        // Make the entire content scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Your Vacation Plan',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: primaryColor, // NEW: Use primary color
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // NEW: Day Summary Card (appears first) - NEW: Use Card widget with gradient border
            if (!_isAiLoading && _daySummary.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[50]!,
                        Colors.lightBlue[50]!,
                      ], // NEW: Light blue gradient
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day Summary',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors
                                .blue[800], // Use a distinct color for summary
                          ),
                        ),
                        const SizedBox(height: 8),
                        // NEW: Use Markdown widget for the summary
                        MarkdownBody(
                          data: _daySummary, // <-- Add 'data:' here
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // NEW: Show loading indicator for the summary card if other content is loading
            if (_isAiLoading)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[50]!,
                        Colors.lightBlue[50]!,
                      ], // NEW: Light blue gradient
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day Summary',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
              ),

            // Location - NEW: Use Card widget with gradient border
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.1),
                      Colors.grey[100]!,
                    ], // NEW: Gradient
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryColor, // NEW: Use primary color
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.locationAddress,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time - NEW: Use Card widget with gradient border
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.1),
                      Colors.grey[100]!,
                    ], // NEW: Gradient
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryColor, // NEW: Use primary color
                            ),
                      ),
                      const SizedBox(height: 4),
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
              ),
            ),
            const SizedBox(height: 16),

            // Weather Summary - NEW: Use Card widget with gradient border
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.1),
                      Colors.grey[100]!,
                    ], // NEW: Gradient
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weather:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryColor, // NEW: Use primary color
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Temperature: ${widget.weatherData.temperature}°C',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'Precipitation: ${widget.weatherData.precipitation} mm/h',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'Wind: ${widget.weatherData.windSpeed} m/s',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selected Activities - NEW: Use Card widget with gradient border
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.1),
                      Colors.grey[100]!,
                    ], // NEW: Gradient
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Activities:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryColor, // NEW: Use primary color
                            ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.selectedActivities.map((activity) {
                          return Chip(
                            label: Text(activity),
                            backgroundColor: Colors.red[200],
                            // Optional: Disable deletion in final screen
                            // onDeleted: () {
                            //   // In a real app, you might want to handle deletion from the final screen
                            // },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // NEW: Loading indicator for other AI content (Fun Facts, Suggestions, Do's & Don'ts)
            if (_isAiLoading &&
                (_funFacts.isEmpty ||
                    _suggestions.isEmpty ||
                    _dosAndDonts.isEmpty))
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_aiError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'AI Content Error: $_aiError',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // NEW: Fun Facts Card - NEW: Use Card widget with gradient border
            if (!_isAiLoading && _funFacts.isNotEmpty)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange[50]!,
                        Colors.amber[50]!,
                      ], // NEW: Orange/Amber gradient
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fun Facts',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                        ),
                        const SizedBox(height: 8),
                        // NEW: Use Markdown widget for fun facts
                        MarkdownBody(
                          data: _funFacts, // <-- Add 'data:' here
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context).textTheme.bodyLarge,
                            listBullet: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors
                                      .orange[800], // Color for bullet points
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // NEW: Suggestions Card - NEW: Use Card widget with gradient border
            if (!_isAiLoading && _suggestions.isNotEmpty)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green[50]!,
                        Colors.lightGreen[50]!,
                      ], // NEW: Green/Light Green gradient
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggestions',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                        ),
                        const SizedBox(height: 8),
                        // NEW: Use Markdown widget for suggestions
                        MarkdownBody(
                          data: _suggestions, // <-- Add 'data:' here
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context).textTheme.bodyLarge,
                            listBullet: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors
                                      .green[800], // Color for bullet points
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // NEW: Do's & Don'ts Card - NEW: Use Card widget with gradient border
            if (!_isAiLoading && _dosAndDonts.isNotEmpty)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red[50]!,
                        Colors.pink[50]!,
                      ], // NEW: Red/Pink gradient
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Do\'s & Don\'ts',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                        ),
                        const SizedBox(height: 8),
                        // NEW: Use Markdown widget for Do's & Don'ts
                        MarkdownBody(
                          data: _dosAndDonts, // <-- Add 'data:' here
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context).textTheme.bodyLarge,
                            listBullet: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors
                                      .red[800], // Color for bullet points
                                ),
                            strong: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight
                                      .bold, // Style for **Do:** and **Don't:**
                                  color: Colors.red[800],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // NEW: Show message if no AI content was generated (after loading)
            if (!_isAiLoading &&
                _aiError.isEmpty &&
                _daySummary.isEmpty &&
                _funFacts.isEmpty &&
                _suggestions.isEmpty &&
                _dosAndDonts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No additional information generated by AI.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 20), // Space before final button
            // Final Button - UPDATED ONPRESSED - NEW: Add gradient
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
                onPressed: _saveParadePlanAsJson, // Call the new function
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Vacation Plan',
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
}
