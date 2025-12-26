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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pager"),
        backgroundColor: viewModel.isAppEnabled ? Colors.green : Colors.grey,
        actions: [
          Switch(
            value: viewModel.isAppEnabled,
            onChanged: (val) => viewModel.toggleAppEnabled(val),
            activeColor: Colors.white,
            activeTrackColor: Colors.lightGreenAccent,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // BIG STOP BUTTON
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  viewModel.stopAlarm();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Signal sent to stop alarm!")),
                  );
                },
                icon: const Icon(Icons.stop_circle, size: 30),
                label: const Text("STOP ALARM", style: TextStyle(fontSize: 20)),
              ),
            ),
            
            const SizedBox(height: 20),

            // INPUT FORM
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: viewModel.pickSound,
                          icon: const Icon(Icons.music_note),
                          label: const Text("Pick Sound"),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            viewModel.selectedSoundName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: () {
                          if (viewModel.selectedSoundPath == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a sound first!")));
                            return;
                          }
                          viewModel.addContact(_controller.text);
                          _controller.clear();
                        },
                        child: const Text("Add Priority Contact", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // CONTACT LIST
            Expanded(
              child: ListView.builder(
                itemCount: viewModel.contacts.length,
                itemBuilder: (context, index) {
                  final contact = viewModel.contacts[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active, color: Colors.blue),
                      title: Text(contact.number, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(p.basename(contact.soundPath)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
    );
  }
}