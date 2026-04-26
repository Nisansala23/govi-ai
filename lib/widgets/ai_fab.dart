import 'package:flutter/material.dart';
import '../screens/chat_screen.dart';

class AiFab extends StatelessWidget {
  const AiFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.green,
      elevation: 6,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      },
      child: const Icon(Icons.smart_toy, color: Colors.white),
    );
  }
}