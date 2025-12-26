class ContactModel {
  final String number;
  final String soundPath;

  ContactModel({required this.number, required this.soundPath});

  Map<String, dynamic> toJson() => {
        'number': number,
        'soundPath': soundPath,
      };

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      number: json['number'],
      soundPath: json['soundPath'],
    );
  }
}