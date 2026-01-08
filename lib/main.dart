import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart'; // Thư viện biểu đồ
import 'database_helper.dart';

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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  // Danh sách các màn hình ứng dụng
  final List<Widget> _pages = [
    const HomeScreen(), 
    const SearchScreen(), 
    const HistoryScreen(), 
    const ChartScreen() // Màn hình biểu đồ mới
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: "Lịch trình"),
          NavigationDestination(icon: Icon(Icons.search), label: "Tìm kiếm"),
          NavigationDestination(icon: Icon(Icons.history), label: "Lịch sử"),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: "Thống kê"), // Nút thứ 4 xuất hiện ở đây
        ],
      ),
    );
  }
}

// --- MÀN HÌNH BIỂU ĐỒ THỐNG KÊ ---
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});
  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int done = 0;
  int pending = 0;

  // Hàm tải dữ liệu thực tế từ SQLite
  Future<void> _loadStats() async {
    final db = await DB.init();
    final data = await db.query('tasks');
    // Lọc theo trạng thái Hoàn thành và Chưa làm
    int d = data.where((t) => t['status'] == 'Hoàn thành').length;
    int p = data.where((t) => t['status'] != 'Hoàn thành').length;
    if (mounted) setState(() { done = d; pending = p; });
  }

  @override
  void initState() { super.initState(); _loadStats(); }

  @override
  Widget build(BuildContext context) {
    _loadStats(); // Tự động làm mới dữ liệu khi người dùng chuyển tab
    return Scaffold(
      appBar: AppBar(title: const Text("Thống kê hiệu suất")),
      body: (done == 0 && pending == 0)
          ? const Center(child: Text("Hãy hoàn thành công việc để xem biểu đồ!"))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Tỷ lệ công việc của bạn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 50),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(value: done.toDouble(), color: Colors.green, title: "Xong ($done)", radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          PieChartSectionData(value: pending.toDouble(), color: Colors.orange, title: "Đang chờ ($pending)", radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legend(Colors.green, "Hoàn thành"),
                      const SizedBox(width: 20),
                      _legend(Colors.orange, "Chưa làm"),
                    ],
                  )
                ],
              ),
            ),
    );
  }

  Widget _legend(Color c, String text) => Row(children: [Container(width: 15, height: 15, color: c), const SizedBox(width: 5), Text(text)]);
}

// --- CÁC MÀN HÌNH CÒN LẠI (GIỮ NGUYÊN NHƯNG DÙNG CẤU TRÚC MỚI) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = DateTime.now();
  List<Map<String, dynamic>> _tasks = [];

  void _refresh() async {
    final db = await DB.init();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final data = await db.query('tasks', where: "date = ?", whereArgs: [dateStr], orderBy: "id DESC");
    if (mounted) setState(() => _tasks = data);
  }

  @override
  void initState() { super.initState(); _refresh(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎯 Lịch trình")),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDay, firstDay: DateTime(2023), lastDay: DateTime(2030),
            calendarFormat: CalendarFormat.week,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (s, f) { setState(() => _selectedDay = s); _refresh(); },
          ),
          Expanded(child: buildTaskList(_tasks, _refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _refresh(), child: const Icon(Icons.add)),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, dynamic>> _results = [];
  void _search(String q) async {
    final db = await DB.init();
    final data = await db.query('tasks', where: "title LIKE ?", whereArgs: ['%$q%']);
    setState(() => _results = data);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Tìm kiếm")),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(decoration: const InputDecoration(hintText: "Tìm kiếm...", prefixIcon: Icon(Icons.search)), onChanged: _search)),
      Expanded(child: buildTaskList(_results, () => _search(""))),
    ]),
  );
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _all = [];
  void _load() async {
    final db = await DB.init();
    final data = await db.query('tasks', orderBy: "date DESC");
    setState(() => _all = data);
  }
  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Lịch sử công việc")),
    body: buildTaskList(_all, _load),
  );
}

Widget buildTaskList(List<Map<String, dynamic>> tasks, Function refresh) {
  if (tasks.isEmpty) return const Center(child: Text("Chưa có công việc nào"));
  return ListView.builder(
    itemCount: tasks.length,
    itemBuilder: (ctx, i) {
      final t = tasks[i];
      final bool isDone = t['status'] == 'Hoàn thành';
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          leading: Icon(Icons.bookmark, color: t['priority'] == 'Cao' ? Colors.red : Colors.green),
          title: Text(t['title'], style: TextStyle(decoration: isDone ? TextDecoration.lineThrough : null)),
          subtitle: Text("${t['category']} • ${t['date']}"),
          trailing: Checkbox(
            value: isDone,
            onChanged: (v) async {
              final db = await DB.init();
              await db.update('tasks', {'status': v! ? 'Hoàn thành' : 'Chưa làm'}, where: "id = ?", whereArgs: [t['id']]);
              refresh();
            },
          ),
        ),
      );
    },
  );
}