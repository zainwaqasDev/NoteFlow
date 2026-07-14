import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../note.dart';
import '../note_action.dart';
import 'add_note_screen.dart';
import 'dart:ui';

class NoteDetailsScreen extends StatefulWidget {
  final Note note;

  const NoteDetailsScreen({super.key, required this.note});
  @override
  State<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFrostedMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Menu",
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 55,
                right: 14,
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white60, Colors.white10],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white30, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 25,
                              spreadRadius: -5,
                            ),
                          ],
                        ),

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _menuItem(
                              icon: Icons.edit,
                              title: "Edit",
                              onTap: () async {
                                Navigator.pop(context);

                                final editedNote = await Navigator.push<Note>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddNoteScreen(note: widget.note),
                                  ),
                                );

                                if (editedNote != null && mounted) {
                                  Navigator.pop(context, {
                                    "action": NoteAction.edited,
                                    "note": editedNote,
                                  });
                                }
                              },
                            ),

                            _menuItem(
                              icon: widget.note.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              title: widget.note.isPinned ? "Unpin" : "Pin",
                              onTap: () {
                                Navigator.pop(context);

                                widget.note.isPinned = !widget.note.isPinned;

                                Navigator.pop(context, {
                                  "action": widget.note.isPinned
                                      ? NoteAction.pinned
                                      : NoteAction.unpinned,
                                  "note": widget.note,
                                });
                              },
                            ),

                            _menuItem(
                              icon: Icons.delete,
                              title: "Delete",
                              iconColor: Colors.red,
                              onTap: () async {
                                Navigator.pop(context);

                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Delete Note"),
                                    content: const Text(
                                      "Are you sure you want to delete this note?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true && mounted) {
                                  Navigator.pop(context, {
                                    "action": NoteAction.deleted,
                                    "key": widget.note.key,
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        title: const Text("Note Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showFrostedMenu,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.orange.shade100.withValues(
                    alpha: 0.2,
                  ),
                  child: Icon(
                    widget.note.isPinned
                        ? Icons.push_pin
                        : Icons.note_alt_outlined,
                    size: 32,
                    color: Colors.orange,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                widget.note.title,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Created: ${DateFormat('dd MMM yyyy • hh:mm a').format(widget.note.createdAt)}",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const Divider(height: 40),

              const Text(
                "Description",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Text(
                widget.note.description,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
