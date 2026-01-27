import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../models/attendance.dart';

class CsvService {
  Future<String> exportAttendanceToCsv() async {
    // Check for Android 11+ (API 30+) 'Manage External Storage' permission
    if (await Permission.manageExternalStorage.status.isDenied) {
       await Permission.manageExternalStorage.request();
    }
    
    // Check for legacy 'Storage' permission (Android < 11)
    if (await Permission.storage.status.isDenied) {
      await Permission.storage.request();
    }
    
    // Verify strictly
    if (!await Permission.manageExternalStorage.isGranted && !await Permission.storage.isGranted) {
       // On some devices, Manage External Storage might show as denied even if granted via intent, 
       // but typically we should check status. 
       // For this specific use case (Downloads folder), let's assume if we can't write, we throw.
       
       // Try one more check for 'restricted' or 'permanentlyDenied'
       if (await Permission.manageExternalStorage.isPermanentlyDenied) {
          openAppSettings();
          throw Exception('Permission Persistent Denied. Please enable "Allow Management of All Files" in Settings.');
       }
    }

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
          // Format: In: HH:mm \n Out: HH:mm
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

    Directory? directory;
    if (Platform.isAndroid) {
      // Specific path for Downloads folder
      directory = Directory('/storage/emulated/0/Download');
      // Fallback if it doesn't exist (unexpected on standard Android)
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    final path = directory?.path ?? (await getApplicationDocumentsDirectory()).path;
    final fileName = 'Attendance_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('$path/$fileName');
    
    await file.writeAsString(csv);
    
    // Share result
    await Share.shareXFiles([XFile(file.path)], text: 'Attendance Report');
    
    return file.path;
  }
}
