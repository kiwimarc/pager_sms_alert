import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';

class PreferencesRepo {
  static const String keyContacts = 'priority_contacts_v3';
  static const String keyAppEnabled = 'app_enabled';

  // --- CONTACTS ---
  Future<List<ContactModel>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(keyContacts);
    if (jsonString == null) return [];
    List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => ContactModel.fromJson(e)).toList();
  }

  Future<void> addContact(ContactModel contact) async {
    List<ContactModel> current = await getContacts();
    current.removeWhere((c) => c.number == contact.number);
    current.add(contact);
    await _saveList(current);
  }

  Future<void> removeContact(String number) async {
    List<ContactModel> current = await getContacts();
    current.removeWhere((c) => c.number == number);
    await _saveList(current);
  }

  Future<void> _saveList(List<ContactModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(keyContacts, jsonString);
  }

  // --- MASTER TOGGLE ---
  Future<bool> isAppEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyAppEnabled) ?? true;
  }

  Future<void> setAppEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAppEnabled, value);
  }

}