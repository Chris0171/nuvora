import 'package:flutter/material.dart';
import 'package:nuvora/features/tasks/presentation/screens/home_screen.dart'
    as task_home;

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const task_home.HomeScreen();
  }
}
