class TContact {
  int? _id;
  String _number;
  String _name;

  TContact(this._number, this._name);
  TContact.withId(this._id, this._number, this._name);

  // Getters
  int get id => _id ?? 0; // Ensure a non-null value
  String get number => _number;
  String get name => _name;

  @override
  String toString() {
    return 'Contact: {id: $_id, name: $_name, number: $_number}';
  }

  // Convert a Contact object to a Map object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': _id, // Keep nullable, SQLite auto-generates IDs
      'number': _number,
      'name': _name,
    };
    return map;
  }

  // Extract a Contact Object from a Map object
  TContact.fromMapObject(Map<String, dynamic> map)
      : _id = map['id'] ?? 0, // Ensure non-null
        _number = map['number'] ?? '',
        _name = map['name'] ?? '';
}
