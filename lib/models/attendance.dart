class Attendance {
  final int? id;
  final String rollNumber;
  final String date; // YYYY-MM-DD
  final String status; // 'P' or 'A'
  final String inTime;
  final String? outTime;

  Attendance({
    this.id,
    required this.rollNumber,
    required this.date,
    required this.status,
    required this.inTime,
    this.outTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roll_number': rollNumber,
      'date': date,
      'status': status,
      'in_time': inTime,
      'out_time': outTime,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      rollNumber: map['roll_number'],
      date: map['date'],
      status: map['status'],
      inTime: map['in_time'] ?? map['timestamp'] ?? '', // Handle migration fallback
      outTime: map['out_time'],
    );
  }
}
