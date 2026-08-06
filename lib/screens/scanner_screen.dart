import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../models/student.dart';
import '../models/scan_type.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  ScanType _scanType = ScanType.checkIn;

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
        
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final String activeUser = auth.currentDisplayName ?? auth.currentUsername ?? 'System';

        // Mark Attendance with active user info
        final provider = Provider.of<AttendanceProvider>(context, listen: false);
        final result = await provider.markAttendance(code, _scanType, markedBy: activeUser);
        
        if (result == 'check-in-success') {
          _showMessage('Check-In Successful: $code (by $activeUser)', Colors.green);
        } else if (result == 'check-out-success') {
          _showMessage('Check-Out Successful: $code (by $activeUser)', Colors.blue);
        } else if (result == 'already-checked-in') {
          _showMessage('Already Checked In Today!', Colors.orange);
        } else if (result == 'already-checked-out') {
          _showMessage('Already Checked Out Today!', Colors.red);
        } else if (result == 'not-checked-in') {
          _showMessage('Student has NOT checked in yet!', Colors.redAccent);
        } else if (result == 'not_found') {
          if (_scanType == ScanType.checkIn) {
            // Pause Scanner and Show Register Dialog
            await controller.stop();
            if (mounted) {
              await _showRegisterDialog(code);
              await controller.start();
            }
          } else {
             _showMessage('Student Not Found!', Colors.red);
          }
        } else {
          _showMessage('Error Marking Attendance', Colors.red);
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
    final domainController = TextEditingController();
    final semController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('New Student: $rollNumber'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: domainController, decoration: const InputDecoration(labelText: 'OC Domain')),
              TextField(controller: semController, decoration: const InputDecoration(labelText: 'Semester')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
               if (nameController.text.isEmpty) return;
               
               final auth = Provider.of<AuthProvider>(context, listen: false);
               final String activeUser = auth.currentDisplayName ?? auth.currentUsername ?? 'System';

               final newStudent = Student(
                 rollNumber: rollNumber,
                 name: nameController.text,
                 ocDomain: domainController.text,
                 semester: semController.text,
               );
               
               await Provider.of<AttendanceProvider>(context, listen: false).registerStudent(newStudent, markedBy: activeUser);
               if (mounted) Navigator.pop(context);
               _showMessage('Student Registered & Checked In by $activeUser', Colors.green);
            },
            child: const Text('Register & Check-In'),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Column(
        children: [
          // Toggle UI
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<ScanType>(
              segments: const [
                ButtonSegment(
                  value: ScanType.checkIn,
                  label: Text('Check In'),
                  icon: Icon(Icons.login),
                ),
                ButtonSegment(
                  value: ScanType.checkOut,
                  label: Text('Check Out'),
                  icon: Icon(Icons.logout),
                ),
              ],
              selected: {_scanType},
              onSelectionChanged: (Set<ScanType> newSelection) {
                setState(() {
                  _scanType = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: _handleBarcode,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: _scanType == ScanType.checkIn ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            child: Text(
              _scanType == ScanType.checkIn ? 'Scanning for CHECK IN' : 'Scanning for CHECK OUT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _scanType == ScanType.checkIn ? Colors.green : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
