import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './crear_aforo.dart';

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
  List<Map<String, dynamic>> aforos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarAforos();
  }

  Future<void> _cargarAforos() async {
    try {
      final response = await _supabase
          .from('dbAforos')
          .select('id, nConsecutivo, nDescripcion, afofinca')
          .eq('afofinca', widget.fincaId);

      setState(() {
        aforos = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar los aforos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('AFOROS FINCA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    SizedBox(width: 40),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: aforos.length,
                          itemBuilder: (context, index) {
                            final aforo = aforos[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              color: Color(0xFF1B4D3E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/aforo_detalle',
                                  arguments: aforo['id'],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${aforo['nConsecutivo']}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${aforo['nDescripcion']}',
                                          style: TextStyle(color: Colors.white),
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
                          },
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
          '/crear_aforo',
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
}
