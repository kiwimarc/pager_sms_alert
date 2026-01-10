// The generic object that the UI displays (standardized)
class SmartHomeEntity {
  final String id;
  final String name;
  final String type; // 'script', 'light', 'scene', etc.

  SmartHomeEntity({required this.id, required this.name, required this.type});
}

// The contract that all vendors must sign
abstract class SmartHomeProvider {
  // Initialize with saved settings (URL, Token, etc.)
  Future<void> initialize(Map<String, dynamic> config);

  // Get a list of things we can trigger
  Future<List<SmartHomeEntity>> fetchAvailableActions();

  // The main event: Do the thing!
  Future<bool> triggerAction(String actionId);
}