import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            Icon(Icons.note_alt_outlined, size: 100, color: Colors.deepPurple),
            SizedBox(height: 20),

            Text(
              "Notes App",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Text("Version 1.0.0", style: TextStyle(fontSize: 18)),

            SizedBox(height: 25),

            Text(
              "A simple and beautiful Notes App built with Flutter.\n\n"
              "Features:\n"
              "• Add Notes\n"
              "• Edit Notes\n"
              "• Delete Notes\n"
              "• Search Notes\n"
              "• Dark Mode\n"
              "• Pin Notes\n"
              "• Local Storage using Hive",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),

            Spacer(),

            Text(
              "Developed by CodZaiva ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
