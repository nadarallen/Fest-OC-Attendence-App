import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../models/attendance.dart';
import '../models/student.dart';

class CsvService {
  Future<String> exportAttendanceToCsv() async {
    final students = await FirestoreService.instance.getAllStudents();
    final attendanceList = await FirestoreService.instance.getAllAttendance();

    final Set<String> datesSet = attendanceList.map((a) => a.date).toSet();
    final List<String> dates = datesSet.toList()..sort();
    
    List<List<dynamic>> rows = [];
    
    // Header Row
    List<dynamic> header = ['Roll No', 'Name', 'OC Domain', 'Semester'];
    header.addAll(dates);
    header.addAll(['Total Present', 'Total Days', 'Attendance %']);
    rows.add(header);

    for (var student in students) {
      List<dynamic> row = [
        student.rollNumber,
        student.name,
        student.ocDomain,
        student.semester,
      ];
      int presentCount = 0;

      for (var date in dates) {
        final att = attendanceList.firstWhere(
          (a) => a.rollNumber == student.rollNumber && a.date == date,
          orElse: () => Attendance(rollNumber: '', date: '', status: 'A', inTime: ''),
        );
        
        if (att.status == 'P') {
          String cellInfo = 'In: ${att.inTime}';
          if (att.outTime != null && att.outTime!.isNotEmpty) {
            cellInfo += ' | Out: ${att.outTime}';
          } else {
             cellInfo += ' | Out: -';
          }
          if (att.markedBy != null && att.markedBy!.isNotEmpty) {
            cellInfo += ' | Taken By: ${att.markedBy}';
          }
          row.add(cellInfo);
          presentCount++;
        } else {
          row.add('Absent'); 
        }
      }
      
      double percentage = dates.isEmpty ? 0 : (presentCount / dates.length) * 100;
      row.add(presentCount);
      row.add(dates.length);
      row.add('${percentage.toStringAsFixed(1)}%');
      
      rows.add(row);
    }

    // Add empty row separator and Detailed Log section
    rows.add([]);
    rows.add(['--- DETAILED ATTENDANCE LOG (RECORDED BY USER) ---']);
    rows.add(['Roll No', 'Name', 'Date', 'Check-In Time', 'Check-Out Time', 'Recorded By User', 'Status']);

    for (var att in attendanceList) {
      final student = students.firstWhere(
        (s) => s.rollNumber == att.rollNumber,
        orElse: () => Student(
          rollNumber: att.rollNumber,
          name: 'Unknown Student',
          ocDomain: '-',
          semester: '-',
        ),
      );
      rows.add([
        att.rollNumber,
        student.name,
        att.date,
        att.inTime,
        att.outTime ?? '-',
        att.markedBy ?? 'System',
        att.status == 'P' ? 'Present' : 'Absent',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    // Save to App's Temporary Directory
    final directory = await getTemporaryDirectory();
    final fileName = 'Attendance_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(csv);
    
    // Share result using native OS sharing options
    await Share.shareXFiles([XFile(file.path)], text: 'Attendance Report with Marked-By Log');
    
    return file.path;
  }
}
