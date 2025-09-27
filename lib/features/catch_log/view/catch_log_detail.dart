import 'package:flutter/material.dart';

import '../models/catch_log.dart';

class CatchLogDetailPage extends StatelessWidget {
  final CatchLog log;
  const CatchLogDetailPage({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(log.species)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (log.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                log.photoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              child: const Icon(Icons.image, size: 60, color: Colors.grey),
            ),
          const SizedBox(height: 16),

          // Species + location
          Text(log.species, style: Theme.of(context).textTheme.headlineSmall),
          if (log.locationName != null)
            Text(
              log.locationName!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

          const Divider(height: 32),

          // Measurements
          if (log.weight != null) Text("Weight: ${log.weight} kg"),
          if (log.length != null) Text("Length: ${log.length} cm"),
          if (log.bait != null) Text("Bait: ${log.bait}"),
          if (log.environment != null) Text("Environment: ${log.environment}"),

          const SizedBox(height: 16),

          // Notes
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            const Text("Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(log.notes!),
            const SizedBox(height: 16),
          ],

          // Date
          Text(
            "Caught on: ${log.createdAt.toLocal().toString().split(' ').first}",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
