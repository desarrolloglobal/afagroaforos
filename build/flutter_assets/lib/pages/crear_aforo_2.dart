import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'vista_aforo.dart';
import 'offline_manager.dart'; // Import the new class

class CrearAforo extends StatefulWidget {
  final int fincaId;
  final String userId;
  final int aforoId;
  final int nConsecutivo;
  final String nDescripcion;
  final double C28;
  final double C29;
  final bool isOffline; // New parameter to indicate if this is an offline aforo

  const CrearAforo({
    Key? key,
    required this.fincaId,
    required this.userId,
    required this.aforoId,
    required this.nConsecutivo,
    required this.nDescripcion,
    required this.C28,
    required this.C29,
    this.isOffline = false, // Default to online mode
  }) : super(key: key);

  @override
  State<CrearAforo> createState() => _CrearAforoState();
}

class _CrearAforoState extends State<CrearAforo> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _offlineManager = OfflineManager(); // Use the offline manager
  bool _isLoading = false;
  bool _isCalculated = false;
  bool _isOnline = true; // Track connectivity status
  Map<String, double> _calculatedResults = {};

  // Form controllers
  final _c05Controller = TextEditingController();
  final _especiesController = TextEditingController();
  final _c28Controller = TextEditingController();
  final _c29Controller = TextEditingController();
  final _c10Controller = TextEditingController();
  final _c11Controller = TextEditingController();
  final _c12Controller = TextEditingController();
  final _c14Controller = TextEditingController();
  final _c15Controller = TextEditingController();
  final _c16Controller = TextEditingController();
  final _c33Controller = TextEditingController();
  final _c34Controller = TextEditingController();
  final _c35Controller = TextEditingController();
  final _c37Controller = TextEditingController();
  final _c40Controller = TextEditingController();

  String? _selectedTipoMarco;
  final List<String> _tiposMarco = [
    '25 cm x 25 cm',
    '50 cm x 50 cm',
    '1 m x 1 m'
  ];

  @override
  void initState() {
    super.initState();
    _selectedTipoMarco = _tiposMarco[2]; // Default to "1 m x 1 m"
    // Inicializar los controladores con los valores del aforo anterior
    _c28Controller.text = widget.C28.toString();
    _c29Controller.text = widget.C29.toStringAsFixed(2);

    // Store current finca ID in offline manager
    _offlineManager.setFincaId(widget.fincaId);
    _offlineManager.setUserId(widget.userId);

    // Check connectivity initially and setup listener
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      if (result is List<ConnectivityResult>) {
        // Handle list case - typically use the first/most relevant result
        if (result.isNotEmpty) {
          _updateConnectionStatus(result.first);
        }
      } else if (result is ConnectivityResult) {
        // Handle single result case
        _updateConnectionStatus(result);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    bool isOnline = await _offlineManager.checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  void _updateConnectionStatus(dynamic result) {
    setState(() {
      if (result is List<ConnectivityResult>) {
        _isOnline =
            result.isNotEmpty && result.first != ConnectivityResult.none;
      } else if (result is ConnectivityResult) {
        _isOnline = result != ConnectivityResult.none;
      }
    });
  }

  @override
  void dispose() {
    _c05Controller.dispose();
    _especiesController.dispose();
    _c28Controller.dispose();
    _c29Controller.dispose();
    _c10Controller.dispose();
    _c11Controller.dispose();
    _c12Controller.dispose();
    _c14Controller.dispose();
    _c15Controller.dispose();
    _c16Controller.dispose();
    _c33Controller.dispose();
    _c34Controller.dispose();
    _c35Controller.dispose();
    _c37Controller.dispose();
    _c40Controller.dispose();
    super.dispose();
  }

  String _formatNumber(String fieldName, double value) {
    if (['C18', 'C19', 'C20', 'C21', 'C22', 'C23', 'C24', 'C25']
        .contains(fieldName)) {
      final formatter = NumberFormat('#,##0', 'es');
      return formatter.format(value);
    } else if (['C30', 'C31', 'C32'].contains(fieldName)) {
      final formatter = NumberFormat('#,##0.00', 'es');
      return formatter.format(value);
    }
    return value.toStringAsFixed(2); // Default format
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
      String label, List<String> fieldNames, List<double> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Bajo: ${_formatNumber(fieldNames[0], values[0])}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Medio: ${_formatNumber(fieldNames[1], values[1])}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Alto: ${_formatNumber(fieldNames[2], values[2])}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String fieldName, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatNumber(fieldName, value),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Este método se ejecuta cuando el usuario hace clic en "Ver"
  void _calculateResults() {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Parse basic input values
      final c05 = double.parse(_c05Controller.text);
      final c10 = double.parse(_c10Controller.text);
      final c11 = double.parse(_c11Controller.text);
      final c12 = double.parse(_c12Controller.text);
      final c14 = double.parse(_c14Controller.text);
      final c15 = double.parse(_c15Controller.text);
      final c16 = double.parse(_c16Controller.text);
      final c28 = double.parse(_c28Controller.text);
      final c29 = double.parse(_c29Controller.text);

      // Get marco multiplicador based on selected type
      int marcoMultiplicador;
      switch (_selectedTipoMarco) {
        case '25 cm x 25 cm':
          marcoMultiplicador = 16;
          break;
        case '50 cm x 50 cm':
          marcoMultiplicador = 4;
          break;
        case '1 m x 1 m':
          marcoMultiplicador = 1;
          break;
        default:
          marcoMultiplicador = 1;
      }

      // Initialize results map with basic calculations
      _calculatedResults = {
        'C18': c05 * c14 / 100,
        'C19': c05 * c15 / 100,
        'C20': c05 * c16 / 100,
        'C21': c05 * c14 * c10 / 100,
        'C22': c05 * c15 * c11 / 100,
        'C23': c05 * c16 * c12 / 100,
        'C24':
            ((c05 * c14 * c10) + (c05 * c15 * c11) + (c05 * c16 * c12)) / 100,
        'C25': 0.0,
        'C26': marcoMultiplicador.toDouble(),
        'C30': 0.0,
        'C31': 0.0,
        'C32': 0.0,
      };

      // Calculate derived values
      _calculatedResults['C25'] = _calculatedResults['C24']! / 1000;
      _calculatedResults['C30'] = c05 / 10000; // Convert m² to hectares

      // Avoid division by zero in C31
      if (_calculatedResults['C30']! > 0) {
        _calculatedResults['C31'] = c29 / _calculatedResults['C30']!;
      }

      _calculatedResults['C32'] = ((c10 * c14) + (c11 * c15) + (c12 * c16)) *
          _calculatedResults['C26']! /
          100000;

      setState(() {
        _isCalculated = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error al calcular. Por favor verifique los valores ingresados: ${e.toString()}')),
      );
    }
  }

  // Este método calcula los valores adicionales según las fórmulas de la imagen
  Map<String, double> _calculateAdditionalResults() {
    Map<String, double> results = Map.from(_calculatedResults);

    try {
      if (_c33Controller.text.isNotEmpty &&
          _c34Controller.text.isNotEmpty &&
          _c35Controller.text.isNotEmpty &&
          _c37Controller.text.isNotEmpty &&
          _c40Controller.text.isNotEmpty) {
        final c05 = double.parse(_c05Controller.text);
        final c28 = double.parse(_c28Controller.text);
        final c29 = double.parse(_c29Controller.text);
        final c33 = double.parse(_c33Controller.text);
        final c34 = double.parse(_c34Controller.text);
        final c35 = double.parse(_c35Controller.text);
        final c37 = double.parse(_c37Controller.text);
        final c40 = double.parse(_c40Controller.text);

        // C36 = C32 * C33 * C34 * (100%-C35)
        results['C36'] = results['C32']! * c33 * c34 * (100 - c35) / 1000000;

        // C38 = C28 * C37
        results['C38'] = c28 * c37 / 100;

        // C39 = C38 * C29
        results['C39'] = results['C38']! * c29;

        // Verificar para evitar división por cero
        if (results['C39']! > 0) {
          // C41 = (C05 * C36) / C39
          results['C41'] = (c05 * results['C36']!) / results['C39']!;

          // C42 = C40 * C39
          results['C42'] = c40 * results['C39']!;

          if (results['C36']! > 0) {
            // C43 = (C42 / C36) / 10000
            results['C43'] = (results['C42']! / results['C36']!) / 10000;

            // C44 = (C30 - C43) * C31
            results['C44'] =
                (results['C30']! - results['C43']!) * results['C31']!;

            if (results['C30']! > 0) {
              // C45 = (C44 * C29) / C30
              results['C45'] = (results['C43']! + c29) / results['C30']!;
            }
          }
        }
      }
    } catch (e) {
      print('Error en cálculos adicionales: $e');
    }

    return results;
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isNumeric = false,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF34A853),
            ),
            child: Icon(Icons.check, color: Colors.white, size: 20),
          ),
        ),
        validator: isNumeric
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                try {
                  double.parse(value);
                } catch (e) {
                  return 'Ingrese un número válido';
                }
                return null;
              }
            : (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
      ),
    );
  }

  // Modified to support offline mode
  Future<void> _guardarAforo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Asegurarse de que los cálculos básicos estén hechos
      if (!_isCalculated) {
        _calculateResults();
      }

      // Calcular las fórmulas adicionales de la imagen
      final completeResults = _calculateAdditionalResults();

      // Determinar el valor de nMarcoAforado basado en la selección
      int nMarcoAforado;
      switch (_selectedTipoMarco) {
        case '25 cm x 25 cm':
          nMarcoAforado = 0;
          break;
        case '50 cm x 50 cm':
          nMarcoAforado = 1;
          break;
        case '1 m x 1 m':
          nMarcoAforado = 2;
          break;
        default:
          nMarcoAforado = 2;
      }

      // Crear un mapa con todos los valores a actualizar
      final Map<String, dynamic> updateData = {
        'C05': double.parse(_c05Controller.text),
        'sespecies': _especiesController.text,
        'nMarcoAforado': nMarcoAforado,
        'C28': double.parse(_c28Controller.text),
        'C29': double.parse(_c29Controller.text),
        'C10': double.parse(_c10Controller.text),
        'C11': double.parse(_c11Controller.text),
        'C12': double.parse(_c12Controller.text),
        'C14': double.parse(_c14Controller.text),
        'C15': double.parse(_c15Controller.text),
        'C16': double.parse(_c16Controller.text),
      };

      // Añadir campos adicionales si están completos
      if (_c33Controller.text.isNotEmpty) {
        updateData['C33'] = double.parse(_c33Controller.text);
      }
      if (_c34Controller.text.isNotEmpty) {
        updateData['C34'] = double.parse(_c34Controller.text);
      }
      if (_c35Controller.text.isNotEmpty) {
        updateData['C35'] = double.parse(_c35Controller.text);
      }
      if (_c37Controller.text.isNotEmpty) {
        updateData['C37'] = double.parse(_c37Controller.text);
      }
      if (_c40Controller.text.isNotEmpty) {
        updateData['C40'] = double.parse(_c40Controller.text);
      }

      // Añadir todos los valores calculados al mapa de actualización
      completeResults.forEach((key, value) {
        updateData[key] = value;
      });

      // Check if online or offline
      if (_isOnline && !widget.isOffline) {
        // Online mode - update directly in Supabase
        await _supabase
            .from('dbAforos')
            .update(updateData)
            .eq('id', widget.aforoId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aforo guardado exitosamente')),
          );

          // Navegar a vista_aforo con el ID del aforo
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VistaAforo(
                aforoId: widget.aforoId,
                fincaId: widget.fincaId,
                userId: widget.userId,
              ),
            ),
          );
        }
      } else {
        // Offline mode - update locally stored aforo
        final result = await _offlineManager.updateAforoOffline(
            widget.aforoId, updateData);

        if (result['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Aforo guardado localmente. Se sincronizará cuando haya conexión.'),
                backgroundColor: Colors.blue,
              ),
            );

            // Navegar a vista_aforo con el ID del aforo y un indicador de que es offline
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VistaAforo(
                  aforoId: widget.aforoId,
                  fincaId: widget.fincaId,
                  userId: widget.userId,
                  isOffline: true,
                ),
              ),
            );
          }
        } else {
          throw Exception(result['message']);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el aforo: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'CREAR AFORO${widget.isOffline || !_isOnline ? ' (OFFLINE)' : ''}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        color: Color(0xFFE8F5E9),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Show connectivity status indicator
                      if (widget.isOffline || !_isOnline)
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
                                  'Modo sin conexión. Los datos se guardarán localmente y se sincronizarán cuando se restablezca la conexión.',
                                  style: TextStyle(color: Colors.orange[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información del Aforo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildInfoRow(
                                  'ID Aforo:', widget.aforoId.toString()),
                              _buildInfoRow(
                                  'Tipo de Aforo:',
                                  widget.nConsecutivo == 1
                                      ? 'Toda la Finca'
                                      : 'Potrero'),
                              _buildInfoRow(
                                  'Descripción:', widget.nDescripcion),
                              _buildInfoRow('Peso de la UGG (kg):',
                                  widget.C28.toString()),
                              _buildInfoRow(
                                  'Total UGG:', widget.C29.toStringAsFixed(2)),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inventario Animales',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                label: 'Peso de la UGG (kg)',
                                controller: _c28Controller,
                                isNumeric: true,
                              ),
                              _buildTextField(
                                label: 'UGG en el potrero',
                                controller: _c29Controller,
                                isNumeric: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Datos Aforo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                label: 'Área del Potrero Aforado m2',
                                controller: _c05Controller,
                                isNumeric: true,
                              ),
                              _buildTextField(
                                label: 'Especies encontradas',
                                controller: _especiesController,
                                isNumeric: false,
                              ),
                              Container(
                                margin: EdgeInsets.only(bottom: 16),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedTipoMarco,
                                  decoration: InputDecoration(
                                    labelText: 'Tipo de marco',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    suffixIcon: Container(
                                      margin: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF34A853),
                                      ),
                                      child: Icon(Icons.check,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                  items: _tiposMarco.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedTipoMarco = newValue;
                                    });
                                  },
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
                                  'PUNTO DE CORTE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                ),
                              ),
                              Text('Peso en Gramos (gr) del marco:'),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Bajo',
                                      controller: _c10Controller,
                                      isNumeric: true,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Medio',
                                      controller: _c11Controller,
                                      isNumeric: true,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Alto',
                                      controller: _c12Controller,
                                      isNumeric: true,
                                    ),
                                  ),
                                ],
                              ),
                              Text('Porcentaje en la pradera (%):'),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Bajo',
                                      controller: _c14Controller,
                                      isNumeric: true,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Medio',
                                      controller: _c15Controller,
                                      isNumeric: true,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Alto',
                                      controller: _c16Controller,
                                      isNumeric: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _calculateResults,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1B4D3E),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Ver',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      if (_isCalculated)
                        Card(
                          margin: EdgeInsets.only(top: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PUNTO DE CORTE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                ),
                                SizedBox(height: 16),
                                _buildResultRow(
                                  'Áreas',
                                  ['C18', 'C19', 'C20'],
                                  [
                                    _calculatedResults['C18'] ?? 0,
                                    _calculatedResults['C19'] ?? 0,
                                    _calculatedResults['C20'] ?? 0,
                                  ],
                                ),
                                _buildResultRow(
                                  'Áreas x peso',
                                  ['C21', 'C22', 'C23'],
                                  [
                                    _calculatedResults['C21'] ?? 0,
                                    _calculatedResults['C22'] ?? 0,
                                    _calculatedResults['C23'] ?? 0,
                                  ],
                                ),
                                Divider(),
                                _buildTotalRow('TOTAL Gr.', 'C24',
                                    _calculatedResults['C24'] ?? 0),
                                _buildTotalRow('TOTAL Kg.', 'C25',
                                    _calculatedResults['C25'] ?? 0),
                                _buildTotalRow('N° de hectáreas en pasto (Ha)',
                                    'C30', _calculatedResults['C30'] ?? 0),
                                _buildTotalRow(
                                    'Capacidad de carga actual (instantánea)',
                                    'C31',
                                    _calculatedResults['C31'] ?? 0),
                                _buildTotalRow('Aforo (Kg FV/m2)', 'C32',
                                    _calculatedResults['C32'] ?? 0),
                                Divider(height: 32),
                                Text(
                                  'DATOS ADICIONALES',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Materia seca (%)',
                                  controller: _c33Controller,
                                  isNumeric: true,
                                ),
                                _buildTextField(
                                  label: 'Aprovechamiento de la pastura (%)',
                                  controller: _c34Controller,
                                  isNumeric: true,
                                ),
                                _buildTextField(
                                  label: 'Área descubierta del potrero (%)',
                                  controller: _c35Controller,
                                  isNumeric: true,
                                ),
                                _buildTextField(
                                  label: '% MS de consumo UGG/día (%)',
                                  controller: _c37Controller,
                                  isNumeric: true,
                                ),
                                _buildTextField(
                                  label: 'Días de ocupación proyectado',
                                  controller: _c40Controller,
                                  isNumeric: true,
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _guardarAforo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1B4D3E),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: Size(double.infinity, 48),
                                  ),
                                  child: _isLoading
                                      ? CircularProgressIndicator(
                                          color: Colors.white)
                                      : Text(
                                          'Guardar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
