import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/weather_model.dart';

class WeatherController extends ChangeNotifier {
  WeatherData? _weatherData;
  WeatherData? get weatherData => _weatherData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> fetchWeather(
    double latitude,
    double longitude,
    DateTime dateTime,
  ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // NASA POWER API endpoint for single point data request
      final url = Uri.parse(
        'https://power.larc.nasa.gov/api/temporal/hourly/point?'
        'start=${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}${dateTime.day.toString().padLeft(2, '0')}&'
        'end=${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}${dateTime.day.toString().padLeft(2, '0')}&'
        'latitude=$latitude&'
        'longitude=$longitude&'
        'community=AG&'
        'parameters=T2M,PRECTOTCORR,WS10M,RH2M&'
        'format=json',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if data structure is valid
        if (data['properties'] == null ||
            data['properties']['parameter'] == null) {
          _errorMessage = 'No weather data available for this location.';
          return;
        }

        final hourlyData = data['properties']['parameter'];

        // Extract data with proper type handling and casting
        double temperature = 0.0;
        double precipitation = 0.0;
        double windSpeed = 0.0;
        double humidity = 0.0;

        // Handle T2M (Temperature)
        if (hourlyData['T2M'] is List) {
          final tempList = hourlyData['T2M'] as List<dynamic>;
          if (tempList.isNotEmpty) {
            final tempValue = tempList[0];
            if (tempValue is num) {
              temperature = tempValue.toDouble();
            } else if (tempValue is String) {
              temperature = double.tryParse(tempValue) ?? 0.0;
            }
          }
        } else if (hourlyData['T2M'] is Map) {
          final tempMap = hourlyData['T2M'] as Map<String, dynamic>;
          final tempValue = tempMap.values.firstWhere(
            (value) => value is num || value is String,
            orElse: () => 0.0,
          );
          if (tempValue is num) {
            temperature = tempValue.toDouble();
          } else if (tempValue is String) {
            temperature = double.tryParse(tempValue) ?? 0.0;
          }
        } else if (hourlyData['T2M'] is num) {
          temperature = (hourlyData['T2M'] as num).toDouble();
        } else if (hourlyData['T2M'] is String) {
          temperature = double.tryParse(hourlyData['T2M']) ?? 0.0;
        }

        // Handle PRECTOTCORR (Precipitation)
        if (hourlyData['PRECTOTCORR'] is List) {
          final precipList = hourlyData['PRECTOTCORR'] as List<dynamic>;
          if (precipList.isNotEmpty) {
            final precipValue = precipList[0];
            if (precipValue is num) {
              precipitation = precipValue.toDouble();
            } else if (precipValue is String) {
              precipitation = double.tryParse(precipValue) ?? 0.0;
            }
          }
        } else if (hourlyData['PRECTOTCORR'] is Map) {
          final precipMap = hourlyData['PRECTOTCORR'] as Map<String, dynamic>;
          final precipValue = precipMap.values.firstWhere(
            (value) => value is num || value is String,
            orElse: () => 0.0,
          );
          if (precipValue is num) {
            precipitation = precipValue.toDouble();
          } else if (precipValue is String) {
            precipitation = double.tryParse(precipValue) ?? 0.0;
          }
        } else if (hourlyData['PRECTOTCORR'] is num) {
          precipitation = (hourlyData['PRECTOTCORR'] as num).toDouble();
        } else if (hourlyData['PRECTOTCORR'] is String) {
          precipitation = double.tryParse(hourlyData['PRECTOTCORR']) ?? 0.0;
        }

        // Handle WS10M (Wind Speed)
        if (hourlyData['WS10M'] is List) {
          final windList = hourlyData['WS10M'] as List<dynamic>;
          if (windList.isNotEmpty) {
            final windValue = windList[0];
            if (windValue is num) {
              windSpeed = windValue.toDouble();
            } else if (windValue is String) {
              windSpeed = double.tryParse(windValue) ?? 0.0;
            }
          }
        } else if (hourlyData['WS10M'] is Map) {
          final windMap = hourlyData['WS10M'] as Map<String, dynamic>;
          final windValue = windMap.values.firstWhere(
            (value) => value is num || value is String,
            orElse: () => 0.0,
          );
          if (windValue is num) {
            windSpeed = windValue.toDouble();
          } else if (windValue is String) {
            windSpeed = double.tryParse(windValue) ?? 0.0;
          }
        } else if (hourlyData['WS10M'] is num) {
          windSpeed = (hourlyData['WS10M'] as num).toDouble();
        } else if (hourlyData['WS10M'] is String) {
          windSpeed = double.tryParse(hourlyData['WS10M']) ?? 0.0;
        }

        // Handle RH2M (Humidity)
        if (hourlyData['RH2M'] is List) {
          final humList = hourlyData['RH2M'] as List<dynamic>;
          if (humList.isNotEmpty) {
            final humValue = humList[0];
            if (humValue is num) {
              humidity = humValue.toDouble();
            } else if (humValue is String) {
              humidity = double.tryParse(humValue) ?? 0.0;
            }
          }
        } else if (hourlyData['RH2M'] is Map) {
          final humMap = hourlyData['RH2M'] as Map<String, dynamic>;
          final humValue = humMap.values.firstWhere(
            (value) => value is num || value is String,
            orElse: () => 0.0,
          );
          if (humValue is num) {
            humidity = humValue.toDouble();
          } else if (humValue is String) {
            humidity = double.tryParse(humValue) ?? 0.0;
          }
        } else if (hourlyData['RH2M'] is num) {
          humidity = (hourlyData['RH2M'] as num).toDouble();
        } else if (hourlyData['RH2M'] is String) {
          humidity = double.tryParse(hourlyData['RH2M']) ?? 0.0;
        }

        // Determine weather condition based on precipitation
        String condition = 'Sunny';
        if (precipitation > 0.1) {
          condition = 'Rainy';
        } else if (temperature > 30) {
          condition = 'Hot';
        } else if (temperature < 10) {
          condition = 'Cold';
        }

        _weatherData = WeatherData(
          temperature: temperature,
          precipitation: precipitation,
          windSpeed: windSpeed,
          humidity: humidity,
          condition: condition,
          dateTime: dateTime,
        );
      } else {
        _errorMessage =
            'Failed to fetch weather data. Status code: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error fetching weather data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
