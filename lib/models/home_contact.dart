class HomeContact {
  final String number;
  final String soundPath;
  final String? entityId;
  final String? entityName;

  HomeContact(this.number, this.soundPath, {this.entityId, this.entityName});

  Map<String, dynamic> toJson() => {
    'number': number,
    'soundPath': soundPath,
    'entityId': entityId,
    'entityName': entityName
  };

  factory HomeContact.fromJson(Map<String, dynamic> json) => HomeContact(
    json['number'],
    json['soundPath'],
    entityId: json['entityId'],
    entityName: json['entityName'],
  );
}