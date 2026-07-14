import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/Screens/about_screen.dart';
import 'package:notes_app/sort_options.dart';
import '../custom_notification.dart';
import '../note.dart';
import 'add_note_screen.dart';
import 'note_details_screen.dart';
import '../note_action.dart';
import 'dart:ui';

class NotesScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const NotesScreen({super.key, required this.onThemeChanged});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Note> notes = [];

  final List<Note> filteredNotes = [];
  final Box box = Hive.box('notesBox');
  final TextEditingController searchController = TextEditingController();
  SortOptions currentSort = SortOptions.newest;
  bool isSelectionMode = false;
  final Set<int> selectedNotes = {};

  @override
  void initState() {
    super.initState();

    debugPrint(box.runtimeType.toString());

    _loadNotes();
  }

  void _toggleSelection(Note note) {
    if (note.key == null) return;

    setState(() {
      if (selectedNotes.contains(note.key!)) {
        selectedNotes.remove(note.key!);
      } else {
        selectedNotes.add(note.key!);
      }

      if (selectedNotes.isEmpty) {
        isSelectionMode = false;
      }
    });
  }

  void _startSelection(Note note) {
    if (note.key == null) return;

    setState(() {
      isSelectionMode = true;
      selectedNotes.add(note.key!);
    });
  }

  void _exitSelection() {
    setState(() {
      isSelectionMode = false;
      selectedNotes.clear();
    });
  }

  void _loadNotes() {
    if (notes.isNotEmpty) {
      return;
    }

    for (final key in box.keys) {
      final item = box.get(key);
      if (item is Map) {
        notes.add(
          Note(
            key: key,
            title: item['title']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
            createdAt: DateTime.parse(item['createdAt'].toString()),
            isPinned: item['isPinned'] ?? false,
          ),
        );
      }
    }

    sortNotes();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void sortNotes() {
    notes.sort((a, b) {
      final pinnedComparison = a.isPinned == b.isPinned
          ? 0
          : (a.isPinned ? -1 : 1);

      if (pinnedComparison != 0) {
        return pinnedComparison;
      }

      switch (currentSort) {
        case SortOptions.newest:
          return b.createdAt.compareTo(a.createdAt);
        case SortOptions.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case SortOptions.az:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortOptions.za:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });
  }

  void _filterNotes() {
    filteredNotes.clear();

    if (searchController.text.isEmpty) {
      return;
    }

    final query = searchController.text.toLowerCase();
    filteredNotes.addAll(
      notes.where(
        (note) =>
            note.title.toLowerCase().contains(query) ||
            note.description.toLowerCase().contains(query),
      ),
    );
  }

  Future<void> _onDeleteNote(Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    final noteIndex = notes.indexOf(note);
    if (noteIndex == -1) {
      return;
    }

    setState(() {
      notes.removeAt(noteIndex);
      filteredNotes.remove(note);
    });

    await box.delete(note.key);

    if (!mounted) return;

    CustomNotification.show(
      context,
      message: 'Note Deleted',
      icon: Icons.delete,
      color: Colors.red,
    );
  }

  Future<void> _deleteNoteDirectly(Note note) async {
    setState(() {
      notes.remove(note);
      filteredNotes.remove(note);
      selectedNotes.remove(note.key);
    });

    await box.delete(note.key);

    if (!mounted) return;

    CustomNotification.show(
      context,
      message: 'Note Deleted',
      icon: Icons.delete,
      color: Colors.red,
    );
  }

  Future<void> _pinSelectedNotes() async {
    for (var note in notes) {
      if (selectedNotes.contains(note.key)) {
        note.isPinned = !note.isPinned;

        if (note.key != null) {
          await box.put(note.key!, {
            'title': note.title,
            'description': note.description,
            'createdAt': note.createdAt.toIso8601String(),
            'isPinned': note.isPinned,
          });
        }
      }
    }

    setState(() {
      sortNotes();
      _exitSelection();
    });

    CustomNotification.show(
      context,
      message: "Notes Updated",
      icon: Icons.push_pin,
      color: Colors.orange,
    );
  }

  Future<void> _deleteSelectedNotes() async {
    debugPrint("Delete button pressed");
    debugPrint("Selected: $selectedNotes");

    final notesToDelete = notes
        .where((note) => selectedNotes.contains(note.key))
        .toList();

    for (final note in notesToDelete) {
      await box.delete(note.key);
    }

    setState(() {
      notes.removeWhere((note) => selectedNotes.contains(note.key));
      filteredNotes.removeWhere((note) => selectedNotes.contains(note.key));
      isSelectionMode = false;
      selectedNotes.clear();
    });

    if (!mounted) return;

    CustomNotification.show(
      context,
      message: "Notes Deleted",
      icon: Icons.delete,
      color: Colors.red,
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white60, Colors.white10],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white30, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 25,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sortItem(
                        icon: Icons.schedule,
                        title: "Newest",
                        onTap: () {
                          Navigator.pop(context);

                          setState(() {
                            currentSort = SortOptions.newest;
                            sortNotes();
                          });
                        },
                      ),

                      _sortItem(
                        icon: Icons.history,
                        title: "Oldest",
                        onTap: () {
                          Navigator.pop(context);

                          setState(() {
                            currentSort = SortOptions.oldest;
                            sortNotes();
                          });
                        },
                      ),

                      _sortItem(
                        icon: Icons.sort_by_alpha,
                        title: "A - Z",
                        onTap: () {
                          Navigator.pop(context);

                          setState(() {
                            currentSort = SortOptions.az;
                            sortNotes();
                          });
                        },
                      ),

                      _sortItem(
                        icon: Icons.sort_by_alpha,
                        title: "Z - A",
                        onTap: () {
                          Navigator.pop(context);

                          setState(() {
                            currentSort = SortOptions.za;
                            sortNotes();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sortItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: isSelectionMode
            ? Text("${selectedNotes.length} Selected")
            : const Column(
                children: [
                  Text(
                    'NoteFlow',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Keep your ideas organized',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelection,
              )
            : null,
        actions: isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.push_pin),
                  onPressed: _pinSelectedNotes,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    debugPrint("Delete icon pressed");
                    _deleteSelectedNotes();
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.sort),
                  tooltip: "Sort Notes",
                  onPressed: _showSortMenu,
                ),
                IconButton(
                  onPressed: widget.onThemeChanged,
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
              ],
      ),
      body: notes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 90, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Welcome to NoteFlow',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Create your first note and start capturing your ideas",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search notes...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Colors.orange,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        setState(_filterNotes);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (searchController.text.isNotEmpty && filteredNotes.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: searchController.text.isEmpty
                            ? notes.length
                            : filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = searchController.text.isEmpty
                              ? notes[index]
                              : filteredNotes[index];

                          return Dismissible(
                            key: ValueKey(note.key),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Note'),
                                      content: const Text(
                                        'Are you sure you want to delete this note?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            onDismissed: (_) => _deleteNoteDirectly(note),

                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Card(
                                elevation: 12,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: ListTile(
                                  selected: selectedNotes.contains(note.key),
                                  selectedTileColor: Colors.orange.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  onLongPress: () {
                                    _startSelection(note);
                                  },
                                  leading: isSelectionMode
                                      ? CircleAvatar(
                                          backgroundColor:
                                              selectedNotes.contains(note.key)
                                              ? Colors.deepPurple
                                              : Colors.grey.shade300,
                                          child: Icon(
                                            selectedNotes.contains(note.key)
                                                ? Icons.check
                                                : Icons.circle_outlined,
                                            color: Colors.white,
                                          ),
                                        )
                                      : CircleAvatar(
                                          backgroundColor:
                                              Colors.deepPurple.shade100,
                                          child: Icon(
                                            note.isPinned
                                                ? Icons.push_pin
                                                : Icons.note_alt_outlined,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                  title: Text(
                                    note.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (note.isPinned) ...[
                                        const Text(
                                          '📌 Pinned',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy • hh:mm a',
                                        ).format(note.createdAt),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    if (isSelectionMode) {
                                      _toggleSelection(note);
                                      return;
                                    }
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            NoteDetailsScreen(note: note),
                                      ),
                                    );

                                    if (!mounted || result == null) return;

                                    final action = result["action"];

                                    switch (action) {
                                      case NoteAction.edited:
                                        final Note updatedNote = result["note"];

                                        note.title = updatedNote.title;
                                        note.description =
                                            updatedNote.description;

                                        await box.put(note.key!, {
                                          'title': note.title,
                                          'description': note.description,
                                          'createdAt': note.createdAt
                                              .toIso8601String(),
                                          'isPinned': note.isPinned,
                                        });

                                        setState(() {
                                          sortNotes();
                                        });

                                        CustomNotification.show(
                                          context,
                                          message: "Note Updated",
                                          icon: Icons.edit,
                                          color: Colors.blue,
                                        );
                                        break;
                                      case NoteAction.pinned:
                                      case NoteAction.unpinned:
                                        final Note updatedNote = result["note"];

                                        note.isPinned = updatedNote.isPinned;

                                        await box.put(note.key!, {
                                          'title': note.title,
                                          'description': note.description,
                                          'createdAt': note.createdAt
                                              .toIso8601String(),
                                          'isPinned': note.isPinned,
                                        });

                                        setState(() {
                                          sortNotes();
                                        });

                                        CustomNotification.show(
                                          context,
                                          message: action == NoteAction.pinned
                                              ? "Note Pinned"
                                              : "Note Unpinned",
                                          icon: action == NoteAction.pinned
                                              ? Icons.push_pin
                                              : Icons.push_pin_outlined,
                                          color: Colors.orange,
                                        );
                                        break;
                                      case NoteAction.deleted:
                                        final deletedKey = result["key"];

                                        await box.delete(deletedKey);

                                        setState(() {
                                          notes.removeWhere(
                                            (n) => n.key == deletedKey,
                                          );
                                          filteredNotes.removeWhere(
                                            (n) => n.key == deletedKey,
                                          );
                                        });

                                        if (!mounted) return;

                                        CustomNotification.show(
                                          context,
                                          message: "Note Deleted",
                                          icon: Icons.delete,
                                          color: Colors.red,
                                        );
                                        break;
                                    }
                                  },

                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Add Note',
        icon: const Icon(Icons.add),

        label: const Text(
          "New Note",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final Note? newNote = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddNoteScreen()),
          );

          if (newNote != null) {
            final key = await box.add({
              'title': newNote.title,
              'description': newNote.description,
              'createdAt': newNote.createdAt.toIso8601String(),
              'isPinned': newNote.isPinned,
            });

            newNote.key = key;

            setState(() {
              notes.add(newNote);
              sortNotes();

              if (searchController.text.isNotEmpty &&
                  (newNote.title.toLowerCase().contains(
                        searchController.text.toLowerCase(),
                      ) ||
                      newNote.description.toLowerCase().contains(
                        searchController.text.toLowerCase(),
                      ))) {
                filteredNotes.add(newNote);
              }
            });

            if (!mounted) return;

            CustomNotification.show(
              context,
              message: 'Note Saved',
              icon: Icons.check_circle,
              color: Colors.green,
            );
          }
        },
      ),
    );
  }
}
