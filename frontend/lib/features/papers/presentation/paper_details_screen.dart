import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/paper_models.dart';
import '../data/paper_repository.dart';
import 'paper_card.dart';

class PaperDetailsScreen extends ConsumerStatefulWidget {
  const PaperDetailsScreen({required this.paperId, super.key});

  final String paperId;

  @override
  ConsumerState<PaperDetailsScreen> createState() => _PaperDetailsScreenState();
}

class _PaperDetailsScreenState extends ConsumerState<PaperDetailsScreen> {
  late Future<PaperDetails> _details;
  late Future<List<PaperSummary>> _related;
  Future<PaperPage>? _references;
  Future<PaperPage>? _citations;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant PaperDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paperId != widget.paperId) {
      _reload();
    }
  }

  void _reload() {
    final repository = ref.read(paperRepositoryProvider);
    _details = repository.getPaper(widget.paperId);
    _related = repository.getRelated(widget.paperId);
    _references = null;
    _citations = null;
  }

  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this paper.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paper details')),
      body: FutureBuilder<PaperDetails>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DetailsError(
              message: snapshot.error.toString(),
              onRetry: () => setState(_reload),
            );
          }
          return _buildDetails(context, snapshot.requireData);
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, PaperDetails paper) {
    final colors = Theme.of(context).colorScheme;
    final authors = paper.authors.map((author) => author.name).join(', ');
    final metadata = [
      if (paper.year != null) '${paper.year}',
      if (paper.venue?.trim().isNotEmpty == true) paper.venue!.trim(),
      if (paper.type?.trim().isNotEmpty == true) paper.type!.trim(),
    ].join(' · ');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          children: [
            Text(
              paper.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            if (authors.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                authors,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: colors.primary),
              ),
            ],
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(metadata, style: TextStyle(color: colors.onSurfaceVariant)),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(
                  avatar: const Icon(Icons.format_quote, size: 17),
                  label: Text('${paper.citationCount} citations'),
                ),
                Chip(
                  avatar: const Icon(Icons.call_made, size: 17),
                  label: Text('${paper.referenceCount} references'),
                ),
                if (paper.openAccess)
                  const Chip(
                    avatar: Icon(Icons.lock_open, size: 17),
                    label: Text('Open access'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: paper.externalUrl == null
                      ? null
                      : () => _open(paper.externalUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open original'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/graph/${Uri.encodeComponent(paper.id)}'),
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('Explore citations'),
                ),
              ],
            ),
            if (paper.topics.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: paper.topics
                    .take(8)
                    .map((topic) => Chip(label: Text(topic.name)))
                    .toList(),
              ),
            ],
            const SizedBox(height: 32),
            Text('Abstract', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              paper.abstractText?.trim().isNotEmpty == true
                  ? paper.abstractText!.trim()
                  : 'No abstract is available from the source.',
              style: TextStyle(
                height: 1.6,
                color: paper.abstractText?.trim().isNotEmpty == true
                    ? null
                    : colors.onSurfaceVariant,
                fontStyle: paper.abstractText?.trim().isNotEmpty == true
                    ? null
                    : FontStyle.italic,
              ),
            ),
            const SizedBox(height: 28),
            _PaperCollection(
              title: 'References',
              count: paper.referenceCount,
              future: _references,
              onOpen: () => setState(() {
                _references ??= ref
                    .read(paperRepositoryProvider)
                    .getReferences(widget.paperId);
              }),
            ),
            const SizedBox(height: 10),
            _PaperCollection(
              title: 'Cited by',
              count: paper.citationCount,
              future: _citations,
              onOpen: () => setState(() {
                _citations ??= ref
                    .read(paperRepositoryProvider)
                    .getCitations(widget.paperId);
              }),
            ),
            const SizedBox(height: 36),
            Text(
              'Related papers',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<PaperSummary>>(
              future: _related,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Related papers unavailable: ${snapshot.error}');
                }
                final related = snapshot.data ?? const [];
                if (related.isEmpty) {
                  return const Text('No related papers were returned.');
                }
                return Column(
                  children: [
                    for (final item in related) ...[
                      PaperCard(
                        paper: item,
                        compact: true,
                        onTap: () => context.push(
                          '/papers/${Uri.encodeComponent(item.id)}',
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Metadata supplied by ${paper.dataSource}.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperCollection extends StatelessWidget {
  const _PaperCollection({
    required this.title,
    required this.count,
    required this.future,
    required this.onOpen,
  });

  final String title;
  final int count;
  final Future<PaperPage>? future;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: ExpansionTile(
        title: Text(title),
        subtitle: Text('$count known'),
        onExpansionChanged: (isOpen) {
          if (isOpen && future == null) onOpen();
        },
        children: [
          if (future == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else
            FutureBuilder<PaperPage>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(snapshot.error.toString()),
                  );
                }
                final items = snapshot.data?.items ?? const [];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No papers available.'),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: items
                        .map(
                          (paper) => ListTile(
                            title: Text(paper.title),
                            subtitle: Text(
                              [
                                if (paper.year != null) '${paper.year}',
                                '${paper.citationCount} citations',
                              ].join(' · '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '/papers/${Uri.encodeComponent(paper.id)}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 52),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
