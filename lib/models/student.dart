class Student {
  final String rollNumber;
  final String name;
  final String ocDomain;
  final String semester;
  
  Student({
    required this.rollNumber,
    required this.name,
    required this.ocDomain,
    required this.semester,
  });

  Map<String, dynamic> toMap() {
    return {
      'roll_number': rollNumber,
      'name': name,
      'oc_domain': ocDomain,
      'semester': semester,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      rollNumber: map['roll_number'],
      name: map['name'],
      ocDomain: map['oc_domain'] ?? map['department'] ?? '',
      semester: map['semester'],
    );
  }
}

