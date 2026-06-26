import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HalgheManagerApp());
}

class HalgheManagerApp extends StatelessWidget {
  const HalgheManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MR.ABOTORAB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.vazirmatnTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const LoginScreen(),
    );
  }
}

// Database Helper
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  DatabaseHelper._init();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('halghe.db');    return _database!;
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
  
  Future<void> _createDB(Database db, int version) async {
    // Members table
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birthdate TEXT,
        interests TEXT,
        responsibility TEXT,
        description TEXT,
        avatar TEXT,
        points INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Groups table
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        leader_id INTEGER,
        points INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Group members table
    await db.execute('''
      CREATE TABLE group_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER,
        member_id INTEGER,
        FOREIGN KEY (group_id) REFERENCES groups (id),
        FOREIGN KEY (member_id) REFERENCES members (id)
      )    ''');
    
    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER,
        date TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (member_id) REFERENCES members (id)
      )
    ''');
    
    // Rewards table
    await db.execute('''
      CREATE TABLE rewards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        required_level INTEGER NOT NULL,
        image TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Logs table
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        details TEXT,
        timestamp TEXT NOT NULL
      )
    ''');
    
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Insert default user
    await db.insert('users', {
      'username': 'admin',
      'password': '1717',
      'created_at': DateTime.now().toIso8601String(),    });
  }
  
  Future<void> addLog(String action, String details) async {
    final db = await database;
    await db.insert('logs', {
      'action': action,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
