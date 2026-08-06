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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        roll_number TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        oc_domain TEXT NOT NULL,
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
        marked_by TEXT,
        FOREIGN KEY (roll_number) REFERENCES students (roll_number)
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        username TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        totp_secret TEXT NOT NULL
      )
    ''');

    await _seedUsers(db);
  }

  Future _seedUsers(Database db) async {
    final users = [
      {'username': 'Allen Admin', 'display_name': 'Allen Admin', 'totp_secret': 'JBSWY3DPEHPK3PXP'},
      {'username': 'user1', 'display_name': 'user1', 'totp_secret': 'KVKFKRCPNZQUYMLS'},
      {'username': 'user2', 'display_name': 'user2', 'totp_secret': 'MZXW6YTBOIJW4ZZP'},
      {'username': 'user3', 'display_name': 'user3', 'totp_secret': 'NXW2CZLSMFUG64TW'},
    ];
    for (var u in users) {
      await db.insert('users', u, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add out_time column
      await db.execute('ALTER TABLE attendance ADD COLUMN out_time TEXT');
      try {
        await db.execute('ALTER TABLE attendance RENAME COLUMN timestamp TO in_time');
      } catch (e) {
        await db.execute('ALTER TABLE attendance ADD COLUMN in_time TEXT');
        await db.execute('UPDATE attendance SET in_time = timestamp');
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE attendance ADD COLUMN marked_by TEXT');
      } catch (e) {
        // Ignore if already exists
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
      columns: ['roll_number', 'name', 'oc_domain', 'semester'],
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
