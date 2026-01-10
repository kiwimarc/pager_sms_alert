import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart';

import '../models/home_contact.dart'; 
import '../core/smart_home/smart_home_provider.dart'; 
import '../core/smart_home/smart_home_manager.dart'; 
import '../core/background_handler.dart';

// Enum to manage which integration is currently active
enum SmartHomeVendor { none, homeAssistant, philipsHue }

class HomeViewModel extends ChangeNotifier {
  // --- STATE VARIABLES ---
  List<HomeContact> _contacts = [];
  bool _isAppEnabled = true;
  String? _selectedSoundPath;
  bool _isLoadingEntities = false;

  // --- SETTINGS & SMART HOME VARIABLES ---
  SmartHomeVendor _activeVendor = SmartHomeVendor.none;
  String? _baseUrl;
  String? _token;
  List<SmartHomeEntity> _availableEntities = [];
  String? _tempSelectedEntityId;

  // --- GETTERS ---
  List<HomeContact> get contacts => _contacts;
  bool get isAppEnabled => _isAppEnabled;
  SmartHomeVendor get activeVendor => _activeVendor;
  
  String? get selectedSoundPath => _selectedSoundPath;
  String get selectedSoundName => _selectedSoundPath != null 
      ? p.basename(_selectedSoundPath!) 
      : "Select Ringtone";

  String? get baseUrl => _baseUrl;
  String? get token => _token;
  List<SmartHomeEntity> get availableEntities => _availableEntities;
  bool get isLoadingEntities => _isLoadingEntities;
  String? get tempSelectedEntityId => _tempSelectedEntityId;

  // --- INITIALIZATION ---
  Future<void> init() async {
    // 1. Load Data
    await _loadSettings();
    await _loadContacts();

    // 2. Request Permissions
    await _requestPermissions();

    // 3. Start Listener
    _initTelephonyListener();

    // 4. Fetch External Data (Dynamic based on active vendor)
    refreshIntegration();
  }

  /// Central method to handle data fetching based on the chosen vendor
  Future<void> refreshIntegration() async {
    // Clear old data to prevent confusion in UI
    _availableEntities = [];
    notifyListeners();

    switch (_activeVendor) {
      case SmartHomeVendor.homeAssistant:
        if (_baseUrl != null && _token != null) {
          await fetchHomeAssistantEntities();
        }
        break;

      case SmartHomeVendor.philipsHue:
        // Placeholder for future logic
        debugPrint("Philips Hue selected - logic pending.");
        break;

      case SmartHomeVendor.none:
      default:
        // Do nothing
        break;
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.notification,
    ].request();

    if (statuses[Permission.sms]?.isDenied ?? true) {
      debugPrint("PAGER WARNING: SMS permission denied.");
    }
  }

  void _initTelephonyListener() {
    try {
      Telephony.instance.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          debugPrint("FOREGROUND SMS: ${message.body}");
          backgroundMessageHandler(message);
        },
        onBackgroundMessage: backgroundMessageHandler,
        listenInBackground: true,
      );
    } catch (e) {
      debugPrint("PAGER ERROR: Could not start SMS listener: $e");
    }
  }

  // --- LOGIC: CONTACTS ---
  
  Future<void> pickSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      _selectedSoundPath = result.files.single.path;
      notifyListeners();
    }
  }

  Future<void> addContact(String number) async {
    if (_selectedSoundPath == null) return;

    // 1. Safe File Path (prevent overwrites)
    final appDir = await getApplicationDocumentsDirectory();
    final String extension = p.extension(_selectedSoundPath!);
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
    final String safeLocalPath = '${appDir.path}/$fileName';

    // 2. Copy File
    await File(_selectedSoundPath!).copy(safeLocalPath);

    // 3. Resolve Smart Home Name
    String? entityName;
    if (_tempSelectedEntityId != null && _availableEntities.isNotEmpty) {
      try {
        entityName = _availableEntities.firstWhere((e) => e.id == _tempSelectedEntityId).name;
      } catch (_) {
        entityName = null;
      }
    }

    // 4. Create & Save
    final newContact = HomeContact(
      number,
      safeLocalPath,
      entityId: _tempSelectedEntityId,
      entityName: entityName,
    );

    _contacts.add(newContact);
    await _saveContacts();

    // 5. Reset UI State
    _selectedSoundPath = null;
    _tempSelectedEntityId = null;
    notifyListeners();
  }

  Future<void> deleteContact(String number) async {
    _contacts.removeWhere((c) => c.number == number);
    await _saveContacts();
    notifyListeners();
  }

  // --- LOGIC: SETTINGS & TOGGLES ---

  void setTempEntity(String? id) {
    _tempSelectedEntityId = id;
    notifyListeners();
  }

  Future<void> toggleAppEnabled(bool value) async {
    _isAppEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_enabled', value);
    notifyListeners();
  }

  /// Sets the active vendor and saves it to preferences
  Future<void> setActiveVendor(SmartHomeVendor vendor) async {
    _activeVendor = vendor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_vendor', vendor.toString());
    
    // Refresh integration to load/unload data immediately
    refreshIntegration();
    notifyListeners();
  }

  Future<void> saveSettings(String url, String token) async {
    final prefs = await SharedPreferences.getInstance();
    String cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    // Save to Disk
    await prefs.setString('ha_base_url', cleanUrl);
    await prefs.setString('ha_token', token.trim());
    
    // Update Memory
    _baseUrl = cleanUrl;
    _token = token.trim();
    
    await setActiveVendor(SmartHomeVendor.homeAssistant);
    
  }

  Future<void> fetchHomeAssistantEntities() async {
    // 1. Basic Validation
    if (_baseUrl == null || _token == null) {
      debugPrint("PAGER ERROR: Cannot fetch entities. Missing URL or Token.");
      return;
    }
    
    _isLoadingEntities = true;
    notifyListeners();

    try {
      debugPrint("PAGER: Fetching HA entities from $_baseUrl...");
      
      final manager = SmartHomeManager();
      // Ensure your Manager reads the 'ha_base_url' and 'ha_token' keys correctly!
      final results = await manager.fetchOptions();
      
      if (results.isEmpty) {
        debugPrint("PAGER WARNING: Connection successful, but 0 entities were found.");
      } else {
        debugPrint("PAGER SUCCESS: Found ${results.length} entities.");
      }

      _availableEntities = results;
      
    } catch (e) {
      // 2. Log the EXACT error
      debugPrint("PAGER ERROR: Failed to fetch entities -> $e");
      
      // Optional: Clear the list on error so users don't see stale data
      _availableEntities = []; 
      
    } finally {
      _isLoadingEntities = false;
      notifyListeners();
    }
  }

  // --- DATA PERSISTENCE (PRIVATE) ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isAppEnabled = prefs.getBool('app_enabled') ?? true;
    _baseUrl = prefs.getString('ha_base_url');
    _token = prefs.getString('ha_token');

    // Load Vendor selection
    final savedVendor = prefs.getString('active_vendor');
    if (savedVendor != null) {
      _activeVendor = SmartHomeVendor.values.firstWhere(
        (e) => e.toString() == savedVendor, 
        orElse: () => SmartHomeVendor.none
      );
    }
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString('priority_contacts_v3');
    if (contactsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        _contacts = decoded.map((e) => HomeContact.fromJson(e)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint("Error parsing contacts: $e");
      }
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_contacts.map((e) => e.toJson()).toList());
    await prefs.setString('priority_contacts_v3', encoded);
  }
}