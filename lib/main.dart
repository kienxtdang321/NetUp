import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart'; // Thêm thư viện biểu đồ

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const MainNavigationScreen(),
    );
  }
}

class DB {
  static Future<Database> init() async {
    return openDatabase(
      join(await getDatabasesPath(), 'todo_pro_final_v15.db'),
      onCreate: (db, version) => db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY, title TEXT, date TEXT, priority TEXT, category TEXT, status TEXT)'),
      version: 1,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(), 
    const SearchScreen(), 
    const HistoryScreen(),
    const ChartScreen(), // Thêm trang biểu đồ mới
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: "Lịch trình"),
          NavigationDestination(icon: Icon(Icons.search), label: "Tìm kiếm"),
          NavigationDestination(icon: Icon(Icons.history), label: "Lịch sử"),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: "Thống kê"), // Icon biểu đồ
        ],
      ),
    );
  }
}

// --- MÀN HÌNH BIỂU ĐỒ MỚI ---
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});
  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int done = 0;
  int pending = 0;

  void _loadStats() async {
    final db = await DB.init();
    final data = await db.query('tasks');
    int d = data.where((t) => t['status'] == 'Hoàn thành').length;
    int p = data.where((t) => t['status'] != 'Hoàn thành').length;
    setState(() { done = d; pending = p; });
  }

  @override
  void initState() { super.initState(); _loadStats(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thống kê hiệu suất")),
      body: (done == 0 && pending == 0) 
        ? const Center(child: Text("Chưa có dữ liệu để thống kê"))
        : Column(
            children: [
              const SizedBox(height: 50),
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: done.toDouble(), color: Colors.green, title: "Xong\n$done", radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      PieChartSectionData(value: pending.toDouble(), color: Colors.orange, title: "Chờ\n$pending", radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Biểu đồ tỉ lệ hoàn thành công việc", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
    );
  }
}

// (Các class HomeScreen, SearchScreen, HistoryScreen và buildTaskList giữ nguyên như code cũ của bạn)
// ... [Chèn phần code cũ từ HomeScreen đến hết buildTaskList tại đây]