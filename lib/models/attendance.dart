class Attendance {
  final int? id;
  final String rollNumber;
  final String date; // YYYY-MM-DD
  final String status; // 'P' or 'A'
  final String timestamp;

  Attendance({
    this.id,
    required this.rollNumber,
    required this.date,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roll_number': rollNumber,
      'date': date,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      rollNumber: map['roll_number'],
      date: map['date'],
      status: map['status'],
      timestamp: map['timestamp'],
    );
  }
}
