import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './lista_aforos.dart';
import 'package:intl/intl.dart'; // Importar para el formato de números

class VistaAforo extends StatefulWidget {
  final int aforoId;
  final int? fincaId; // Nuevo parámetro opcional
  final String? userId; // Nuevo parámetro opcional

  const VistaAforo({
    Key? key,
    required this.aforoId,
    this.fincaId, // Opcional para mantener compatibilidad con usos existentes
    this.userId, // Opcional para mantener compatibilidad con usos existentes
  }) : super(key: key);

  @override
  State<VistaAforo> createState() => _VistaAforoState();
}

class _VistaAforoState extends State<VistaAforo> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic> aforoData = {};
  bool isLoading = true;
  int? fincaId; // Para almacenar el ID de la finca

  // Formato para números sin decimales
  final formatSinDecimales = NumberFormat('#,###', 'es_ES');

  // Formato para números con 2 decimales
  final formatConDecimales = NumberFormat('#,##0.00', 'es_ES');

  @override
  void initState() {
    super.initState();
    _cargarAforo();
  }

  Future<void> _cargarAforo() async {
    try {
      final response = await _supabase
          .from('dbAforos')
          .select('*, afofinca') // Agregamos afofinca a la selección
          .eq('id', widget.aforoId)
          .single();

      setState(() {
        aforoData = response;
        // Guardamos el fincaId del aforo o usamos el que se pasó como parámetro
        fincaId = widget.fincaId ?? response['afofinca'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el aforo')),
      );
    }
  }

  // Método para formatear campos numéricos con 2 decimales
  String formatoConDecimales(dynamic valor) {
    if (valor == null) return '';
    try {
      return formatConDecimales.format(double.parse(valor.toString()));
    } catch (e) {
      return valor.toString();
    }
  }

  // Método para formatear campos numéricos sin decimales
  String formatoSinDecimales(dynamic valor) {
    if (valor == null) return '';
    try {
      double numero = double.parse(valor.toString());
      return formatSinDecimales.format(numero);
    } catch (e) {
      return valor.toString();
    }
  }

  Widget _buildDataRow(String title, String value,
      {bool isHeader = false, Color? bgColor, bool conDecimales = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: bgColor,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeColumnRow(
      String title, String low, String medium, String high,
      {bool isHeader = false, Color? bgColor, bool conDecimales = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: bgColor,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              low,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              medium,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              high,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF1B4D3E),
          iconTheme: IconThemeData(color: Colors.white),
          title: Text('DETALLE DEL AFORO',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final lightGreen = Color(0xFFE8F5E9);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('DETALLE DEL AFORO',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDataRow('Id Aforo', aforoData['id'].toString(),
                          bgColor: lightGreen),
                      _buildDataRow(
                          'Tipo de Aforo', aforoData['nConsecutivo'].toString(),
                          bgColor: lightGreen),
                      _buildDataRow(
                          'Fecha de aforo:', aforoData['nFecha'] ?? '',
                          bgColor: lightGreen),
                      _buildDataRow('Área del potrero aforado (En m2):',
                          formatoSinDecimales(aforoData['C05']),
                          bgColor: lightGreen),
                      _buildDataRow('Identificación del potrero:',
                          aforoData['nDescripcion'] ?? '',
                          bgColor: lightGreen),
                      _buildDataRow(
                          'Principales especies encontradas en el potrero',
                          aforoData['sespecies'] ?? '',
                          bgColor: lightGreen),
                      _buildDataRow('Tipo de marco',
                          aforoData['nMarcoAforado']?.toString() ?? '',
                          bgColor: lightGreen),
                      SizedBox(height: 20),
                      _buildThreeColumnRow(
                          'PUNTO DE CORTE', 'Bajo', 'Medio', 'Alto',
                          isHeader: true),
                      _buildThreeColumnRow(
                          'PESO GR',
                          formatoSinDecimales(aforoData['C10']),
                          formatoSinDecimales(aforoData['C11']),
                          formatoSinDecimales(aforoData['C12']),
                          bgColor: lightGreen),
                      _buildThreeColumnRow(
                          '% En la pradera',
                          formatoSinDecimales(aforoData['C14']),
                          formatoSinDecimales(aforoData['C15']),
                          formatoSinDecimales(aforoData['C16']),
                          bgColor: lightGreen),
                      _buildThreeColumnRow(
                          'Area m2',
                          formatoSinDecimales(aforoData['C18']),
                          formatoSinDecimales(aforoData['C19']),
                          formatoSinDecimales(aforoData['C20']),
                          bgColor: lightGreen),
                      _buildThreeColumnRow(
                          'Area x peso gr.',
                          formatoSinDecimales(aforoData['C21']),
                          formatoSinDecimales(aforoData['C22']),
                          formatoSinDecimales(aforoData['C23']),
                          bgColor: lightGreen),
                      SizedBox(height: 20),
                      _buildDataRow(
                          'Total Gr', formatoSinDecimales(aforoData['C24']),
                          bgColor: lightGreen),
                      _buildDataRow(
                          'Total Kg', formatoSinDecimales(aforoData['C25']),
                          bgColor: lightGreen),
                      SizedBox(height: 20),
                      Text('CAPACIDAD PRODUCTIVA',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildDataRow('Peso de la UGG (kg)',
                          formatoConDecimales(aforoData['C28']),
                          bgColor: lightGreen),
                      _buildDataRow('N° de hectárea en pasto (Ha)',
                          formatoConDecimales(aforoData['C30']),
                          bgColor: lightGreen),
                      _buildDataRow(
                          'Capacidad de carga actual (2/3) Instantanea',
                          formatoConDecimales(aforoData['C31']),
                          bgColor: lightGreen),
                      _buildDataRow('Aforo (Kg FV/m2)',
                          formatoConDecimales(aforoData['C32']),
                          bgColor: lightGreen),
                      _buildDataRow('UGG en el potrero',
                          formatoConDecimales(aforoData['C29']),
                          bgColor: lightGreen),
                      _buildDataRow('Materia seca (%)',
                          formatoSinDecimales(aforoData['C33']),
                          bgColor: lightGreen),
                      _buildDataRow('Aprovechamiento de la pastura (%)',
                          formatoSinDecimales(aforoData['C34']),
                          bgColor: lightGreen),
                      _buildDataRow('Area descubierta del potrero (%)',
                          formatoSinDecimales(aforoData['C35']),
                          bgColor: lightGreen),
                      _buildDataRow('Kg de MS disponible por m2 (kg MS/m2)',
                          formatoConDecimales(aforoData['C36']),
                          bgColor: lightGreen),
                      _buildDataRow('% MS de consumo UGG/día (%)',
                          formatoConDecimales(aforoData['C37']),
                          bgColor: lightGreen),
                      _buildDataRow('Consumo de MS UGG/día (kg MS UGG/día)',
                          formatoConDecimales(aforoData['C38']),
                          bgColor: lightGreen),
                      _buildDataRow('Consumo total de MS UGG día (kg/día)',
                          formatoConDecimales(aforoData['C39']),
                          bgColor: lightGreen),
                      _buildDataRow('Días de ocupación proyectado',
                          formatoConDecimales(aforoData['C40']),
                          bgColor: lightGreen),
                      _buildDataRow('Días de ocupación sugeridos',
                          formatoConDecimales(aforoData['C41']),
                          bgColor: lightGreen),
                      _buildDataRow(
                          'Consumo total de MS UGG por Ocupación (kg/MS)',
                          formatoConDecimales(aforoData['C42']),
                          bgColor: lightGreen),
                      _buildDataRow('Ha necesarias',
                          formatoConDecimales(aforoData['C43']),
                          bgColor: lightGreen),
                      _buildDataRow('Ajuste de UGG',
                          formatoConDecimales(aforoData['C44']),
                          bgColor: lightGreen),
                      _buildDataRow(
                          'Carga final', formatoConDecimales(aforoData['C45']),
                          bgColor: lightGreen),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Botón Volver
              Container(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    if (fincaId != null && widget.userId != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListaAforos(
                            fincaId: fincaId!,
                            userId: widget.userId!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B4D3E),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 48),
                  ),
                  child: Text(
                    'Volver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
