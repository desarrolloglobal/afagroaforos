import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  // Current values
  String? _currentUserId;
  int? _currentFincaId;

  // Stream controllers for connectivity
  final _connectivityStreamController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityStreamController.stream;
  bool _isOnline = true;

  // Subscription for connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Getters
  String? get currentUserId => _currentUserId;
  int? get currentFincaId => _currentFincaId;
  bool get isOnline => _isOnline;

  // Setters
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  void setFincaId(int fincaId) {
    _currentFincaId = fincaId;
  }

  // Initialize connectivity monitoring
  Future<void> initConnectivity() async {
    // Cancel previous subscription if exists
    _connectivitySubscription?.cancel();

    // Create new subscription
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) async {
      final bool isConnected =
          results.any((result) => result != ConnectivityResult.none);
      _isOnline = isConnected;
      _connectivityStreamController.add(isConnected);

      if (isConnected) {
        await syncOfflineData();
      }
    });

    // Check initial state
    final results = await Connectivity().checkConnectivity();
    final bool isConnected =
        results.any((result) => result != ConnectivityResult.none);
    _isOnline = isConnected;
    _connectivityStreamController.add(isConnected);

    if (isConnected) {
      await syncOfflineData();
    }
  }

  // Check current connectivity
  Future<bool> checkConnectivity() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    _isOnline =
        connectivityResults.any((result) => result != ConnectivityResult.none);
    return _isOnline;
  }

  // Save aforo data offline
  Future<Map<String, dynamic>> saveAforoOffline(
      Map<String, dynamic> aforoData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing offline aforos or create empty list
      List<String> offlineAforos = prefs.getStringList('offlineAforos') ?? [];

      // Generate temporary ID (negative to avoid conflicts with real IDs)
      final tempId = -(offlineAforos.length + 1);

      // Add the temp ID to aforo data
      aforoData['id'] = tempId;

      // Add timestamp for sorting later
      aforoData['timestamp'] = DateTime.now().toIso8601String();

      // Add to offline aforos list
      offlineAforos.add(json.encode(aforoData));

      // Save back to shared preferences
      await prefs.setStringList('offlineAforos', offlineAforos);

      return {
        'success': true,
        'id': tempId,
        'message':
            'Aforo guardado localmente. Se sincronizará cuando haya conexión.',
        'data': aforoData
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al guardar localmente: $e',
        'error': e.toString()
      };
    }
  }

  // Update offline aforo
  Future<Map<String, dynamic>> updateAforoOffline(
      int aforoId, Map<String, dynamic> updateData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing offline aforos
      List<String> offlineAforos = prefs.getStringList('offlineAforos') ?? [];

      bool updated = false;

      // Find and update the specified aforo
      for (int i = 0; i < offlineAforos.length; i++) {
        Map<String, dynamic> aforo = json.decode(offlineAforos[i]);

        if (aforo['id'] == aforoId) {
          // Update with new data
          aforo.addAll(updateData);

          // Update timestamp
          aforo['timestamp'] = DateTime.now().toIso8601String();

          // Replace in the list
          offlineAforos[i] = json.encode(aforo);
          updated = true;

          // Save back to shared preferences
          await prefs.setStringList('offlineAforos', offlineAforos);

          return {
            'success': true,
            'message': 'Aforo actualizado localmente.',
            'data': aforo
          };
        }
      }

      if (!updated) {
        return {
          'success': false,
          'message': 'No se encontró el aforo con ID $aforoId',
        };
      }

      return {
        'success': true,
        'message': 'No se hicieron cambios.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar localmente: $e',
        'error': e.toString()
      };
    }
  }

  // Get offline aforo by ID
  Future<Map<String, dynamic>?> getOfflineAforoById(int aforoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing offline aforos
      List<String> offlineAforos = prefs.getStringList('offlineAforos') ?? [];

      // Find the specified aforo
      for (String aforoString in offlineAforos) {
        Map<String, dynamic> aforo = json.decode(aforoString);

        if (aforo['id'] == aforoId) {
          return aforo;
        }
      }

      // Not found
      return null;
    } catch (e) {
      print('Error retrieving offline aforo: $e');
      return null;
    }
  }

  // Get all offline aforos for a specific finca
  Future<List<Map<String, dynamic>>> getOfflineAforosByFinca(
      int fincaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing offline aforos
      List<String> offlineAforos = prefs.getStringList('offlineAforos') ?? [];

      // Filter for the specific finca
      List<Map<String, dynamic>> result = [];

      for (String aforoString in offlineAforos) {
        Map<String, dynamic> aforo = json.decode(aforoString);

        if (aforo['afofinca'] == fincaId) {
          result.add(aforo);
        }
      }

      return result;
    } catch (e) {
      print('Error retrieving offline aforos for finca: $e');
      return [];
    }
  }

  // Sync offline data with Supabase
  Future<Map<String, dynamic>> syncOfflineData() async {
    // Update this check to handle list of connectivity results
    var connectivityResults = await Connectivity().checkConnectivity();
    _isOnline =
        connectivityResults.any((result) => result != ConnectivityResult.none);

    if (!_isOnline) {
      return {
        'success': false,
        'message': 'No hay conexión a internet para sincronizar.',
      };
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing offline aforos
      List<String> offlineAforos = prefs.getStringList('offlineAforos') ?? [];

      // If no offline data, return early
      if (offlineAforos.isEmpty) {
        return {
          'success': true,
          'message': 'No hay datos para sincronizar.',
          'synced': <Map<String, dynamic>>[],
          'pending': 0
        };
      }

      // Track successful synchronizations
      List<Map<String, dynamic>> syncedAforos = [];
      List<String> remainingAforos = [];

      // Process each offline aforo
      for (String aforoString in offlineAforos) {
        try {
          Map<String, dynamic> aforo = json.decode(aforoString);

          // Remove temp ID and timestamp before sending to Supabase
          final tempId = aforo['id'];
          aforo.remove('id');
          aforo.remove('timestamp');

          // Insert into Supabase and get the real ID
          final response = await Supabase.instance.client
              .from('dbAforos')
              .insert(aforo)
              .select()
              .single();

          // Record successful sync
          syncedAforos.add(
              {'tempId': tempId, 'realId': response['id'], 'data': response});
        } catch (e) {
          // If this aforo failed to sync, keep it for later
          remainingAforos.add(aforoString);
          print('Error syncing aforo: $e');
        }
      }

      // Save remaining aforos back to shared preferences
      await prefs.setStringList('offlineAforos', remainingAforos);

      return {
        'success': true,
        'message':
            'Sincronización completada. ${syncedAforos.length} aforos sincronizados, ${remainingAforos.length} pendientes.',
        'synced': syncedAforos,
        'pending': remainingAforos.length
      };
    } catch (e) {
      print('Error during synchronization: $e');
      return {
        'success': false,
        'message': 'Error durante la sincronización: $e',
        'error': e.toString(),
        'synced': <Map<String, dynamic>>[]
      };
    }
  }

  // Clear all offline data (for testing)
  Future<void> clearOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offlineAforos');
  }

  // Cleanup
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityStreamController.close();
  }
}
