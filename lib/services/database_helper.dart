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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        in_time TEXT NOT NULL,
        out_time TEXT,
        FOREIGN KEY (roll_number) REFERENCES students (roll_number)
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add out_time column
      await db.execute('ALTER TABLE attendance ADD COLUMN out_time TEXT');
      // Rename timestamp to in_time (SQLite doesn't support generic RENAME COLUMN in older versions easily, 
      // but commonly we can just interpret the old 'timestamp' as 'in_time' in code or add new column and copy.
      // For simplicity/compatibility, we will try to rename if possible or just create new col)
      
      // Since SQLite limited support for RENAME COLUMN depending on version:
      // Simplest migration: we will treat 'timestamp' as valid legacy and just add 'in_time' column, 
      // and update 'Attendance.fromMap' to handle it.
      // BUT, let's try to be clean.
      // We will just ADD in_time and COPY timestamp to it, then we can ignore timestamp.
      
      try {
        await db.execute('ALTER TABLE attendance RENAME COLUMN timestamp TO in_time');
      } catch (e) {
        // Fallback if renaming not supported directly
        await db.execute('ALTER TABLE attendance ADD COLUMN in_time TEXT');
        await db.execute('UPDATE attendance SET in_time = timestamp');
      }
    }
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

  // Attendance Operations

  // Strict Check-In
  Future<int> markCheckIn(Attendance attendance) async {
    final db = await instance.database;
    final existing = await db.query(
      'attendance',
      where: 'roll_number = ? AND date = ?',
      whereArgs: [attendance.rollNumber, attendance.date],
    );

    if (existing.isNotEmpty) {
      throw Exception('Already Checked In');
    }

    return await db.insert('attendance', attendance.toMap());
  }

  // Strict Check-Out
  Future<int> markCheckOut(String rollNumber, String date, String outTime) async {
    final db = await instance.database;
    final existing = await db.query(
      'attendance',
      where: 'roll_number = ? AND date = ?',
      whereArgs: [rollNumber, date],
    );

    if (existing.isEmpty) {
      throw Exception('Student has not Checked In yet');
    }

    final record = existing.first;
    if (record['out_time'] != null && (record['out_time'] as String).isNotEmpty) {
       throw Exception('Already Checked Out');
    }

    return await db.update(
      'attendance',
      {'out_time': outTime},
      where: 'id = ?',
      whereArgs: [record['id']],
    );
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
