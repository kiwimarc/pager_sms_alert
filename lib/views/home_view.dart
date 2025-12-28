import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
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

    // Modern Color Palette
    final primaryColor = viewModel.isAppEnabled ? const Color(0xFF006400) : Colors.grey.shade700; // Dark Green vs Grey
    const accentColor =  Color(0xFFD32F2F); // Red for delete/alert

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light Grey Background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          "PAGER ALERT",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
        ),
        actions: [
          // Elegant Toggle Switch
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Switch(
              value: viewModel.isAppEnabled,
              onChanged: (val) => viewModel.toggleAppEnabled(val),
              activeColor: Colors.white,
              activeTrackColor: Colors.lightGreenAccent,
              inactiveThumbColor: Colors.grey,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // STATUS HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  viewModel.isAppEnabled ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                  size: 40,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 10),
                Text(
                  viewModel.isAppEnabled ? "SYSTEM ACTIVE" : "SYSTEM DISABLED",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  viewModel.isAppEnabled 
                    ? "Ready to override silent mode for priority contacts."
                    : "You will not receive audio alerts.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ADD NEW PRIORITY",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  
                  // MODERN INPUT CARD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          keyboardType: TextInputType.text, // Changed to text to allow names like "Dispatch"
                          decoration: InputDecoration(
                            labelText: "Sender Name or Number",
                            hintText: "e.g. Dispatch or 12345678",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.person_add_alt_1),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: viewModel.pickSound,
                                icon: const Icon(Icons.music_note),
                                label: Text(
                                  viewModel.selectedSoundPath == null ? "Select Ringtone" : "Sound Selected",
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton.small(
                              onPressed: () {
                                if (viewModel.selectedSoundPath == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a sound file first.")));
                                  return;
                                }
                                viewModel.addContact(_controller.text);
                                _controller.clear();
                                FocusScope.of(context).unfocus(); // Close keyboard
                              },
                              backgroundColor: primaryColor,
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                          ],
                        ),
                        if (viewModel.selectedSoundPath != null)
                           Padding(
                             padding: const EdgeInsets.only(top: 8.0),
                             child: Text(
                               "Selected: ${viewModel.selectedSoundName}",
                               style: const TextStyle(fontSize: 12, color: Colors.green),
                             ),
                           ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "ACTIVE WATCHLIST",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  // CONTACT LIST
                  Expanded(
                    child: viewModel.contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text("No priority contacts yet", style: TextStyle(color: Colors.grey.shade400)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: viewModel.contacts.length,
                        itemBuilder: (context, index) {
                          final contact = viewModel.contacts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                child: Icon(Icons.priority_high, color: primaryColor, size: 20),
                              ),
                              title: Text(
                                contact.number,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.music_note, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(p.basename(contact.soundPath), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: accentColor),
                                onPressed: () => viewModel.deleteContact(contact.number),
                              ),
                            ),
                          );
                        },
                      ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}