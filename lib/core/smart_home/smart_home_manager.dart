import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/material.dart';

import 'smart_home_provider.dart';
import 'providers/home_assistant_provider.dart';

class SmartHomeManager {
  SmartHomeProvider? _provider;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('active_vendor');
    
    if (type == 'SmartHomeVendor.homeAssistant') {
      _provider = HomeAssistantProvider();
      await _provider!.initialize({
        'url': prefs.getString('ha_base_url'),
        'token': prefs.getString('ha_token'),
      });
    } 
  }

  Future<bool> triggerAlarm({String? specificEntityId}) async {
    if (_provider == null) await init();
    
    if (_provider == null) {
      debugPrint("Smart Home Provider is not configured. Skipping.");
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? localUrl = prefs.getString('ha_base_url');

    // 1. DETERMINE TARGET
    String? targetId = specificEntityId ?? prefs.getString('smarthome_target_id');
    
    if (targetId == null || targetId.isEmpty || targetId == "None") {
      debugPrint("No Smart Home Target defined.");
      return false;
    }

    // 2. SECURITY CHECK (MANDATORY)
    // We always ping the server first. If we can't reach it via socket (Local IP),
    // we assume we are on public internet and ABORT to protect the token.
    if (localUrl != null) {
      debugPrint("Security Check: Verifying local reachability to $localUrl...");
      try {
        final uri = Uri.parse(localUrl);
        final socket = await Socket.connect(
          uri.host, 
          uri.port, 
          timeout: const Duration(seconds: 2)
        );
        socket.destroy();
        debugPrint("Security Passed: Local Server found.");
      } catch (e) {
        debugPrint("SECURITY BLOCK: Server unreachable or remote. Aborting to protect keys.");
        return false;
      }
    }

    // 3. EXECUTE
    return await _provider!.triggerAction(targetId);
  }
  
  Future<List<SmartHomeEntity>> fetchOptions() async {
    if (_provider == null) await init();
    return _provider?.fetchAvailableActions() ?? [];
  }
}