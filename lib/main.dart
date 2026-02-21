import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const HabitTrackerScreen(),
    );
  }
}

// Database Helper
class HabitDatabaseHelper {
  static final HabitDatabaseHelper instance = HabitDatabaseHelper._init();
  static Database? _database;

  HabitDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habits.db');
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
  }

  // Habit operations
  Future<int> createHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final result = await db.query('habits', orderBy: 'createdAt DESC');
    return result.map((map) => Habit.fromMap(map)).toList();
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    await db.delete('habit_logs', where: 'habitId = ?', whereArgs: [id]);
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // Habit log operations
  Future<void> toggleHabitLog(int habitId, String date) async {
    final db = await database;
    final existing = await db.query(
      'habit_logs',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, date],
    );

    if (existing.isEmpty) {
      await db.insert('habit_logs', {
        'habitId': habitId,
        'date': date,
        'completed': 1,
      });
    } else {
      await db.delete(
        'habit_logs',
        where: 'habitId = ? AND date = ?',
        whereArgs: [habitId, date],
      );
    }
  }

  Future<List<String>> getCompletedDates(int habitId) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      columns: ['date'],
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    return result.map((map) => map['date'] as String).toList();
  }

  Future<Map<int, List<String>>> getAllCompletedDates() async {
    final habits = await getAllHabits();
    Map<int, List<String>> result = {};
    
    for (var habit in habits) {
      final dates = await getCompletedDates(habit.id!);
      result[habit.id!] = dates;
    }
    
    return result;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

// Models
class Habit {
  final int? id;
  final String name;
  final int color;
  final DateTime createdAt;

  Habit({
    this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Habit copyWith({
    int? id,
    String? name,
    int? color,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Habit Colors
final List<Color> habitColors = [
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
];

// Habit Tracker Screen
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final HabitDatabaseHelper _dbHelper = HabitDatabaseHelper.instance;
  List<Habit> _habits = [];
  Map<int, List<String>> _completedDates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final habits = await _dbHelper.getAllHabits();
    final completedDates = await _dbHelper.getAllCompletedDates();
    setState(() {
      _habits = habits;
      _completedDates = completedDates;
      _isLoading = false;
    });
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _addHabit() async {
    final nameController = TextEditingController();
    Color selectedColor = habitColors[0];
    final context = this.context; // Capture outer context before StatefulBuilder

    final result = await showDialog<Habit>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter habit name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Color:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: habitColors.map((color) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final habit = Habit(
                    name: name,
                    color: selectedColor.toARGB32(),
                    createdAt: DateTime.now(),
                  );
                  Navigator.pop(context, habit);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _dbHelper.createHabit(result);
      _loadData();
    }
  }

  Future<void> _toggleHabit(Habit habit) async {
    final dateStr = _getDateString(DateTime.now());
    await _dbHelper.toggleHabitLog(habit.id!, dateStr);
    _loadData();
  }

  Future<void> _deleteHabit(Habit habit) async {
    final context = this.context; // Capture outer context before StatefulBuilder
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && habit.id != null) {
      await _dbHelper.deleteHabit(habit.id!);
      _loadData();
    }
  }

  bool _isHabitCompletedToday(Habit habit) {
    final dateStr = _getDateString(DateTime.now());
    return _completedDates[habit.id]?.contains(dateStr) ?? false;
  }

  int _getStreak(Habit habit) {
    final dates = _completedDates[habit.id] ?? [];
    if (dates.isEmpty) return 0;

    dates.sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (int i = 0; i < 365; i++) {
      final dateStr = _getDateString(checkDate);
      if (dates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (i > 0) {
        break;
      } else {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }
    
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.track_changes, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No habits yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap + to add your first habit',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _habits.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    final isCompleted = _isHabitCompletedToday(habit);
                    final streak = _getStreak(habit);
                    final habitColor = Color(habit.color);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _toggleHabit(habit),
                        onLongPress: () => _deleteHabit(habit),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: habitColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCompleted ? Icons.check : Icons.circle_outlined,
                                  color: habitColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      habit.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department,
                                          size: 16,
                                          color: streak > 0 ? Colors.orange : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$streak day streak',
                                          style: TextStyle(
                                            color: streak > 0 ? Colors.orange : Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                isCompleted ? 'Done' : 'Tap to complete',
                                style: TextStyle(
                                  color: isCompleted ? Colors.green : Colors.grey,
                                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
    );
  }
}
