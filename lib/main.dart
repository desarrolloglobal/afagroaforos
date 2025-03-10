import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/crear_aforo_1.dart';
import 'pages/crear_aforo_2.dart';
import 'pages/vista_aforo.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    await initializeDateFormatting('es');

    await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
        debug: true);

    await SharedPreferences.getInstance();
    runApp(MyApp());
  } catch (e) {
    print('Error en la inicialización: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encuesta Global',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/crear_aforo_1': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return CrearAforo1(
            fincaId: args['fincaId'],
            userId: args['userId'],
          );
        },
        '/crear_aforo_2': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return CrearAforo(
            fincaId: args['fincaId'],
            userId: args['userId'],
            aforoId: args['aforoId'],
            nConsecutivo: args['nConsecutivo'],
            nDescripcion: args['nDescripcion'],
            C28: args['C28'],
            C29: args['C29'],
          );
        },
        '/vista_aforo': (context) {
          final Map<String, dynamic> args = ModalRoute.of(context)
              ?.settings
              .arguments as Map<String, dynamic>;
          return VistaAforo(
            aforoId: args['aforoId'],
            fincaId: args['fincaId'],
            userId: args['userId'],
          );
        },
      },
    );
  }
}
