import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'library/data/library_models.dart';
import 'library/data/library_repository.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final _queryController = TextEditingController();
  late Future<List<LibraryPaper>> _papers;
  ReadingStatus? _status;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _reload() {
    _papers = ref
        .read(libraryRepositoryProvider)
        .list(status: _status, query: _queryController.text);
  }

  Future<void> _changeStatus(LibraryPaper paper, ReadingStatus status) async {
    try {
      await ref
          .read(libraryRepositoryProvider)
          .update(
            paper.paperId,
            status: status,
            notes: paper.notes,
            tags: paper.tags,
          );
      if (mounted) setState(_reload);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _edit(LibraryPaper paper) async {
    final notes = TextEditingController(text: paper.notes);
    final tags = TextEditingController(text: paper.tags.join(', '));
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notes and tags'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notes,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Key findings, questions, or follow-up ideas…',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: tags,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'graph, methods, priority',
                  helperText: 'Separate tags with commas.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (shouldSave != true) {
      notes.dispose();
      tags.dispose();
      return;
    }

    final parsedTags = tags.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final noteText = notes.text.trim();
    notes.dispose();
    tags.dispose();
    try {
      await ref
          .read(libraryRepositoryProvider)
          .update(
            paper.paperId,
            status: paper.readingStatus,
            notes: noteText.isEmpty ? null : noteText,
            tags: parsedTags,
          );
      if (mounted) setState(_reload);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _delete(LibraryPaper paper) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove saved paper?'),
        content: Text(
          '“${paper.title}” and its notes and tags will be removed from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(libraryRepositoryProvider).delete(paper.paperId);
      if (mounted) setState(_reload);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research library'),
        actions: [
          IconButton(
            tooltip: 'Search for papers',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _queryController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => setState(_reload),
                        decoration: InputDecoration(
                          hintText: 'Filter by title or author…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: 'Apply filter',
                            onPressed: () => setState(_reload),
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<ReadingStatus?>(
                          segments: const [
                            ButtonSegment(value: null, label: Text('All')),
                            ButtonSegment(
                              value: ReadingStatus.toRead,
                              label: Text('To read'),
                            ),
                            ButtonSegment(
                              value: ReadingStatus.reading,
                              label: Text('Reading'),
                            ),
                            ButtonSegment(
                              value: ReadingStatus.read,
                              label: Text('Read'),
                            ),
                          ],
                          selected: {_status},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _status = selection.first;
                              _reload();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LibraryPaper>>(
              future: _papers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _LibraryMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Library unavailable',
                    message: snapshot.error.toString(),
                    actionLabel: 'Try again',
                    onAction: () => setState(_reload),
                  );
                }
                final papers = snapshot.data ?? const [];
                if (papers.isEmpty) {
                  return _LibraryMessage(
                    icon: Icons.bookmarks_outlined,
                    title: _status == null && _queryController.text.isEmpty
                        ? 'Your library is empty'
                        : 'No saved papers match',
                    message: _status == null && _queryController.text.isEmpty
                        ? 'Save a paper from its details page to start a reading list.'
                        : 'Try another reading state or a broader search.',
                    actionLabel:
                        _status == null && _queryController.text.isEmpty
                        ? 'Find papers'
                        : null,
                    onAction: _status == null && _queryController.text.isEmpty
                        ? () => context.push('/search')
                        : null,
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                      itemCount: papers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final paper = papers[index];
                        return _LibraryPaperCard(
                          paper: paper,
                          onOpen: () => context
                              .push(
                                '/papers/${Uri.encodeComponent(paper.paperId)}',
                              )
                              .then((_) {
                                if (mounted) setState(_reload);
                              }),
                          onStatusChanged: (status) =>
                              _changeStatus(paper, status),
                          onEdit: () => _edit(paper),
                          onDelete: () => _delete(paper),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryPaperCard extends StatelessWidget {
  const _LibraryPaperCard({
    required this.paper,
    required this.onOpen,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final LibraryPaper paper;
  final VoidCallback onOpen;
  final ValueChanged<ReadingStatus> onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metadata = [
      if (paper.year != null) '${paper.year}',
      if (paper.venue?.trim().isNotEmpty == true) paper.venue!.trim(),
      '${paper.citationCount} citations',
    ].join(' · ');
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onOpen,
                    child: Text(
                      paper.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Library actions',
                  onSelected: (action) {
                    if (action == 'edit') onEdit();
                    if (action == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit notes and tags'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Remove from library'),
                    ),
                  ],
                ),
              ],
            ),
            if (paper.authors.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                paper.authors.join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.primary),
              ),
            ],
            const SizedBox(height: 6),
            Text(metadata, style: TextStyle(color: colors.onSurfaceVariant)),
            if (paper.notes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                paper.notes!.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.4),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<ReadingStatus>(
                  value: paper.readingStatus,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(12),
                  items: ReadingStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (status) {
                    if (status != null) onStatusChanged(status);
                  },
                ),
                ...paper.tags.map((tag) => Chip(label: Text(tag))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    ),
  );
}
