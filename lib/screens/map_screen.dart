import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/site_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  List<SiteModel> _allSites = [];
  List<SiteModel> _filteredSites = [];
  String _selectedFilter = 'all';
  String? _searchedCity;
  bool _isSearching = false;
  bool _addMode = false;
  bool _showSidebar = false;
  LatLng? _tempLocation;

  static const LatLng _initialCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadSites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
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
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        12,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _loadSites() {
    _firestoreService.getSites(limit: 500).listen((sites) {
      setState(() {
        _allSites = sites;
        _applyFilter();
      });
    });
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'all') {
        _filteredSites = _allSites;
      } else if (_selectedFilter == 'low') {
        _filteredSites = _allSites.where((s) => s.carbonEstimate < 100).toList();
      } else if (_selectedFilter == 'medium') {
        _filteredSites = _allSites.where((s) => s.carbonEstimate >= 100 && s.carbonEstimate < 300).toList();
      } else if (_selectedFilter == 'high') {
        _filteredSites = _allSites.where((s) => s.carbonEstimate >= 300).toList();
      }
    });
  }

  Future<void> _searchCity() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query,India&format=json&limit=1',
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          
          setState(() {
            _searchedCity = results[0]['display_name'];
          });

          _mapController.move(LatLng(lat, lon), 11);
        } else {
          _showMessage('City not found', isError: true);
        }
      }
    } catch (e) {
      _showMessage('Error searching city', isError: true);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchedCity = null;
    });
    _mapController.move(_initialCenter, 5);
  }

  void _toggleAddMode() {
    setState(() {
      _addMode = !_addMode;
      _tempLocation = null;
    });
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latlng) {
    if (_addMode) {
      setState(() {
        _tempLocation = latlng;
      });
      _showAddSiteDialog(latlng);
    }
  }

  void _showAddSiteDialog(LatLng location) {
    showDialog(
      context: context,
      builder: (context) => AddSiteDialog(
        location: location,
        userId: Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '',
        onSiteAdded: () {
          setState(() {
            _addMode = false;
            _tempLocation = null;
          });
          _loadSites();
        },
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
      ),
    );
  }

  List<Marker> _buildSiteMarkers() {
    return _filteredSites.map((site) {
      return Marker(
        point: LatLng(site.latitude, site.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showSitePopup(site),
          child: Container(
            decoration: BoxDecoration(
              color: site.emissionColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: site.emissionColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              site.facilityIcon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showSitePopup(SiteModel site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: site.emissionColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                site.facilityIcon,
                color: site.emissionColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    site.facilityType.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    site.address,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: site.emissionColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: site.emissionColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    color: site.emissionColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${site.carbonEstimate.toStringAsFixed(0)} tCO₂/year',
                    style: TextStyle(
                      color: site.emissionColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: site.emissionColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      site.emissionLevel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (site.verifiedViolation) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verified Violation',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: MediaQuery.of(context).size.width > 768 ? 350 : double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Map Explorer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search & explore sites',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (MediaQuery.of(context).size.width <= 768)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _showSidebar = false),
                  ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search cities...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[500], size: 18),
                              onPressed: _clearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF0F1419),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (_) => _searchCity(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search, color: Colors.white, size: 20),
                    onPressed: _isSearching ? null : _searchCity,
                  ),
                ),
              ],
            ),
          ),

          if (_searchedCity != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF22C55E).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_city, color: Color(0xFF22C55E), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _searchedCity!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              isExpanded: true,
              dropdownColor: const Color(0xFF0F1419),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Filter by Emission',
                labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF0F1419),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Sites')),
                DropdownMenuItem(value: 'low', child: Text('Low Emission')),
                DropdownMenuItem(value: 'medium', child: Text('Medium Emission')),
                DropdownMenuItem(value: 'high', child: Text('High Emission')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                  _applyFilter();
                });
              },
            ),
          ),

          Expanded(
            child: _filteredSites.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchedCity == null
                                ? 'Search for a city'
                                : 'No sites found',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredSites.length,
                    itemBuilder: (context, index) {
                      final site = _filteredSites[index];
                      return _buildSiteCard(site);
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Legend',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegendItem('Low', const Color(0xFF22C55E)),
                _buildLegendItem('Medium', const Color(0xFFEAB308)),
                _buildLegendItem('High', const Color(0xFFEF4444)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1A1F2E),
              title: const Text('Map Explorer'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => setState(() => _showSidebar = true),
                ),
              ],
            ),
      body: Stack(
        children: [
          Row(
            children: [
              if (isDesktop) _buildSidebar(),

              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _initialCenter,
                        initialZoom: 5,
                        minZoom: 3,
                        maxZoom: 18,
                        onTap: _handleMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.ecolens.carbonscope',
                        ),
                        MarkerLayer(markers: _buildSiteMarkers()),
                        if (_tempLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _tempLocation!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Color(0xFFEF4444),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    if (_addMode)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.touch_app, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Tap map to add site',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _toggleAddMode,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (!_addMode)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.extended(
                          onPressed: _toggleAddMode,
                          backgroundColor: const Color(0xFF22C55E),
                          icon: const Icon(Icons.add_location, size: 20),
                          label: const Text('Add Site', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (!isDesktop && _showSidebar)
            GestureDetector(
              onTap: () => setState(() => _showSidebar = false),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {},
                    child: _buildSidebar(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSiteCard(SiteModel site) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            _mapController.move(
              LatLng(site.latitude, site.longitude),
              14,
            );
            _showSitePopup(site);
            if (!isDesktop) {
              setState(() => _showSidebar = false);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: site.emissionColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    site.facilityIcon,
                    color: site.emissionColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        site.facilityType.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: site.emissionColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${site.carbonEstimate.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: site.emissionColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              border: Border.all(color: color, width: 2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class AddSiteDialog extends StatefulWidget {
  final LatLng location;
  final String userId;
  final VoidCallback onSiteAdded;

  const AddSiteDialog({
    super.key,
    required this.location,
    required this.userId,
    required this.onSiteAdded,
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final site = SiteModel(
      id: '',
      name: _nameController.text.trim(),
      address: 'Lat: ${widget.location.latitude.toStringAsFixed(4)}, Lng: ${widget.location.longitude.toStringAsFixed(4)}',
      latitude: widget.location.latitude,
      longitude: widget.location.longitude,
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
            content: Text('✅ Site added! +50 pts'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        widget.onSiteAdded();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Add New Site',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Site Name',
                labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F1419),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _facilityType,
              dropdownColor: const Color(0xFF0F1419),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Facility Type',
                labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F1419),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'cement', child: Text('Cement')),
                DropdownMenuItem(value: 'steel', child: Text('Steel')),
                DropdownMenuItem(value: 'power', child: Text('Power')),
                DropdownMenuItem(value: 'refinery', child: Text('Refinery')),
                DropdownMenuItem(value: 'chemical', child: Text('Chemical')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _facilityType = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addSite,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
