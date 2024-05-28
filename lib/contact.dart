class Contact {
  final int? id;
  final String name;
  final String firstName;
  final String number;

  Contact({
    this.id,
    required this.name,
    required this.firstName,
    required this.number,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'firstName': firstName,
      'number': number,
    };
  }

  @override
  String toString() {
    return 'Contact{id: $id, name: $name, firstName: $firstName, number: $number}';
  }
}