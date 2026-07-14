import 'package:flutter/material.dart';
import '../note.dart';
import '../custom_notification.dart';

class AddNoteScreen extends StatefulWidget {
  final Note? note;

  const AddNoteScreen({super.key, this.note});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.note?.title ?? '');

    descriptionController = TextEditingController(
      text: widget.note?.description ?? '',
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void saveNote() {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      CustomNotification.show(
        context,
        message: "Please fill in both title and description.",
        icon: Icons.error,
        color: Colors.red,
      );
      return;
    }

    final note = Note(
      key: widget.note?.key,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      isPinned: widget.note?.isPinned ?? false,
    );

    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Note" : "New Note"),
        actions: [
          IconButton(onPressed: saveNote, icon: const Icon(Icons.check)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "Title",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: TextField(
                controller: descriptionController,
                expands: true,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "Start writing...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
