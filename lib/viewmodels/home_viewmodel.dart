import 'dart:io';
import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/contact_model.dart';
import '../repositories/preferences_repo.dart';
import '../core/background_handler.dart';

class HomeViewModel extends ChangeNotifier {
  final PreferencesRepo _repo = PreferencesRepo();
  final Telephony _telephony = Telephony.instance;
  
  List<ContactModel> _contacts = [];
  List<ContactModel> get contacts => _contacts;

  String? _selectedSoundPath;
  String? get selectedSoundPath => _selectedSoundPath;
  String get selectedSoundName => _selectedSoundPath != null 
      ? p.basename(_selectedSoundPath!) 
      : "No sound selected";

  bool _isAppEnabled = true;
  bool get isAppEnabled => _isAppEnabled;
  bool _isListening = false;
  bool get isListening => _isListening;

  Future<void> init() async {
    _contacts = await _repo.getContacts();
    _isAppEnabled = await _repo.isAppEnabled();
    notifyListeners();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted == true) {
      _startListening();
    }
  }

  void _startListening() {
    _telephony.listenIncomingSms(
      onNewMessage: backgroundMessageHandler,
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
    _isListening = true;
    notifyListeners();
  }

  Future<void> toggleAppEnabled(bool value) async {
    _isAppEnabled = value;
    await _repo.setAppEnabled(value);
    notifyListeners();
  }

  Future<void> pickSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      _selectedSoundPath = result.files.single.path;
      notifyListeners();
    }
  }

  Future<void> addContact(String number) async {
    if (number.isEmpty || _selectedSoundPath == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp3';
    final String safeLocalPath = p.join(directory.path, fileName);

    final File sourceFile = File(_selectedSoundPath!);
    await sourceFile.copy(safeLocalPath);

    final newContact = ContactModel(number: number, soundPath: safeLocalPath);
    await _repo.addContact(newContact);
    
    _contacts = await _repo.getContacts();
    _selectedSoundPath = null;
    notifyListeners();
  }

  Future<void> deleteContact(String number) async {
    await _repo.removeContact(number);
    _contacts = await _repo.getContacts();
    notifyListeners();
  }
}