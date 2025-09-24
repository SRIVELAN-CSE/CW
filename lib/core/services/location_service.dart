import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check permissions
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Debug: Print all available placemark data
        print('Debug - Placemark data:');
        print('Name: ${place.name}');
        print('Street: ${place.street}');
        print('Thoroughfare: ${place.thoroughfare}');
        print('SubThoroughfare: ${place.subThoroughfare}');
        print('Locality: ${place.locality}');
        print('SubLocality: ${place.subLocality}');
        print('AdministrativeArea: ${place.administrativeArea}');
        print('PostalCode: ${place.postalCode}');
        print('Country: ${place.country}');
        
        String formattedAddress = _formatAddress(place);
        
        // Ensure we don't return coordinates as address
        if (formattedAddress.contains('Lat:') || formattedAddress.contains('Lng:')) {
          return 'Current Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
        }
        
        return formattedAddress;
      }
      
      return 'Current Location (Address not available)';
    } catch (e) {
      print('Error getting address: $e');
      // Try to provide a meaningful location description instead of raw coordinates
      return 'Current Location (${_getLocationDescription(latitude, longitude)})';
    }
  }

  // Helper method to provide location description based on coordinates
  String _getLocationDescription(double latitude, double longitude) {
    // Basic location description based on coordinates
    String latDirection = latitude >= 0 ? 'N' : 'S';
    String lngDirection = longitude >= 0 ? 'E' : 'W';
    
    return '${latitude.abs().toStringAsFixed(4)}°$latDirection, ${longitude.abs().toStringAsFixed(4)}°$lngDirection';
  }

  // Format address from placemark
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    
    // Street number and name
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    
    // Sub-locality (neighborhood/area)
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }
    
    // City/Locality
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    
    // State/Administrative Area
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    
    // Postal Code
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }
    
    // Country (for international addresses)
    if (place.country != null && place.country!.isNotEmpty && place.country != place.administrativeArea) {
      addressParts.add(place.country!);
    }
    
    // Ensure we have at least some address information
    if (addressParts.isEmpty) {
      // If no standard address parts, try to construct from available data
      if (place.name != null && place.name!.isNotEmpty) {
        addressParts.add(place.name!);
      }
      if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
        addressParts.add(place.thoroughfare!);
      }
      if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
        addressParts.add(place.subThoroughfare!);
      }
    }
    
    // Return formatted address or a fallback
    return addressParts.isNotEmpty 
        ? addressParts.join(', ')
        : 'Current Location (Address details unavailable)';
  }

  // Get location with address - enhanced version
  Future<LocationData?> getCurrentLocationWithAddress() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) return null;

      // Try multiple times to get a proper address
      String address = await _getAddressWithRetry(position.latitude, position.longitude);

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      print('Error getting location with address: $e');
      return null;
    }
  }

  // Helper method to retry address resolution
  Future<String> _getAddressWithRetry(double latitude, double longitude, {int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        String address = await getAddressFromCoordinates(latitude, longitude);
        
        // Check if we got a real address (not coordinates)
        if (!address.contains('Lat:') && !address.contains('Lng:') && address != 'Unknown location') {
          return address;
        }
        
        // Wait a bit before retrying
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      } catch (e) {
        print('Address resolution attempt ${attempt + 1} failed: $e');
      }
    }
    
    // Final fallback - provide a descriptive location
    return _generateFallbackAddress(latitude, longitude);
  }

  // Generate a meaningful fallback address
  String _generateFallbackAddress(double latitude, double longitude) {
    // Determine general location based on coordinates
    String region = _getRegionFromCoordinates(latitude, longitude);
    return 'Location in $region (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
  }

  // Get region description from coordinates
  String _getRegionFromCoordinates(double latitude, double longitude) {
    // Basic region detection for India (you can expand this)
    if (latitude >= 8.0 && latitude <= 37.0 && longitude >= 68.0 && longitude <= 97.0) {
      if (latitude >= 28.0 && longitude >= 76.0 && longitude <= 78.0) {
        return 'Delhi NCR, India';
      } else if (latitude >= 18.0 && latitude <= 19.5 && longitude >= 72.5 && longitude <= 73.5) {
        return 'Mumbai, Maharashtra, India';
      } else if (latitude >= 12.8 && latitude <= 13.2 && longitude >= 77.4 && longitude <= 77.8) {
        return 'Bangalore, Karnataka, India';
      } else if (latitude >= 13.0 && latitude <= 13.2 && longitude >= 80.1 && longitude <= 80.3) {
        return 'Chennai, Tamil Nadu, India';
      } else {
        return 'India';
      }
    }
    
    // Global fallback
    return 'Current Location';
  }

  // Calculate distance between two points
  double calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings for permissions
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final double accuracy;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.accuracy,
    required this.timestamp,
  });

  String get coordinates => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  
  String get formattedAccuracy => '±${accuracy.toStringAsFixed(0)}m';

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: json['latitude'],
    longitude: json['longitude'],
    address: json['address'],
    accuracy: json['accuracy'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}