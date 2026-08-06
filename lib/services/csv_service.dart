import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../models/attendance.dart';

class CsvService {
  Future<String> exportAttendanceToCsv() async {
    final students = await FirestoreService.instance.getAllStudents();
    final attendanceList = await FirestoreService.instance.getAllAttendance();

    final Set<String> datesSet = attendanceList.map((a) => a.date).toSet();
    final List<String> dates = datesSet.toList()..sort();
    
    List<List<dynamic>> rows = [];
    List<dynamic> header = ['Roll No', 'Name'];
    header.addAll(dates);
    header.add('Attendance %');
    rows.add(header);

    for (var student in students) {
      List<dynamic> row = [student.rollNumber, student.name];
      int presentCount = 0;

      for (var date in dates) {
        final att = attendanceList.firstWhere(
          (a) => a.rollNumber == student.rollNumber && a.date == date,
          orElse: () => Attendance(rollNumber: '', date: '', status: 'N/A', inTime: ''),
        );
        
        if (att.status == 'P') {
          String cellInfo = 'In: ${att.inTime}';
          if (att.outTime != null && att.outTime!.isNotEmpty) {
            cellInfo += '\nOut: ${att.outTime}';
          } else {
             cellInfo += '\nOut: -';
          }
          row.add(cellInfo);
          presentCount++;
        } else {
          row.add('A'); 
        }
      }
      
      double percentage = dates.isEmpty ? 0 : (presentCount / dates.length) * 100;
      row.add(percentage.toStringAsFixed(1));
      
      rows.add(row);
    }

    String csv = const ListToCsvConverter().convert(rows);

    // Save to App's Temporary Cache Directory (requires no permissions)
    final directory = await getTemporaryDirectory();
    final fileName = 'Attendance_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(csv);
    
    // Share result using native OS sharing options
    await Share.shareXFiles([XFile(file.path)], text: 'Attendance Report');
    
    return file.path;
  }
}
