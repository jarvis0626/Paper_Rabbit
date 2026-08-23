import 'package:flutter/material.dart';

import '../data/paper_models.dart';

class PaperCard extends StatelessWidget {
  const PaperCard({
    required this.paper,
    required this.onTap,
    super.key,
    this.compact = false,
  });

  final PaperSummary paper;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authors = paper.authors.map((author) => author.name).join(', ');
    final metadata = [
      if (paper.year != null) '${paper.year}',
      if (paper.venue?.trim().isNotEmpty == true) paper.venue!.trim(),
    ].join(' · ');
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paper.title,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              if (authors.isNotEmpty)
                Text(
                  authors,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.primary),
                ),
              if (metadata.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
              if (!compact &&
                  paper.abstractPreview?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  paper.abstractPreview!.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.4),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Metric(
                    icon: Icons.format_quote,
                    label: '${paper.citationCount} citations',
                  ),
                  if (paper.openAccess)
                    const _Metric(icon: Icons.lock_open, label: 'Open access'),
                  ...paper.topics
                      .take(compact ? 1 : 2)
                      .map(
                        (topic) => Chip(
                          label: Text(topic.name),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
  );
}
