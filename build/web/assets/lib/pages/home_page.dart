import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_state_manager.dart';
import 'crear_fincas.dart';
import 'lista_aforos.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = '';
  List<Map<String, dynamic>> fincas = [];
  int authorizedFarms = 0;
  final stateManager = OfflineStateManager();

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    stateManager.setUserId(user!.id);
    await _loadUserData();
    await _loadFincas();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final response = await Supabase.instance.client
        .from('users')
        .select('name, nofincas')
        .eq('id', user.id)
        .single();

    setState(() {
      userName = response['name'] ?? 'Usuario';
      authorizedFarms = response['nofincas'] ?? 0;
    });
  }

  Future<void> _loadFincas() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final response = await Supabase.instance.client
        .from('dbfincas')
        .select('id, s_nombrefinca, s_legal')
        .eq('iduser', user.id);

    setState(() {
      fincas = List<Map<String, dynamic>>.from(response);
    });
  }

  void _navigateToListaAforos(Map<String, dynamic> finca) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    stateManager.setUserId(userId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaAforos(
          fincaId: finca['id'],
          userId: userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFarms = fincas.length;
    final canCreateFarm = currentFarms < authorizedFarms;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        title: Text('FINCAS',
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
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/images/afagro_logo.png', height: 70),
                      SizedBox(width: 8),
                      Text(
                        'Bienvenido: $userName',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Fincas permitidas: $authorizedFarms',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      Text(
                        'Fincas actuales: $currentFarms',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Text('ID finca',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text('Nombre de la finca',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text('Propietario',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: fincas.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        color: Color(0xFF1B4D3E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _navigateToListaAforos(fincas[index]),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fincas[index]['id'].toString() ?? '',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    fincas[index]['s_nombrefinca'] ?? '',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    fincas[index]['s_legal'] ?? '',
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
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton(
                      onPressed: canCreateFarm
                          ? () async {
                              final stateManager = OfflineStateManager();
                              final user =
                                  Supabase.instance.client.auth.currentUser;
                              if (user != null) {
                                stateManager.setUserId(user.id);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CrearFincasPage(),
                                  ),
                                );
                                if (result == true) {
                                  _loadFincas();
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCreateFarm
                            ? Color(0xFF34A853)
                            : Colors.grey[350],
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Agregar una Finca ',
                              style: TextStyle(
                                  color: canCreateFarm
                                      ? Colors.white
                                      : Colors.grey)),
                          Icon(Icons.add,
                              color:
                                  canCreateFarm ? Colors.white : Colors.grey),
                        ],
                      ),
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
}
