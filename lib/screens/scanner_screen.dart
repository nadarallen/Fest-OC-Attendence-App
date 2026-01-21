import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../models/student.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() { _isProcessing = true; });
        final String code = barcode.rawValue!;
        
        // Mark Attendance
        final provider = Provider.of<AttendanceProvider>(context, listen: false);
        final result = await provider.markAttendance(code);
        
        if (result == 'success') {
          _showMessage('Attendance Marked for $code', Colors.green);
        } else if (result == 'duplicate') {
          _showMessage('Already Marked Today!', Colors.orange);
        } else if (result == 'not_found') {
          // Pause Scanner and Show Register Dialog
          await controller.stop();
          if (mounted) {
            await _showRegisterDialog(code);
            await controller.start();
          }
        }

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() { _isProcessing = false; });
        return; 
      }
    }
  }

  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _showRegisterDialog(String rollNumber) async {
    final nameController = TextEditingController();
    final deptController = TextEditingController();
    final semController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('New Student: $rollNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: deptController, decoration: const InputDecoration(labelText: 'Department')),
            TextField(controller: semController, decoration: const InputDecoration(labelText: 'Semester')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
               if (nameController.text.isEmpty) return;
               
               final newStudent = Student(
                 rollNumber: rollNumber,
                 name: nameController.text,
                 department: deptController.text,
                 semester: semController.text,
               );
               
               await Provider.of<AttendanceProvider>(context, listen: false).registerStudent(newStudent);
               if (mounted) Navigator.pop(context);
               _showMessage('Student Registered & Marked Present', Colors.green);
            },
            child: const Text('Register & Mark'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        controller: controller,
        onDetect: _handleBarcode,
      ),
    );
  }
}
