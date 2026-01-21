class Student {
  final String rollNumber;
  final String name;
  final String department;
  final String semester;
  
  Student({
    required this.rollNumber,
    required this.name,
    required this.department,
    required this.semester,
  });

  Map<String, dynamic> toMap() {
    return {
      'roll_number': rollNumber,
      'name': name,
      'department': department,
      'semester': semester,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      rollNumber: map['roll_number'],
      name: map['name'],
      department: map['department'],
      semester: map['semester'],
    );
  }
}
