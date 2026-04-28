import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/calendar_service.dart';
import '../services/ai_scheduler_service.dart';
import '../theme/app_theme.dart';

class FarmingCalendarScreen extends StatefulWidget {
  const FarmingCalendarScreen({super.key});

  @override
  State<FarmingCalendarScreen> createState() =>
      _FarmingCalendarScreenState();
}

class _FarmingCalendarScreenState extends State<FarmingCalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  String selectedCrop = "Paddy";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Farming Calendar 🌾")),

      body: Column(
        children: [
          _buildCalendar(),
          _buildSelectedDateHeader(),
          Expanded(child: _buildTaskList()),
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "ai",
            onPressed: _generateAI,
            icon: const Icon(Icons.auto_awesome),
            label: const Text("AI"),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "add",
            onPressed: _showAddTaskDialog,
            icon: const Icon(Icons.add),
            label: const Text("Add Task"),
          ),
        ],
      ),
    );
  }

  // 📅 CALENDAR WITH DOTS
  Widget _buildCalendar() {
    return StreamBuilder(
      stream: CalendarService.getTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;

        // 🔥 group tasks by date
        Map<DateTime, List> events = {};

        for (var doc in docs) {
          final date = (doc['date']).toDate();
          final day = DateTime(date.year, date.month, date.day);

          events.putIfAbsent(day, () => []);
          events[day]!.add(doc);
        }

        return TableCalendar(
          firstDay: DateTime.utc(2020),
          lastDay: DateTime.utc(2035),
          focusedDay: _focusedDay,

          selectedDayPredicate: (day) =>
              isSameDay(_selectedDay, day),

          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },

          // 🔥 DOTS
          eventLoader: (day) {
            return events[DateTime(day.year, day.month, day.day)] ?? [];
          },

          calendarStyle: const CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // 📆 HEADER
  Widget _buildSelectedDateHeader() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        "Tasks on ${_selectedDay.toLocal().toString().split(' ')[0]}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // 📡 TASK LIST
  Widget _buildTaskList() {
    return StreamBuilder(
      stream: CalendarService.getTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        final filtered = docs.where((doc) {
          final date = (doc['date']).toDate();
          return isSameDay(date, _selectedDay);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text("No tasks for this day 🌱"));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final task = filtered[index];

            return Card(
              child: ListTile(
                title: Text(task['title']),
                subtitle: Text(task['type']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    CalendarService.deleteTask(task.id);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ➕ ADD TASK
  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String type = "General";

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Task 🌾"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration:
                    const InputDecoration(labelText: "Task Title"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                value: type,
                items: ["General", "Fertilizing", "Irrigation", "Spraying"]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (value) => type = value!,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;

                await CalendarService.addTask(
                  title: titleController.text,
                  crop: selectedCrop,
                  type: type,
                  date: _selectedDay,
                );

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // 🤖 AI GENERATE
  Future<void> _generateAI() async {
    await AiSchedulerService.generateAndSaveSchedule(
      crop: selectedCrop,
      plantingDate: _selectedDay,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("AI Schedule Generated 🌾")),
    );
  }
}