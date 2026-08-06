import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  FirestoreService._init();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -- Students Collection --
  final CollectionReference _studentsRef =
      FirebaseFirestore.instance.collection('students');

  // -- Attendance Collection --
  final CollectionReference _attendanceRef =
      FirebaseFirestore.instance.collection('attendance');

  // -- Users Collection --
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  /// Seeds the 4 authorized users into Firestore
  Future<void> seedAuthorizedUsers() async {
    final users = [
      {'username': 'Allen Admin', 'displayName': 'Allen Admin', 'totpSecret': 'JBSWY3DPEHPK3PXP'},
      {'username': 'user1', 'displayName': 'user1', 'totpSecret': 'KVKFKRCPNZQUYMLS'},
      {'username': 'user2', 'displayName': 'user2', 'totpSecret': 'MZXW6YTBOIJW4ZZP'},
      {'username': 'user3', 'displayName': 'user3', 'totpSecret': 'NXW2CZLSMFUG64TW'},
    ];
    for (var u in users) {
      await _usersRef.doc(u['username']!).set(u, SetOptions(merge: true));
    }
  }

  // Student Operations
  Future<void> createStudent(Student student) async {
    // Using rollNumber as Document ID for easy lookup
    await _studentsRef.doc(student.rollNumber).set(student.toMap());
  }

  Future<Student?> getStudent(String rollNumber) async {
    final doc = await _studentsRef.doc(rollNumber).get();
    if (doc.exists) {
      return Student.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Student>> getAllStudents() async {
    final snapshot = await _studentsRef.get();
    return snapshot.docs
        .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Attendance Operations

  // Strict Check-In
  Future<void> markCheckIn(Attendance attendance) async {
    // Check if document exists for today?
    // Composite ID: rollNumber_date (e.g., "123_2024-05-20") ensures uniqueness
    final docId = '${attendance.rollNumber}_${attendance.date}';
    final docRef = _attendanceRef.doc(docId);

    final doc = await docRef.get();
    if (doc.exists) {
      throw Exception('Already Checked In');
    }

    await docRef.set(attendance.toMap());
  }

  // Strict Check-Out
  Future<void> markCheckOut(String rollNumber, String date, String outTime) async {
    final docId = '${rollNumber}_${date}';
    final docRef = _attendanceRef.doc(docId);

    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Student has not Checked In yet');
    }

    final data = doc.data() as Map<String, dynamic>;
    if (data['out_time'] != null && (data['out_time'] as String).isNotEmpty) {
      throw Exception('Already Checked Out');
    }

    await docRef.update({'out_time': outTime});
  }

  Future<List<Attendance>> getAllAttendance() async {
    final snapshot = await _attendanceRef.get();
    return snapshot.docs
        .map((doc) => Attendance.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getStudentStats(String rollNumber) async {
    // Firestore COUNT queries are efficient
    final totalQuery = _attendanceRef.where('roll_number', isEqualTo: rollNumber).count();
    final presentQuery = _attendanceRef
        .where('roll_number', isEqualTo: rollNumber)
        .where('status', isEqualTo: 'P')
        .count();

    final totalSnapshot = await totalQuery.get();
    final presentSnapshot = await presentQuery.get();

    return {
      'total': totalSnapshot.count ?? 0,
      'present': presentSnapshot.count ?? 0,
    };
  }

  // Clear Database
  Future<void> clearDatabase() async {
    // Delete all students
    final studentsSnapshot = await _studentsRef.get();
    for (var doc in studentsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete all attendance records
    final attendanceSnapshot = await _attendanceRef.get();
    for (var doc in attendanceSnapshot.docs) {
      await doc.reference.delete();
    }
  }
}
