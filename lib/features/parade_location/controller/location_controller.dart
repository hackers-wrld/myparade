import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../model/location_model.dart';

class LocationController extends ChangeNotifier {
  LocationModel? _currentLocation;
  LocationModel? get currentLocation => _currentLocation;

  List<LocationModel> _suggestions = [];
  List<LocationModel> get suggestions => _suggestions;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  Future<void> updateLocation(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final place = placemarks.first;
      final fullAddress =
          '${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}'
              .replaceAll(', ,', ', ')
              .replaceAll(',,', ',')
              .trim();

      _currentLocation = LocationModel(
        latitude: lat,
        longitude: lng,
        address: fullAddress,
      );

      notifyListeners();
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  Future<void> searchLocations(String query) async {
    if (query.isEmpty) {
      _suggestions.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      // Find coordinates from the query
      final locations = await locationFromAddress(query);

      // Convert each location back to full address
      _suggestions = [];
      for (var loc in locations) {
        final placemarks = await placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final fullAddress =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}'
                  .replaceAll(', ,', ', ')
                  .replaceAll(',,', ',')
                  .trim();

          _suggestions.add(
            LocationModel(
              latitude: loc.latitude,
              longitude: loc.longitude,
              address: fullAddress,
            ),
          );
        }
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void selectSuggestion(LocationModel suggestion) {
    _currentLocation = suggestion;
    _suggestions.clear(); // Clear suggestions after selection
    notifyListeners();
  }

  // Add this method to clear suggestions
  void clearSuggestions() {
    _suggestions.clear();
    notifyListeners();
  }
}
