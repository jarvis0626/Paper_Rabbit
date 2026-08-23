import 'package:flutter/material.dart';

class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key, this.paperId});

  final String? paperId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citation Graph')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_tree_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Interactive graph view is the next milestone.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (paperId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'The details page already exposes this work\'s references and citations.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
