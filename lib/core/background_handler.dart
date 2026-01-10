import 'dart:convert';
import 'dart:io';
import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';

import 'smart_home/smart_home_manager.dart'; 

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  String sender = message.address ?? "";
  debugPrint("SMS Received from $sender");

  final prefs = await SharedPreferences.getInstance();

  // 1. CHECK MASTER SWITCH
  bool isEnabled = prefs.getBool('app_enabled') ?? true;
  if (!isEnabled) {
    debugPrint("App disabled. Ignoring message.");
    return;
  }

  // 2. CHECK CONTACT LIST
  final String? jsonString = prefs.getString('priority_contacts_v3');
  if (jsonString != null) {
    List<dynamic> decoded = jsonDecode(jsonString);
    
    // Find match (Case insensitive)
    var match;
    try {
      match = decoded.firstWhere(
        (c) {
          String incoming = sender.toLowerCase();
          String saved = c['number'].toString().toLowerCase();
          return incoming.contains(saved);
        }, 
        orElse: () => null
      );
    } catch (e) { match = null; }

    if (match != null) {
      debugPrint("Matched Priority Contact: ${match['number']}");

      // --- STEP A: TRIGGER SMART HOME ---
      try {
        final smartHome = SmartHomeManager();
        String? contactEntityId = match['entityId']; 
        
        debugPrint("Triggering Smart Home Action (Target: ${contactEntityId ?? 'Default'})...");
        
        // We don't await this indefinitely so it doesn't delay the sound
        smartHome.triggerAlarm(specificEntityId: contactEntityId).then((success) {
           debugPrint("Smart Home Result: $success");
        });
      } catch (e) {
        debugPrint("Smart Home Error: $e");
      }

      // --- STEP B: PLAY AUDIO ---
      String soundPath = match['soundPath'];
      
      // Reset stop signal so previous clicks don't kill this new alarm immediately
      await prefs.setBool('stop_alarm_signal', false);
      
      debugPrint("Starting Audio Alert: $soundPath");
      await _playLocalAlarm(soundPath);
    }
  }
}

Future<void> _playLocalAlarm(String filePath) async {
  final player = AudioPlayer();
  final session = await AudioSession.instance;

  // CONFIGURE AS ALARM TO BYPASS SILENT MODE
  await session.configure(const AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    androidAudioAttributes: AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      flags: AndroidAudioFlags.audibilityEnforced,
      usage: AndroidAudioUsage.alarm, 
    ),
  ));

  try {
    final file = File(filePath);
    if (await file.exists()) {
      await player.setFilePath(filePath);
      player.play();
      
      // Check every 500ms for 30 seconds (60 checks)
      for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if audio finished naturally
        if (player.processingState == ProcessingState.completed) {
          break;
        }

      }
      await player.stop();
    } else {
      debugPrint("Error: Sound file not found at $filePath");
    }
  } catch (e) {
    debugPrint("Audio Player Error: $e");
  } finally {
    await player.dispose();
  }
}