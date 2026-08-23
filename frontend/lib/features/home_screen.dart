import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper Rabbit'),
        actions: [
          IconButton(
            tooltip: 'Saved papers',
            onPressed: () => context.push('/bookmarks'),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 52,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Follow the research,\nnot the rabbit hole.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Search scholarly works, inspect their evidence trail, and discover the papers around them.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Search academic papers'),
                  ),
                ),
                const SizedBox(height: 40),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FeatureChip(
                      icon: Icons.manage_search,
                      label: 'Keyword & semantic search',
                    ),
                    _FeatureChip(
                      icon: Icons.account_tree_outlined,
                      label: 'References & citations',
                    ),
                    _FeatureChip(
                      icon: Icons.lightbulb_outline,
                      label: 'Related-paper discovery',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    );
  }
}
