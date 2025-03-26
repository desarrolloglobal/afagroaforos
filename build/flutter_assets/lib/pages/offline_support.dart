import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OfflineSupport {
  static Future<Map<String, dynamic>> saveTablesLocally() async {
    try {
      final encuestasResponse =
          await Supabase.instance.client.from('dbEncuestas').select();
      final preguntasResponse =
          await Supabase.instance.client.from('dbPreguntas').select();
      final fincasResponse =
          await Supabase.instance.client.from('dbfincas').select();

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('dbEncuestas', json.encode(encuestasResponse));
      await prefs.setString('dbPreguntas', json.encode(preguntasResponse));
      await prefs.setString('dbfincas', json.encode(fincasResponse));

      return {
        'success': true,
        'message': 'Tablas guardadas con éxito en tu dispositivo'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error al guardar las tablas: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final encuestasData = prefs.getString('dbEncuestas');
    final preguntasData = prefs.getString('dbPreguntas');
    final fincasData = prefs.getString('dbfincas');

    return {
      'dbEncuestas': encuestasData != null ? json.decode(encuestasData) : null,
      'dbPreguntas': preguntasData != null ? json.decode(preguntasData) : null,
      'dbfincas': fincasData != null ? json.decode(fincasData) : null,
    };
  }

  static Future<bool> updateLocalData(
      String tableName, List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tableName, json.encode(data));
      return true;
    } catch (e) {
      print('Error al actualizar datos locales: $e');
      return false;
    }
  }

  static Future<bool> saveResponseLocally(Map<String, dynamic> response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> offlineResponses =
          prefs.getStringList('offlineResponses') ?? [];
      offlineResponses.add(json.encode(response));
      await prefs.setStringList('offlineResponses', offlineResponses);
      return true;
    } catch (e) {
      print('Error al guardar respuesta localmente: $e');
      return false;
    }
  }

  static Future<bool> syncOfflineResponses() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineResponses =
        prefs.getStringList('offlineResponses') ?? [];

    if (offlineResponses.isEmpty) return true;

    try {
      for (String responseStr in offlineResponses) {
        Map<String, dynamic> response = json.decode(responseStr);

        // Procesar campos específicos
        response = _processResponse(response);

        // Asegurarse de que iduser está presente
        if (!response.containsKey('iduser')) {
          String? idUser = await prefs.getString('idUser');
          if (idUser != null) {
            response['iduser'] = idUser;
          }
        }

        // Insertar en dbRespuestas
        await Supabase.instance.client.from('dbRespuestas').insert(response);

        // Actualizar dbfincas
        //await _updateDbFincas(response);
      }

      // Clear offline responses after successful sync
      await prefs.setStringList('offlineResponses', []);
      return true;
    } catch (e) {
      print('Error al sincronizar respuestas: $e');
      return false;
    }
  }

  static Future<void> updateDbFincas(
      int knumero, Map<String, dynamic> updateData) async {
    try {
      // Actualizar en Supabase
      await Supabase.instance.client
          .from('dbfincas')
          .update(updateData)
          .eq('knumero', knumero);

      // Actualizar localmente
      final prefs = await SharedPreferences.getInstance();
      final localData = json.decode(prefs.getString('dbfincas') ?? '[]');

      final index = localData.indexWhere((item) => item['knumero'] == knumero);
      if (index != -1) {
        localData[index] = {...localData[index], ...updateData};
      } else {
        localData.add({'knumero': knumero, ...updateData});
      }

      await prefs.setString('dbfincas', json.encode(localData));
    } catch (e) {
      print('Error al actualizar dbfincas: $e');
      throw e;
    }
  }

  static Map<String, dynamic> _processResponse(Map<String, dynamic> response) {
    // Procesar arrays
    if (response.containsKey('stlargo') && response['stlargo'] is String) {
      response['stlargo'] = json.decode(response['stlargo']);
    }
    if (response.containsKey('stlargo2') && response['stlargo2'] is String) {
      response['stlargo2'] = json.decode(response['stlargo2']);
    }

    // Procesar fechas
    if (response.containsKey('ffecha') && response['ffecha'] is String) {
      response['ffecha'] =
          DateTime.parse(response['ffecha']).toUtc().toIso8601String();
    }
    if (response.containsKey('ffecha2') && response['ffecha2'] is String) {
      response['ffecha2'] =
          DateTime.parse(response['ffecha2']).toUtc().toIso8601String();
    }

    // Procesar booleanos
    if (response.containsKey('bsino') && response['bsino'] is String) {
      response['bsino'] = response['bsino'].toLowerCase() == 'true';
    }

    // Procesar números
    if (response.containsKey('nnumero') && response['nnumero'] is String) {
      response['nnumero'] = double.tryParse(response['nnumero']) ?? 0;
    }
    if (response.containsKey('nnumero2') && response['nnumero2'] is String) {
      response['nnumero2'] = double.tryParse(response['nnumero2']) ?? 0;
    }

    return response;
  }
}
