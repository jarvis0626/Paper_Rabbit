import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/search'),
              child: const Text('Go to Search'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/bookmarks'),
              child: const Text('Go to Bookmarks'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/graph'),
              child: const Text('Go to Graph'),
            ),
          ],
        ),
      ),
    );
  }
}
