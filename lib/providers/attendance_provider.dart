import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../models/scan_type.dart';
import '../services/firestore_service.dart';

class AttendanceProvider with ChangeNotifier {
  List<Student> _students = [];
  bool _isLoading = false;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _students = await FirestoreService.instance.getAllStudents();
    } catch (e) {
      debugPrint("Error loading students: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String> markAttendance(String rollNumber, ScanType type, {String markedBy = 'System'}) async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Check if student exists
    final student = await FirestoreService.instance.getStudent(rollNumber);
    if (student == null) {
      return 'not_found';
    }

    try {
      if (type == ScanType.checkIn) {
        final attendance = Attendance(
          rollNumber: rollNumber,
          date: date,
          status: 'P',
          inTime: DateFormat('HH:mm').format(DateTime.now()),
          markedBy: markedBy,
        );
        await FirestoreService.instance.markCheckIn(attendance);
        notifyListeners();
        return 'check-in-success';
      } else {
        await FirestoreService.instance.markCheckOut(
          rollNumber, 
          date, 
          DateFormat('HH:mm').format(DateTime.now())
        );
        notifyListeners();
        return 'check-out-success';
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Already Checked In')) {
        return 'already-checked-in';
      } else if (msg.contains('Student has not Checked In yet')) {
        return 'not-checked-in';
      } else if (msg.contains('Already Checked Out')) {
        return 'already-checked-out';
      }
      return 'error';
    }
  }

  Future<void> registerStudent(Student student, {String markedBy = 'System'}) async {
    await FirestoreService.instance.createStudent(student);
    await loadStudents();
    await markAttendance(student.rollNumber, ScanType.checkIn, markedBy: markedBy); 
  }

  Future<Map<String, double>> getAttendancePercentage(String rollNumber) async {
    final stats = await FirestoreService.instance.getStudentStats(rollNumber);
    final total = stats['total'];
    final present = stats['present'];
    
    if (total == 0) return {'percentage': 0.0, 'present': 0.0, 'total': 0.0};
    
    return {
      'percentage': (present / total) * 100,
      'present': present.toDouble(),
      'total': total.toDouble()
    };
  }

  Future<void> clearAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await FirestoreService.instance.clearDatabase();
      _students = [];
    } catch (e) {
      debugPrint("Error clearing database: $e");
    }
    _isLoading = false;
    notifyListeners();
  }
}
