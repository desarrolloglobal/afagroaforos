import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './crear_aforo_1.dart';
import 'offline_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ListaAforos extends StatefulWidget {
  final int fincaId;
  final String userId;

  const ListaAforos({
    Key? key,
    required this.fincaId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ListaAforos> createState() => _ListaAforosState();
}

class _ListaAforosState extends State<ListaAforos> {
  final _supabase = Supabase.instance.client;
  final _offlineManager = OfflineManager();
  List<Map<String, dynamic>> aforos = [];
  List<Map<String, dynamic>> offlineAforos = [];
  bool isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);

    // Set current finca ID in offline manager
    _offlineManager.setFincaId(widget.fincaId);
    _offlineManager.setUserId(widget.userId);

    _cargarAforos();
  }

  Future<void> _checkConnectivity() async {
    bool isOnline = await _offlineManager.checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    setState(() {
      // Check if any of the results are not "none"
      _isOnline = results.any((result) => result != ConnectivityResult.none);
    });

    // If connection is restored, reload data
    if (_isOnline) {
      _cargarAforos();
    }
  }

  Future<void> _cargarAforos() async {
    setState(() => isLoading = true);

    try {
      // Always load offline aforos
      offlineAforos =
          await _offlineManager.getOfflineAforosByFinca(widget.fincaId);

      // Try to load online aforos if connected
      if (_isOnline) {
        final response = await _supabase
            .from('dbAforos')
            .select('id, nConsecutivo, nDescripcion, afofinca, nFecha')
            .eq('afofinca', widget.fincaId);

        setState(() {
          aforos = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });

        // If we have a connection, try to sync offline data
        if (offlineAforos.isNotEmpty) {
          _offlineManager.syncOfflineData().then((result) {
            if (result['success'] && result['synced'].length > 0) {
              // Reload data after successful sync
              _cargarAforos();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${result['synced'].length} aforos sincronizados exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        }
      } else {
        // If offline, just show offline aforos
        setState(() {
          aforos = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los aforos: ${e.toString()}')),
      );
    }
  }

  // Method to manually trigger sync
  Future<void> _syncOfflineData() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No hay conexión a Internet. Intente más tarde.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _offlineManager.syncOfflineData();

      if (result['success']) {
        // Reload aforos
        _cargarAforos();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error durante la sincronización: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('AFOROS FINCA${!_isOnline ? ' (OFFLINE)' : ''}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Show sync button if there are offline aforos and we're online
          if (_isOnline && offlineAforos.isNotEmpty)
            IconButton(
              icon: Icon(Icons.sync, color: Colors.white),
              onPressed: _syncOfflineData,
              tooltip: 'Sincronizar aforos',
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show connectivity status indicator
                if (!_isOnline)
                  Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Modo sin conexión. Puede crear nuevos aforos que se sincronizarán cuando se restablezca la conexión.',
                            style: TextStyle(color: Colors.orange[800]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Show offline aforos indicator if we have any
                if (offlineAforos.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _isOnline ? Colors.blue : Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isOnline ? Icons.sync : Icons.sync_disabled,
                          color: _isOnline ? Colors.blue : Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isOnline
                                ? 'Hay ${offlineAforos.length} aforos guardados localmente. Puede sincronizarlos ahora usando el botón de sincronización.'
                                : 'Hay ${offlineAforos.length} aforos guardados localmente que se sincronizarán cuando se restablezca la conexión.',
                            style: TextStyle(
                              color: _isOnline
                                  ? Colors.blue[800]
                                  : Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: Text('Consecutivo',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text('Descripción',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text('Estado',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView(
                          children: [
                            // Online aforos
                            if (_isOnline && aforos.isNotEmpty)
                              ...aforos
                                  .map((aforo) => _buildAforoCard(aforo, false))
                                  .toList(),

                            // Offline aforos
                            if (offlineAforos.isNotEmpty)
                              ...offlineAforos
                                  .map((aforo) => _buildAforoCard(aforo, true))
                                  .toList(),

                            // No aforos message
                            if (aforos.isEmpty && offlineAforos.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    'No hay aforos para mostrar. Use el botón + para crear uno nuevo.',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context,
          '/crear_aforo_1',
          arguments: {
            'fincaId': widget.fincaId,
            'userId': widget.userId,
          },
        ),
        backgroundColor: Color(0xFF34A853),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAforoCard(Map<String, dynamic> aforo, bool isOffline) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: isOffline ? Color(0xFFE9AA64) : Color(0xFF1B4D3E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          try {
            final id = aforo['id'];
            print('Navegando a aforo con ID: $id'); // Para debug

            Navigator.pushNamed(
              context,
              '/vista_aforo',
              arguments: {
                'aforoId': id,
                'fincaId': widget.fincaId,
                'userId': widget.userId,
                'isOffline': isOffline,
              },
            );
          } catch (e) {
            print('Error al navegar: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error al abrir el aforo: ${e.toString()}')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${aforo['nConsecutivo'] ?? "N/A"}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Expanded(
                child: Text(
                  '${aforo['nDescripcion'] ?? "Sin descripción"}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isOffline ? Icons.cloud_off : Icons.cloud_done,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      isOffline ? 'Pendiente' : 'Sincronizado',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
