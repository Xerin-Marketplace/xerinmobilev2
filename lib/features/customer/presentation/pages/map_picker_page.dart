import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/map_api_service.dart';

class MapPickerResult {
  final double latitude;
  final double longitude;
  final String? formattedAddress;
  final String? country;
  final String? region;
  final String? district;
  final String? ward;
  final String? city;
  final String? street;
  final String? postalCode;
  final String? placeId;

  const MapPickerResult({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.country,
    this.region,
    this.district,
    this.ward,
    this.city,
    this.street,
    this.postalCode,
    this.placeId,
  });
}

class MapPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const MapPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late GoogleMapController _mapController;
  CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(-6.3690, 34.8888),
    zoom: 6,
  );

  LatLng? _selectedPosition;
  String? _selectedAddress;
  MapResolvedLocation? _resolvedLocation;
  bool _isResolving = false;
  bool _isSearching = false;
  bool _mapReady = false;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<MapPrediction> _predictions = [];
  bool _showPredictions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _initialCamera = CameraPosition(
        target: LatLng(widget.initialLatitude!, widget.initialLongitude!),
        zoom: 15,
      );
      _selectedPosition = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _selectedAddress = widget.initialAddress;
    }
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        setState(() => _showPredictions = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    setState(() => _mapReady = true);

    if (widget.initialLatitude == null) {
      _goToCurrentLocation();
    } else if (_selectedPosition != null) {
      _reverseGeocode(_selectedPosition!);
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final loc = await GetIt.instance<LocationService>().getCurrentLocation();
      final pos = LatLng(loc.latitude, loc.longitude);
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
      setState(() {
        _selectedPosition = pos;
        _selectedAddress = null;
        _resolvedLocation = null;
      });
      _reverseGeocode(pos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    if (!_isResolving) {
      setState(() => _selectedPosition = position.target);
    }
  }

  Future<void> _onCameraIdle() async {
    if (_selectedPosition != null && !_isResolving) {
      _reverseGeocode(_selectedPosition!);
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() {
      _isResolving = true;
      _selectedAddress = null;
      _resolvedLocation = null;
    });
    try {
      final result = await GetIt.instance<MapApiService>().reverseGeocode(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (mounted) {
        setState(() {
          _resolvedLocation = result;
          _selectedAddress = result.formattedAddress;
          _isResolving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResolving = false;
          _selectedAddress = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        });
      }
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _predictions = [];
        _showPredictions = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await GetIt.instance<MapApiService>().autocomplete(
        query: query.trim(),
        countryCode: 'TZ',
      );
      if (mounted) {
        setState(() {
          _predictions = results;
          _showPredictions = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showPredictions = false;
        });
      }
    }
  }

  Future<void> _onPredictionSelected(MapPrediction prediction) async {
    setState(() {
      _showPredictions = false;
      _isResolving = true;
      _searchController.text = prediction.description;
    });
    _searchFocus.unfocus();
    try {
      final details = await GetIt.instance<MapApiService>().getPlaceDetails(
        placeId: prediction.placeId,
      );
      final pos = LatLng(details.latitude, details.longitude);
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
      if (mounted) {
        setState(() {
          _selectedPosition = pos;
          _resolvedLocation = details;
          _selectedAddress = details.formattedAddress ?? prediction.description;
          _isResolving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResolving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  void _confirmSelection() {
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map first'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final result = MapPickerResult(
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
      formattedAddress: _resolvedLocation?.formattedAddress,
      country: _resolvedLocation?.country,
      region: _resolvedLocation?.region,
      district: _resolvedLocation?.district,
      ward: _resolvedLocation?.ward,
      city: _resolvedLocation?.city,
      street: _resolvedLocation?.street,
      postalCode: _resolvedLocation?.postalCode,
      placeId: _resolvedLocation?.placeId,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
            buildingsEnabled: true,
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedPosition!,
                      draggable: false,
                      consumeTapEvents: true,
                      infoWindow: InfoWindow(
                        title: _selectedAddress ?? 'Selected location',
                      ),
                    ),
                  }
                : {},
          ),

          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(cs, isDark),
                if (_showPredictions && _predictions.isNotEmpty)
                  _buildPredictionsList(cs, isDark),
                const Spacer(),
                _buildLocationInfoCard(cs, isDark),
                _buildBottomActions(cs),
              ],
            ),
          ),

          if (!_mapReady)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, color: cs.onSurface),
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search for a place...',
                  hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _predictions = [];
                                  _showPredictions = false;
                                });
                              },
                            )
                          : null,
                ),
              ),
            ),
            IconButton(
              onPressed: _goToCurrentLocation,
              icon: Icon(Icons.my_location, color: cs.primary),
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsList(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _predictions.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          itemBuilder: (context, index) {
            final p = _predictions[index];
            return ListTile(
              dense: true,
              leading: Icon(Icons.location_on_outlined, size: 20, color: cs.primary),
              title: Text(
                p.mainText ?? p.description,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: p.secondaryText != null
                  ? Text(
                      p.secondaryText!,
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () => _onPredictionSelected(p),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationInfoCard(ColorScheme cs, bool isDark) {
    if (_selectedPosition == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.location_on, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Location',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                      const SizedBox(height: 2),
                      if (_isResolving)
                        Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.primary),
                            ),
                            const SizedBox(width: 8),
                            Text('Resolving address...',
                              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        )
                      else
                        Text(
                          _selectedAddress ?? 'Tap on the map to select',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!_isResolving && _selectedAddress != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed, size: 12, color: const Color(0xFF22C55E)),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _isResolving ? null : _confirmSelection,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
