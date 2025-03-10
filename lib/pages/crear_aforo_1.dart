import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrearAforo1 extends StatefulWidget {
  final int fincaId;
  final String userId;

  const CrearAforo1({
    Key? key,
    required this.fincaId,
    required this.userId,
  }) : super(key: key);

  @override
  State<CrearAforo1> createState() => _CrearAforo1State();
}

class _CrearAforo1State extends State<CrearAforo1> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRaza;
  final List<String> _tiposRaza = [
    'No lo conoce',
    'Pesada',
    'Mediana',
    'Liviana'
  ];

  final _fechaController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _pesoHembraController = TextEditingController();
  final Map<String, TextEditingController> _cantidadControllers = {};
  String? _selectedTipoConsecutivo;
  final List<String> _tiposConsecutivo = ['Toda la Finca', 'Potrero'];

  // Variables para los resultados
  double _pesoUGG = 0.0;
  double _totalUGG = 0.0;
  int _totalAnimales = 0;
  double _totalPesoKg = 0.0;
  double _totalPesoGr = 0.0;
  bool _showResults = false;

  final List<Map<String, String>> _categorias = [
    {'var': 'D09', 'name': 'Crías Hembras'},
    {'var': 'D10', 'name': 'Crías Machos'},
    {'var': 'D11', 'name': 'Hembras de Levante'},
    {'var': 'D12', 'name': 'Macho de Levante'},
    {'var': 'D13', 'name': 'Hembras de vientre'},
    {'var': 'D14', 'name': 'Machos de Ceba'},
    {'var': 'D15', 'name': 'Hembras en producción'},
    {'var': 'D16', 'name': 'Hembras secas'},
    {'var': 'D17', 'name': 'Machos reproductores'},
    {'var': 'D18', 'name': 'Toretes'},
    {'var': 'D19', 'name': 'Bueyes'},
    {'var': 'D20', 'name': 'Equinos y mulares adultos'},
    {'var': 'D21', 'name': 'Equinos y mulares jovenes'}
  ];

  @override
  void initState() {
    super.initState();
    for (var categoria in _categorias) {
      _cantidadControllers[categoria['var']!] =
          TextEditingController(text: '0');
    }
    _pesoHembraController.text = '0';
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _descripcionController.dispose();
    _pesoHembraController.dispose();
    _cantidadControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
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

  Widget _buildCategoryTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categorías de Animales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4D3E),
              ),
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Categoría')),
                  DataColumn(label: Text('Cantidad')),
                ],
                rows: _categorias.map((categoria) {
                  final controller = _cantidadControllers[categoria['var']]!;
                  return DataRow(cells: [
                    DataCell(Text(categoria['name']!)),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateUGG() {
    if (_selectedRaza == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor seleccione un tipo de raza')),
      );
      return;
    }

    // Variables ocultas
    double pesou1;
    double pesoh1;
    double factor1;
    double factor2;

    // Calcular pesou1 basado en tipo de raza
    if (_selectedRaza == 'Pesada') {
      pesou1 = 600;
    } else if (_selectedRaza == 'Liviana') {
      pesou1 = 400;
    } else {
      pesou1 = 500;
    }

    // Calcular pesoh1
    double pesoHembra = double.tryParse(_pesoHembraController.text) ?? 0;
    pesoh1 = pesoHembra == 0 ? pesou1 : pesoHembra;

    // Calcular factor1
    factor1 = pesoh1 / pesou1;

    // Calcular factor2
    factor2 = _cantidadControllers.entries.fold(0.0, (sum, entry) {
      final cantidad = double.tryParse(entry.value.text) ?? 0;
      switch (entry.key) {
        case 'D09':
        case 'D10':
          return sum + (cantidad * 0.2);
        case 'D11':
        case 'D12':
        case 'D18':
          return sum + (cantidad * 0.6);
        case 'D13':
        case 'D14':
          return sum + (cantidad * 0.7);
        case 'D15':
        case 'D16':
          return sum + cantidad;
        case 'D17':
          return sum + (cantidad * 1.2);
        case 'D19':
        case 'D20':
          return sum + (cantidad * 1.5);
        case 'D21':
          return sum + (cantidad * 0.5);
        default:
          return sum;
      }
    });

    setState(() {
      _pesoUGG = pesou1 * factor1;
      _totalUGG = factor2 * factor1;
      _totalAnimales = _cantidadControllers.values
          .map((controller) => int.tryParse(controller.text) ?? 0)
          .reduce((a, b) => a + b);
      _totalPesoKg = factor2 * factor1 * pesou1;
      _totalPesoGr = _totalPesoKg * 1000;
      _showResults = true;
    });
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType:
            hint?.contains('peso') == true || hint?.contains('0') == true
                ? TextInputType.number
                : TextInputType.text,
        inputFormatters:
            hint?.contains('peso') == true || hint?.contains('0') == true
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            if (hint?.contains('0') == true) {
              return null;
            }
            return 'Este campo es requerido';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildResultsTable() {
    if (!_showResults) return SizedBox.shrink();

    // Función para formatear números con separador de miles (punto) y decimales (coma)
    String formatNumber(double value, int decimals) {
      final formatter = NumberFormat.decimalPattern('es');
      formatter.minimumFractionDigits = decimals;
      formatter.maximumFractionDigits = decimals;
      return formatter.format(value);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4D3E),
              ),
            ),
            SizedBox(height: 16),
            Table(
              border: TableBorder.all(),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Color(0xFFE8F5E9)),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('RESULTADOS UGG',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('VALORES',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right),
                      ),
                    ),
                  ],
                ),
                _buildResultRow(
                    'Peso de la UGG (kg)', formatNumber(_pesoUGG, 0)),
                _buildResultRow('Total UGG', formatNumber(_totalUGG, 2)),
                _buildResultRow('Total Animales',
                    formatNumber(_totalAnimales.toDouble(), 0)),
                _buildResultRow('Total Peso Kg', formatNumber(_totalPesoKg, 0)),
                _buildResultRow('Total Peso gr', formatNumber(_totalPesoGr, 0)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildResultRow(String label, String value) {
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(label),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAforo() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos requeridos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Crear el mapa de datos para insertar
      final aforoData = {
        'nConsecutivo': _selectedTipoConsecutivo == 'Toda la Finca' ? 1 : 0,
        'nFecha': _fechaController.text,
        'nDescripcion': _descripcionController.text,
        'D09': int.parse(_cantidadControllers['D09']!.text),
        'D10': int.parse(_cantidadControllers['D10']!.text),
        'D11': int.parse(_cantidadControllers['D11']!.text),
        'D12': int.parse(_cantidadControllers['D12']!.text),
        'D13': int.parse(_cantidadControllers['D13']!.text),
        'D14': int.parse(_cantidadControllers['D14']!.text),
        'D15': int.parse(_cantidadControllers['D15']!.text),
        'D16': int.parse(_cantidadControllers['D16']!.text),
        'D17': int.parse(_cantidadControllers['D17']!.text),
        'D18': int.parse(_cantidadControllers['D18']!.text),
        'D19': int.parse(_cantidadControllers['D19']!.text),
        'D20': int.parse(_cantidadControllers['D20']!.text),
        'D21': int.parse(_cantidadControllers['D21']!.text),
        'C28': _pesoUGG,
        'C29': _totalUGG,
        'D25': _totalAnimales,
        'D26': _totalPesoKg,
        'D27': _totalPesoGr,
        'afofinca': widget.fincaId,
        'afouser': widget.userId,
      };

      // Insertar en la base de datos usando .select() para obtener el registro insertado
      final response = await Supabase.instance.client
          .from('dbAforos')
          .insert(aforoData)
          .select()
          .single();

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aforo guardado con éxito'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a crear_Aforo_2 con los datos necesarios
        Navigator.pushNamed(
          context,
          '/crear_aforo_2',
          arguments: {
            'fincaId': widget.fincaId,
            'userId': widget.userId,
            'aforoId': response[
                'id'], // Accedemos directamente al ID del registro insertado
            'nConsecutivo': aforoData['nConsecutivo'],
            'nDescripcion': aforoData['nDescripcion'],
            'C28': aforoData['C28'],
            'C29': aforoData['C29'],
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el aforo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'CREAR AFORO 1',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        color: Color(0xFFE8F5E9),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Datos del Aforo',
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
                                onTap: () => _selectDate(context),
                              ),
                              _buildTextField(
                                label: 'Descripción',
                                controller: _descripcionController,
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
                                'Inventario Animales',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedRaza,
                                decoration: InputDecoration(
                                  labelText: 'Tipo de Raza',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: _tiposRaza.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedRaza = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor seleccione un tipo de raza';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                label:
                                    'Peso de la hembra Adulta del Hato Kg, si no lo conoce deje 0',
                                controller: _pesoHembraController,
                                hint: 'Si no conoce el peso déjelo en 0',
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildCategoryTable(),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _calculateUGG();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1B4D3E),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Ver UGG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildResultsTable(),
                      if (_showResults) ...[
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveAforo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1B4D3E),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Continuar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
