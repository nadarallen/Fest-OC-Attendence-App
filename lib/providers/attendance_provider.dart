import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../services/database_helper.dart';

class AttendanceProvider with ChangeNotifier {
  List<Student> _students = [];
  bool _isLoading = false;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();
    _students = await DatabaseHelper.instance.getAllStudents();
    _isLoading = false;
    notifyListeners();
  }

  Future<String> markAttendance(String rollNumber) async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Check if student exists
    final student = await DatabaseHelper.instance.getStudent(rollNumber);
    if (student == null) {
      return 'not_found';
    }

    try {
      final attendance = Attendance(
        rollNumber: rollNumber,
        date: date,
        status: 'P',
        timestamp: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.markAttendance(attendance);
      notifyListeners();
      return 'success';
    } catch (e) {
      if (e.toString().contains('already marked')) {
        return 'duplicate';
      }
      return 'error';
    }
  }

  Future<void> registerStudent(Student student) async {
    await DatabaseHelper.instance.createStudent(student);
    await loadStudents();
    await markAttendance(student.rollNumber); 
  }

  Future<Map<String, double>> getAttendancePercentage(String rollNumber) async {
    final stats = await DatabaseHelper.instance.getStudentStats(rollNumber);
    final total = stats['total'];
    final present = stats['present'];
    
    if (total == 0) return {'percentage': 0.0, 'present': 0.0, 'total': 0.0};
    
    return {
      'percentage': (present / total) * 100,
      'present': present.toDouble(),
      'total': total.toDouble()
    };
  }
}
