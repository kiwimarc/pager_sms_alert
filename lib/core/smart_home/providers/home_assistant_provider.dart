import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../smart_home_provider.dart';

class HomeAssistantProvider implements SmartHomeProvider {
  String? _baseUrl;
  String? _token;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _baseUrl = config['url'];
    if (_baseUrl != null && _baseUrl!.endsWith('/')) {
      _baseUrl = _baseUrl!.substring(0, _baseUrl!.length - 1);
    }
    _token = config['token'];
  }

  @override
  Future<List<SmartHomeEntity>> fetchAvailableActions() async {
    if (_baseUrl == null || _token == null) return [];

    try {
      final url = Uri.parse('$_baseUrl/api/states');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data
            .where((e) {
              String id = e['entity_id'];
              return id.startsWith('script.') || 
                     id.startsWith('automation.') || 
                     id.startsWith('scene.') ||
                     id.startsWith('input_boolean.');
            })
            .map((e) => SmartHomeEntity(
              id: e['entity_id'], 
              name: e['attributes']['friendly_name'] ?? e['entity_id'],
              type: e['entity_id'].split('.')[0]
            ))
            .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      }
    } catch (e) {
      debugPrint("HA Fetch Error: $e");
    }
    return [];
  }

  @override
  Future<bool> triggerAction(String actionId) async {
    if (_baseUrl == null || _token == null) return false;

    // Logic to determine service (script.turn_on vs automation.trigger)
    String domain = actionId.split('.')[0];
    String service = 'turn_on';
    String serviceDomain = domain; 

    if (domain == 'automation') {
      service = 'trigger';
      serviceDomain = 'automation';
    }

    final apiUrl = Uri.parse('$_baseUrl/api/services/$serviceDomain/$service');
    
    try {
      final response = await http.post(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'entity_id': actionId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("HA Trigger Error: $e");
      return false;
    }
  }
}