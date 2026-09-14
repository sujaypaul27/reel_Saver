import 'package:flutter/material.dart';

/// Placeholder screen displayed while video details are being fetched.
/// Full animation and details loading will be integrated in Phase 3.
class FetchingDetailsScreen extends StatelessWidget {
  final String? videoUrl;

  const FetchingDetailsScreen({
    super.key,
    this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fetching Details'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Fetching...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
