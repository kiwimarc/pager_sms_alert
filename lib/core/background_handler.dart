import 'dart:convert';
import 'dart:io';
import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  String sender = message.address ?? "";
  print("DEBUG: SMS Received from $sender");

  final prefs = await SharedPreferences.getInstance();

  // 1. CHECK MASTER SWITCH
  bool isEnabled = prefs.getBool('app_enabled') ?? true;
  if (!isEnabled) {
    print("App disabled. Ignoring.");
    return;
  }

  // 2. CHECK CONTACT LIST
  final String? jsonString = prefs.getString('priority_contacts_v3');
  if (jsonString != null) {
    List<dynamic> decoded = jsonDecode(jsonString);
    
    // Find match
    var match;
    try {
      match = decoded.firstWhere(
        (c) {
          // CONVERT BOTH TO LOWERCASE BEFORE COMPARING
          String incoming = sender.toLowerCase();
          String saved = c['number'].toString().toLowerCase();
          
          return incoming.contains(saved);
        }, 
        orElse: () => null
      );
    } catch (e) { match = null; }

    if (match != null) {
      String soundPath = match['soundPath'];
      
      // RESET STOP SIGNAL BEFORE STARTING
      await prefs.setBool('stop_alarm_signal', false);
      
      print("Pager Alert! Playing: $soundPath");
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
      usage: AndroidAudioUsage.alarm, // <--- CRITICAL
    ),
  ));

  try {
    final file = File(filePath);
    if (await file.exists()) {
      await player.setFilePath(filePath);
      player.play(); // Start playing

      // SMART LOOP: Check for STOP signal every 500ms
      // Max duration: 60 checks * 500ms = 30 seconds
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      
      for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check if Stop Button was pressed
        bool stopNow = prefs.getBool('stop_alarm_signal') ?? false;
        if (stopNow) {
          print("Stop signal received. Killing audio.");
          break;
        }

        // Check if audio finished naturally
        if (player.processingState == ProcessingState.completed) {
          break;
        }
      }
      await player.stop();
    }
  } catch (e) {
    print("Audio Error: $e");
  } finally {
    await player.dispose();
  }
}