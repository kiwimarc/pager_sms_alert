import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import 'settings_view.dart';
import 'package:path/path.dart' as p;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<HomeViewModel>(context, listen: false).init()
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);
    final primaryColor = viewModel.isAppEnabled ? const Color(0xFF006400) : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context, viewModel, primaryColor),
      body: Column(
        children: [
          _buildStatusHeader(viewModel, primaryColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputCard(context, viewModel, primaryColor),
                  const SizedBox(height: 30),
                  const Text("ACTIVE WATCHLIST", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildContactList(viewModel, primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- EXTRACTED WIDGETS ---

  PreferredSizeWidget _buildAppBar(BuildContext context, HomeViewModel vm, Color color) {
    return AppBar(
      elevation: 0,
      backgroundColor: color,
      centerTitle: true,
      title: const Text("PAGER ALERT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.settings, color: Colors.white),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView())),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Switch(
            value: vm.isAppEnabled,
            onChanged: vm.toggleAppEnabled,
            activeColor: Colors.white,
            activeTrackColor: Colors.lightGreenAccent,
            inactiveThumbColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(HomeViewModel vm, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Icon(vm.isAppEnabled ? Icons.wifi_tethering : Icons.wifi_tethering_off, size: 40, color: Colors.white.withOpacity(0.9)),
          const SizedBox(height: 10),
          Text(vm.isAppEnabled ? "SYSTEM ACTIVE" : "SYSTEM DISABLED", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildInputCard(BuildContext context, HomeViewModel vm, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: "Sender Name or Number",
              prefixIcon: const Icon(Icons.person_add_alt_1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          // Sound Picker
          OutlinedButton.icon(
            onPressed: vm.pickSound,
            icon: const Icon(Icons.music_note),
            label: Text(vm.selectedSoundPath == null ? "Select Ringtone" : "Sound Selected"),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
          ),
          const SizedBox(height: 10),
          // Smart Home Dropdown
          if (vm.activeVendor != SmartHomeVendor.none) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: vm.tempSelectedEntityId,
                hint: const Text("Link Smart Action (Optional)"),
                items: [
                  const DropdownMenuItem(value: null, child: Text("No Automation")),
                  ...vm.availableEntities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))),
                ],
                onChanged: (val) => vm.setTempEntity(val),
              ),
            ),
          ),
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (vm.selectedSoundPath == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a sound first")));
                  return;
                }
                vm.addContact(_controller.text);
                _controller.clear();
                FocusScope.of(context).unfocus();
              },
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
              child: const Text("Save to Watchlist"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContactList(HomeViewModel vm, Color primaryColor) {
    if (vm.contacts.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.notifications_off_outlined, size: 40, color: Colors.grey.shade300),
            const Text("No priority contacts yet", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemCount: vm.contacts.length,
        itemBuilder: (context, index) {
          final contact = vm.contacts[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: primaryColor.withOpacity(0.1), child: Icon(Icons.priority_high, color: primaryColor)),
              title: Text(contact.number, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🎵 ${p.basename(contact.soundPath)}"),
                  if (contact.entityName != null) Text("🏠 Triggers: ${contact.entityName}", style: const TextStyle(color: Colors.blue, fontSize: 12)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => vm.deleteContact(contact.number),
              ),
            ),
          );
        },
      ),
    );
  }
}