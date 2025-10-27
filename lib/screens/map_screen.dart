import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/site_model.dart';
import 'site_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  String _selectedFilter = 'all';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 5,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 12,
          ),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _updateMarkers(List<SiteModel> sites) {
    setState(() {
      _markers = sites.map((site) {
        return Marker(
          markerId: MarkerId(site.id),
          position: LatLng(site.latitude, site.longitude),
          infoWindow: InfoWindow(
            title: site.name,
            snippet: '${site.carbonEstimate.toStringAsFixed(0)} tons/year',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SiteDetailScreen(siteId: site.id),
                ),
              );
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            site.carbonEstimate < 100
                ? BitmapDescriptor.hueGreen
                : site.carbonEstimate < 300
                    ? BitmapDescriptor.hueYellow
                    : BitmapDescriptor.hueRed,
          ),
        );
      }).toSet();
    });
  }

  void _showAddSiteDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AddSiteDialog(
        currentPosition: _currentPosition,
        userId: authService.currentUser?.uid ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Explorer'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Sites')),
              const PopupMenuItem(value: 'low', child: Text('Low Emission')),
              const PopupMenuItem(value: 'medium', child: Text('Medium Emission')),
              const PopupMenuItem(value: 'high', child: Text('High Emission')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<SiteModel>>(
        stream: _selectedFilter == 'all'
            ? _firestoreService.getSites()
            : _firestoreService.getSitesByEmission(_selectedFilter),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _updateMarkers(snapshot.data!);
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _initialPosition,
                markers: _markers,
                onMapCreated: (controller) => _mapController = controller,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
              ),
              
              // Legend
              Positioned(
                top: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Legend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem('Low', const Color(0xFF22C55E)),
                        _buildLegendItem('Medium', const Color(0xFFEAB308)),
                        _buildLegendItem('High', const Color(0xFFEF4444)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSiteDialog,
        icon: const Icon(Icons.add_location),
        label: const Text('Add Site'),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Add Site Dialog
class AddSiteDialog extends StatefulWidget {
  final Position? currentPosition;
  final String userId;

  const AddSiteDialog({
    super.key,
    required this.currentPosition,
    required this.userId,
  });

  @override
  State<AddSiteDialog> createState() => _AddSiteDialogState();
}

class _AddSiteDialogState extends State<AddSiteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _facilityType = 'cement';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addSite() async {
    if (_formKey.currentState!.validate() && widget.currentPosition != null) {
      setState(() => _isLoading = true);

      final site = SiteModel(
        id: '',
        name: _nameController.text.trim(),
        address: 'Location: ${widget.currentPosition!.latitude.toStringAsFixed(4)}, ${widget.currentPosition!.longitude.toStringAsFixed(4)}',
        latitude: widget.currentPosition!.latitude,
        longitude: widget.currentPosition!.longitude,
        facilityType: _facilityType,
        carbonEstimate: 100 + (200 * (DateTime.now().millisecond % 300) / 300),
        verifiedViolation: false,
        reportCount: 1,
        createdBy: widget.userId,
      );

      final firestoreService = FirestoreService();
      String? siteId = await firestoreService.addSite(site, widget.userId);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);

        if (siteId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Site added successfully! +50 points'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to add site'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Site'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Site Name',
                hintText: 'e.g., Delhi Cement Plant',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a site name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _facilityType,
              decoration: const InputDecoration(
                labelText: 'Facility Type',
              ),
              items: const [
                DropdownMenuItem(value: 'cement', child: Text('Cement Plant')),
                DropdownMenuItem(value: 'steel', child: Text('Steel Factory')),
                DropdownMenuItem(value: 'power', child: Text('Power Plant')),
                DropdownMenuItem(value: 'refinery', child: Text('Oil Refinery')),
                DropdownMenuItem(value: 'chemical', child: Text('Chemical Plant')),
                DropdownMenuItem(value: 'other', child: Text('Other Industrial')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _facilityType = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addSite,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Site'),
        ),
      ],
    );
  }
}
