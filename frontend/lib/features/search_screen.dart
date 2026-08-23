import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'papers/data/paper_models.dart';
import 'papers/data/paper_repository.dart';
import 'papers/presentation/paper_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  SearchMode _mode = SearchMode.keyword;
  List<PaperSummary> _papers = const [];
  String? _error;
  String _lastQuery = '';
  int _page = 1;
  int _total = 0;
  bool _hasSearched = false;
  bool _hasNext = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) _loadMore();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
      _papers = const [];
      _lastQuery = query;
      _page = 1;
      _total = 0;
      _hasNext = false;
    });
    try {
      final result = await ref
          .read(paperRepositoryProvider)
          .search(query: query, mode: _mode);
      if (!mounted) return;
      setState(() {
        _papers = result.items;
        _page = result.page;
        _total = result.total;
        _hasNext = result.hasNext;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_hasNext || _isLoading || _isLoadingMore || _error != null) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await ref
          .read(paperRepositoryProvider)
          .search(query: _lastQuery, mode: _mode, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _papers = [..._papers, ...result.items];
        _page = result.page;
        _hasNext = result.hasNext;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover papers')),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _queryController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: _mode == SearchMode.keyword
                              ? 'Search by title, author, topic…'
                              : 'Describe the research you need…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: 'Search',
                            onPressed: _isLoading ? null : _search,
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<SearchMode>(
                        segments: SearchMode.values
                            .map(
                              (mode) => ButtonSegment(
                                value: mode,
                                label: Text(mode.label),
                                icon: Icon(
                                  mode == SearchMode.keyword
                                      ? Icons.text_fields
                                      : Icons.auto_awesome,
                                ),
                              ),
                            )
                            .toList(),
                        selected: {_mode},
                        onSelectionChanged: _isLoading
                            ? null
                            : (selection) {
                                setState(() => _mode = selection.first);
                                if (_hasSearched) {
                                  _search();
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _papers.isEmpty) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Search unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _search,
      );
    }
    if (!_hasSearched) {
      return const _MessageState(
        icon: Icons.travel_explore,
        title: 'Start with a question or topic',
        message:
            'Use keyword search for exact terms, or semantic search to describe an idea in natural language.',
      );
    }
    if (_papers.isEmpty) {
      return const _MessageState(
        icon: Icons.search_off,
        title: 'No papers found',
        message: 'Try broader terms or switch search modes.',
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          itemCount: _papers.length + 2,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                '$_total results for “$_lastQuery”',
                style: Theme.of(context).textTheme.titleSmall,
              );
            }
            if (index == _papers.length + 1) {
              if (_isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (_error != null) {
                return Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _error = null);
                      _loadMore();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry loading more'),
                  ),
                );
              }
              return const SizedBox.shrink();
            }
            final paper = _papers[index - 1];
            return PaperCard(
              paper: paper,
              onTap: () =>
                  context.push('/papers/${Uri.encodeComponent(paper.id)}'),
            );
          },
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
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
      constraints: const BoxConstraints(maxWidth: 460),
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
