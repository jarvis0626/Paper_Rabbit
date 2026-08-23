import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'papers/data/paper_models.dart';
import 'papers/data/paper_repository.dart';

class GraphScreen extends ConsumerStatefulWidget {
  const GraphScreen({super.key, this.paperId});

  final String? paperId;

  @override
  ConsumerState<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends ConsumerState<GraphScreen> {
  final _transformationController = TransformationController();
  Future<CitationGraph>? _graph;
  CitationGraphNode? _selected;
  bool _showReferences = true;
  bool _showCitations = true;
  bool _showTruncationNotice = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant GraphScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paperId != widget.paperId) {
      _load();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _load() {
    _selected = null;
    _showTruncationNotice = true;
    _transformationController.value = Matrix4.identity();
    _graph = widget.paperId == null
        ? null
        : ref.read(paperRepositoryProvider).getCitationGraph(widget.paperId!);
  }

  void _setScale(double scale) {
    _transformationController.value = Matrix4.diagonal3Values(scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citation explorer')),
      body: widget.paperId == null
          ? _ChoosePaper(onSearch: () => context.go('/search'))
          : FutureBuilder<CitationGraph>(
              future: _graph,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _GraphError(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(_load),
                  );
                }
                return _buildGraph(context, snapshot.requireData);
              },
            ),
    );
  }

  Widget _buildGraph(BuildContext context, CitationGraph graph) {
    final visibleNodes = graph.nodes.where((node) {
      return node.kind == CitationGraphNodeKind.root ||
          (node.kind == CitationGraphNodeKind.reference && _showReferences) ||
          (node.kind == CitationGraphNodeKind.citation && _showCitations);
    }).toList();
    final visibleIds = visibleNodes.map((node) => node.id).toSet();
    final visibleEdges = graph.edges
        .where(
          (edge) =>
              visibleIds.contains(edge.sourceId) &&
              visibleIds.contains(edge.targetId),
        )
        .toList();
    final layout = _GraphLayout.calculate(visibleNodes);

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    selected: _showReferences,
                    avatar: const Icon(Icons.arrow_outward, size: 16),
                    label: const Text('References'),
                    onSelected: (value) =>
                        setState(() => _showReferences = value),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _showCitations,
                    avatar: const Icon(Icons.south_west, size: 16),
                    label: const Text('Cited by'),
                    onSelected: (value) =>
                        setState(() => _showCitations = value),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    tooltip: 'Zoom out',
                    onPressed: () => _setScale(0.75),
                    icon: const Icon(Icons.zoom_out),
                  ),
                  IconButton(
                    tooltip: 'Reset view',
                    onPressed: () => _setScale(1),
                    icon: const Icon(Icons.center_focus_strong),
                  ),
                  IconButton(
                    tooltip: 'Zoom in',
                    onPressed: () => _setScale(1.25),
                    icon: const Icon(Icons.zoom_in),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selected != null)
          _SelectionBar(
            node: _selected!,
            isRoot: _selected!.id == graph.rootId,
            onClose: () => setState(() => _selected = null),
            onDetails: () =>
                context.push('/papers/${Uri.encodeComponent(_selected!.id)}'),
            onFocus: () => context.pushReplacement(
              '/graph/${Uri.encodeComponent(_selected!.id)}',
            ),
          ),
        if (graph.truncated && _showTruncationNotice)
          MaterialBanner(
            content: const Text(
              'Showing the most-cited neighbors. Select a node and make it the focus to keep exploring.',
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() => _showTruncationNotice = false),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.35,
            maxScale: 2.5,
            child: SizedBox(
              width: layout.size.width,
              height: layout.size.height,
              child: Stack(
                children: [
                  CustomPaint(
                    size: layout.size,
                    painter: _EdgePainter(
                      positions: layout.positions,
                      edges: visibleEdges,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  for (final node in visibleNodes)
                    Positioned(
                      left: layout.positions[node.id]!.dx - _nodeWidth / 2,
                      top: layout.positions[node.id]!.dy - _nodeHeight / 2,
                      child: _GraphNodeCard(
                        node: node,
                        selected: _selected?.id == node.id,
                        onTap: () => setState(() => _selected = node),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        _GraphLegend(
          nodeCount: visibleNodes.length,
          edgeCount: visibleEdges.length,
        ),
      ],
    );
  }
}

const double _nodeWidth = 220;
const double _nodeHeight = 112;

class _GraphLayout {
  const _GraphLayout({required this.positions, required this.size});

  final Map<String, Offset> positions;
  final Size size;

  static _GraphLayout calculate(List<CitationGraphNode> nodes) {
    final references = nodes
        .where((node) => node.kind == CitationGraphNodeKind.reference)
        .toList();
    final citations = nodes
        .where((node) => node.kind == CitationGraphNodeKind.citation)
        .toList();
    final height = math.max(
      720.0,
      (math.max(references.length, citations.length) + 1) * 145.0,
    );
    final size = Size(1200, height);
    final positions = <String, Offset>{};

    for (final node in nodes) {
      if (node.kind == CitationGraphNodeKind.root) {
        positions[node.id] = Offset(size.width / 2, size.height / 2);
      }
    }
    for (var index = 0; index < references.length; index++) {
      positions[references[index].id] = Offset(
        210,
        height * (index + 1) / (references.length + 1),
      );
    }
    for (var index = 0; index < citations.length; index++) {
      positions[citations[index].id] = Offset(
        size.width - 210,
        height * (index + 1) / (citations.length + 1),
      );
    }
    return _GraphLayout(positions: positions, size: size);
  }
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.positions,
    required this.edges,
    required this.color,
  });

  final Map<String, Offset> positions;
  final List<CitationGraphEdge> edges;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    for (final edge in edges) {
      final source = positions[edge.sourceId];
      final target = positions[edge.targetId];
      if (source == null || target == null) continue;
      final delta = target - source;
      final distance = delta.distance;
      if (distance == 0) continue;
      final direction = delta / distance;
      final start = source + direction * (_nodeWidth / 2);
      final end = target - direction * (_nodeWidth / 2 + 5);
      canvas.drawLine(start, end, paint);

      final angle = math.atan2(direction.dy, direction.dx);
      const arrowSize = 10.0;
      final path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowSize * math.cos(angle - math.pi / 6),
          end.dy - arrowSize * math.sin(angle - math.pi / 6),
        )
        ..lineTo(
          end.dx - arrowSize * math.cos(angle + math.pi / 6),
          end.dy - arrowSize * math.sin(angle + math.pi / 6),
        )
        ..close();
      canvas.drawPath(path, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) =>
      oldDelegate.positions != positions ||
      oldDelegate.edges != edges ||
      oldDelegate.color != color;
}

class _GraphNodeCard extends StatelessWidget {
  const _GraphNodeCard({
    required this.node,
    required this.selected,
    required this.onTap,
  });

  final CitationGraphNode node;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = switch (node.kind) {
      CitationGraphNodeKind.root => colors.primaryContainer,
      CitationGraphNodeKind.reference => colors.tertiaryContainer,
      CitationGraphNodeKind.citation => colors.secondaryContainer,
    };
    final icon = switch (node.kind) {
      CitationGraphNodeKind.root => Icons.my_location,
      CitationGraphNodeKind.reference => Icons.arrow_outward,
      CitationGraphNodeKind.citation => Icons.south_west,
    };

    return SizedBox(
      width: _nodeWidth,
      height: _nodeHeight,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 17),
                    const SizedBox(width: 6),
                    Text(switch (node.kind) {
                      CitationGraphNodeKind.root => 'Focus paper',
                      CitationGraphNodeKind.reference => 'Referenced by focus',
                      CitationGraphNodeKind.citation => 'Cites focus',
                    }, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    node.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  [
                    if (node.year != null) '${node.year}',
                    '${node.citationCount} citations',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.node,
    required this.isRoot,
    required this.onClose,
    required this.onDetails,
    required this.onFocus,
  });

  final CitationGraphNode node;
  final bool isRoot;
  final VoidCallback onClose;
  final VoidCallback onDetails;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                node.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(onPressed: onDetails, child: const Text('Details')),
            if (!isRoot)
              FilledButton.tonal(
                onPressed: onFocus,
                child: const Text('Make focus'),
              ),
            IconButton(
              tooltip: 'Close selection',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphLegend extends StatelessWidget {
  const _GraphLegend({required this.nodeCount, required this.edgeCount});

  final int nodeCount;
  final int edgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.touch_app_outlined, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Drag to pan · pinch or scroll to zoom · tap a paper to explore',
              ),
            ),
            Text('$nodeCount papers · $edgeCount links'),
          ],
        ),
      ),
    );
  }
}

class _ChoosePaper extends StatelessWidget {
  const _ChoosePaper({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_tree_outlined, size: 56),
          const SizedBox(height: 16),
          Text(
            'Choose a paper to explore its citation neighborhood.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            label: const Text('Search papers'),
          ),
        ],
      ),
    ),
  );
}

class _GraphError extends StatelessWidget {
  const _GraphError({required this.message, required this.onRetry});
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
