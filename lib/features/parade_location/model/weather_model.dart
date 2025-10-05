class WeatherData {
  final double temperature;
  final double precipitation;
  final double windSpeed;
  final double humidity;
  final String condition;
  final DateTime dateTime;

  WeatherData({
    required this.temperature,
    required this.precipitation,
    required this.windSpeed,
    required this.humidity,
    required this.condition,
    required this.dateTime,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // Extract data with null safety
    final temperature = json['temperature'] != null
        ? (json['temperature'] as num).toDouble()
        : 0.0;
    final precipitation = json['precipitation'] != null
        ? (json['precipitation'] as num).toDouble()
        : 0.0;
    final windSpeed = json['windSpeed'] != null
        ? (json['windSpeed'] as num).toDouble()
        : 0.0;
    final humidity = json['humidity'] != null
        ? (json['humidity'] as num).toDouble()
        : 0.0;

    // Determine weather condition based on precipitation
    String condition = 'Sunny';
    if (precipitation > 0.1) {
      condition = 'Rainy';
    } else if (temperature > 30) {
      condition = 'Hot';
    } else if (temperature < 10) {
      condition = 'Cold';
    }

    return WeatherData(
      temperature: temperature,
      precipitation: precipitation,
      windSpeed: windSpeed,
      humidity: humidity,
      condition: condition,
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }
}
