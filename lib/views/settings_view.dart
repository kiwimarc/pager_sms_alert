import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // HA Controllers
  late TextEditingController _haUrlController;
  late TextEditingController _haTokenController;

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<HomeViewModel>(context, listen: false);
    _haUrlController = TextEditingController(text: vm.baseUrl);
    _haTokenController = TextEditingController(text: vm.token);
  }

  @override
  void dispose() {
    _haUrlController.dispose();
    _haTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HomeViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Integrations", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // INFO CARD
          _buildInfoCard(),
          const SizedBox(height: 20),
          
          const Text("SELECT ACTIVE PROVIDER", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),

          // --- OPTION 1: NONE ---
          _buildVendorCard(
            context,
            vm,
            type: SmartHomeVendor.none,
            title: "No Integration",
            icon: Icons.notifications_off_outlined,
            color: Colors.grey,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Smart home triggers will be disabled. You will receive sound alerts only.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          // --- OPTION 2: HOME ASSISTANT ---
          _buildVendorCard(
            context,
            vm,
            type: SmartHomeVendor.homeAssistant,
            title: "Home Assistant",
            icon: Icons.home_filled,
            color: Colors.blue,
            subtitle: vm.baseUrl != null ? "Configured" : "Setup Required",
            child: Column(
              children: [
                TextField(
                  controller: _haUrlController,
                  decoration: InputDecoration(
                    labelText: "Local Server URL",
                    hintText: "http://192.168.1.X:8123",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.link),
                    helperText: "Must be a local IP address",
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _haTokenController,
                  decoration: InputDecoration(
                    labelText: "Long-Lived Access Token",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.key),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      vm.saveSettings(_haUrlController.text, _haTokenController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Home Assistant Saved & Connected")),
                      );
                      // Note: saveSettings automatically sets active vendor to Home Assistant
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("Save Configuration"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
              ],
            ),
          ),

          // --- OPTION 3: PHILIPS HUE ---
          _buildVendorCard(
            context,
            vm,
            type: SmartHomeVendor.philipsHue,
            title: "Philips Hue",
            icon: Icons.lightbulb,
            color: Colors.orange,
            subtitle: "Coming Soon",
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Hue Bridge discovery will be added in a future update.",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildVendorCard(
    BuildContext context, 
    HomeViewModel vm, 
    {
      required SmartHomeVendor type,
      required String title,
      required IconData icon,
      required Color color,
      required Widget child,
      String? subtitle,
    }) {
    
    final bool isSelected = vm.activeVendor == type;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: ExpansionTile(
        // Force expansion if this is the selected vendor
        initiallyExpanded: isSelected,
        
        // The Radio Button is the Leading Widget
        leading: Radio<SmartHomeVendor>(
          value: type,
          groupValue: vm.activeVendor,
          activeColor: color,
          onChanged: (SmartHomeVendor? value) {
            if (value != null) vm.setActiveVendor(value);
          },
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey.shade700
          )
        ),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Select a provider below. Only one smart home system can be active at a time.",
              style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
            ),
          )
        ],
      ),
    );
  }
}