class Attendance {
  final int? id;
  final String rollNumber;
  final String date; // YYYY-MM-DD
  final String status; // 'P' or 'A'
  final String inTime;
  final String? outTime;
  final String? markedBy; // Username of authorized user who took attendance

  Attendance({
    this.id,
    required this.rollNumber,
    required this.date,
    required this.status,
    required this.inTime,
    this.outTime,
    this.markedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roll_number': rollNumber,
      'date': date,
      'status': status,
      'in_time': inTime,
      'out_time': outTime,
      'marked_by': markedBy ?? 'System',
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      rollNumber: map['roll_number'] as String,
      date: map['date'] as String,
      status: map['status'] as String,
      inTime: map['in_time'] ?? map['timestamp'] ?? '',
      outTime: map['out_time'] as String?,
      markedBy: map['marked_by'] as String? ?? 'System',
    );
  }
}
