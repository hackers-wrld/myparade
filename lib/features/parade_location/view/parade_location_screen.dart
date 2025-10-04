import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myparadefixed/core/constants/strings.dart';
import 'package:myparadefixed/features/parade_location/controller/location_controller.dart';
import 'package:provider/provider.dart';

import 'date_time_picker_screen.dart';

class ParadeLocationScreen extends StatefulWidget {
  const ParadeLocationScreen({super.key});

  @override
  State<ParadeLocationScreen> createState() => _ParadeLocationScreenState();
}

class _ParadeLocationScreenState extends State<ParadeLocationScreen> {
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isBottomSheetExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDefaultLocation();
    });
  }

  Future<void> _initializeDefaultLocation() async {
    final controller = Provider.of<LocationController>(context, listen: false);
    await controller.updateLocation(40.7128, -74.0060);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LocationController>(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.appName), centerTitle: true),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                controller.currentLocation?.latitude ?? 40.7128,
                controller.currentLocation?.longitude ?? -74.0060,
              ),
              zoom: 14,
            ),
            markers: {
              if (controller.currentLocation != null)
                Marker(
                  markerId: const MarkerId('userPin'),
                  position: LatLng(
                    controller.currentLocation!.latitude,
                    controller.currentLocation!.longitude,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
            },
            onMapCreated: (GoogleMapController mapController) {
              _mapController = mapController;
            },
            onTap: (LatLng tappedPoint) async {
              await controller.updateLocation(
                tappedPoint.latitude,
                tappedPoint.longitude,
              );
              _moveCameraToLocation(
                tappedPoint.latitude,
                tappedPoint.longitude,
              );

              if (controller.currentLocation != null) {
                _searchController.text = controller.currentLocation!.address;
              }
            },
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _calculateBottomSheetHeight(controller),
              child: _buildBottomSheet(controller),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBottomSheetHeight(LocationController controller) {
    final maxHeight =
        MediaQuery.of(context).size.height * 0.7; // Max 70% of screen
    final minHeight = 200.0; // Default height

    if (controller.suggestions.isNotEmpty || controller.isSearching) {
      return maxHeight;
    }
    return minHeight;
  }

  Widget _buildBottomSheet(LocationController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.addressHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                controller.searchLocations(value);
              },
              onSubmitted: (value) {
                controller.clearSuggestions();
              },
            ),
            const SizedBox(height: 16),

            // Suggestions List
            Expanded(
              child: controller.isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : controller.suggestions.isNotEmpty
                  ? ListView.builder(
                      itemCount: controller.suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = controller.suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(
                            suggestion.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            controller.selectSuggestion(suggestion);
                            _searchController.text = suggestion.address;
                            _moveCameraToLocation(
                              suggestion.latitude,
                              suggestion.longitude,
                            );
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                    )
                  : const SizedBox(),
            ),

            // Choose Location Button
            if (controller.currentLocation != null) const SizedBox(height: 16),
            if (controller.currentLocation != null)
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Selected: ${controller.currentLocation!.address}',
                      ),
                    ),
                  );

                  if (controller.currentLocation != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DateTimePickerScreen(
                          locationAddress: controller.currentLocation!.address,
                        ),
                      ),
                    );
                  }
                },
                child: Text(AppStrings.chooseLocation),
              ),
          ],
        ),
      ),
    );
  }

  void _moveCameraToLocation(double lat, double lng) {
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
