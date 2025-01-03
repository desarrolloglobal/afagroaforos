import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CrearAforo extends StatefulWidget {
  final int fincaId;
  final String userId;

  const CrearAforo({
    Key? key,
    required this.fincaId,
    required this.userId,
  }) : super(key: key);

  @override
  State<CrearAforo> createState() => _CrearAforoState();
}

class _CrearAforoState extends State<CrearAforo> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isCalculated = false; // Agregar esta línea
  Map<String, double> _calculatedResults = {};
  // Form controllers
  final _fechaController = TextEditingController();
  final _descripcionController = TextEditingController();

  String? _selectedTipoConsecutivo;
  final List<String> _tiposConsecutivo = [
    'Toda la Finca',
    'Potrero'
  ]; // Order matches 0/1 values
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
    _selectedTipoConsecutivo =
        _tiposConsecutivo[1]; // Default to "Potrero" (value 1)
    _fechaController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _descripcionController.dispose();
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
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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

  void _calculateResults() {
    if (!_formKey.currentState!.validate()) return;

    final c05 = double.parse(_c05Controller.text);
    final c10 = double.parse(_c10Controller.text);
    final c11 = double.parse(_c11Controller.text);
    final c12 = double.parse(_c12Controller.text);
    final c14 = double.parse(_c14Controller.text);
    final c15 = double.parse(_c15Controller.text);
    final c16 = double.parse(_c16Controller.text);
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

    // Calculations based on Image 2
    _calculatedResults = {
      'C18': c05 * c14 / 100,
      'C19': c05 * c15 / 100,
      'C20': c05 * c16 / 100,
      'C21': c05 * c14 * c10 / 100,
      'C22': c05 * c15 * c11 / 100,
      'C23': c05 * c16 * c12 / 100,
      'C24': ((c05 * c14 * c10) + (c05 * c15 * c11) + (c05 * c16 * c12)) / 100,
    };

    // Additional calculations
    _calculatedResults['C25'] = _calculatedResults['C24']! / 1000;
    _calculatedResults['C26'] = marcoMultiplicador.toDouble();
    _calculatedResults['C30'] = c05 / 10000;
    _calculatedResults['C31'] = c29 / (_calculatedResults['C30']!);
    _calculatedResults['C32'] = ((c10 * c14) + (c11 * c15) + (c12 * c16)) *
        _calculatedResults['C26']! /
        100000;

    setState(() {
      _isCalculated = true;
    });
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
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            },
      ),
    );
  }

  Future<void> _guardarAforo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Determine el valor de nMarcoAforado basado en la selección
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

      // Get consecutivo value directly from tipo selection (0 for 'Toda la Finca', 1 for 'Potrero')
      int consecutivo = _tiposConsecutivo.indexOf(_selectedTipoConsecutivo!);

      await _supabase.from('dbAforos').insert({
        'afouser': widget.userId,
        'afofinca': widget.fincaId,
        'nConsecutivo': consecutivo,
        'nFecha': _fechaController.text,
        'nDescripcion': _descripcionController.text,
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
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aforo guardado exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el aforo')),
      );
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
          'CREAR AFORO',
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Image.asset(
                          'assets/images/afagro_logo.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
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
                              Container(
                                margin: EdgeInsets.only(bottom: 16),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedTipoConsecutivo,
                                  decoration: InputDecoration(
                                    labelText: 'Tipo de Aforo',
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
                                  items: _tiposConsecutivo.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedTipoConsecutivo = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor seleccione un tipo de aforo';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              _buildTextField(
                                label: 'Fecha aforo',
                                controller: _fechaController,
                                readOnly: true,
                                onTap: _selectDate,
                              ),
                              _buildTextField(
                                label: 'Descripción',
                                controller: _descripcionController,
                              ),
                              _buildTextField(
                                label: 'Área del Potrero Aforado m2',
                                controller: _c05Controller,
                                isNumeric: true,
                              ),
                              _buildTextField(
                                label: 'Especies encontradas',
                                controller: _especiesController,
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
                      // Agregar esta sección de resultados
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
// First row - Areas
                                _buildResultRow(
                                  'Áreas',
                                  ['C18', 'C19', 'C20'],
                                  [
                                    _calculatedResults['C18'] ?? 0,
                                    _calculatedResults['C19'] ?? 0,
                                    _calculatedResults['C20'] ?? 0,
                                  ],
                                ),
                                // Second row - Areas x peso
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
                                // Total results
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
