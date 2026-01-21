import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('attendance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        roll_number TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        department TEXT NOT NULL,
        semester TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roll_number TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (roll_number) REFERENCES students (roll_number)
      )
    ''');
  }

  // Student Operations
  Future<int> createStudent(Student student) async {
    final db = await instance.database;
    return await db.insert('students', student.toMap());
  }

  Future<Student?> getStudent(String rollNumber) async {
    final db = await instance.database;
    final maps = await db.query(
      'students',
      columns: ['roll_number', 'name', 'department', 'semester'],
      where: 'roll_number = ?',
      whereArgs: [rollNumber],
    );

    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Student>> getAllStudents() async {
    final db = await instance.database;
    final result = await db.query('students');
    return result.map((json) => Student.fromMap(json)).toList();
  }

  Future<int> markAttendance(Attendance attendance) async {
    final db = await instance.database;
    final existing = await db.query(
      'attendance',
      where: 'roll_number = ? AND date = ?',
      whereArgs: [attendance.rollNumber, attendance.date],
    );

    if (existing.isNotEmpty) {
      throw Exception('Attendance already marked for this student today.');
    }

    return await db.insert('attendance', attendance.toMap());
  }
  
  Future<List<Attendance>> getAllAttendance() async {
    final db = await instance.database;
    return (await db.query('attendance')).map((json) => Attendance.fromMap(json)).toList();
  }
  
  Future<Map<String, dynamic>> getStudentStats(String rollNumber) async {
    final db = await instance.database;
    final total = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM attendance WHERE roll_number = ?', [rollNumber]
    ));
    final present = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM attendance WHERE roll_number = ? AND status = ?', [rollNumber, 'P']
    ));
    
    return {
      'total': total ?? 0,
      'present': present ?? 0,
    };
  }
}
