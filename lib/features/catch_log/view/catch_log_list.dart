import 'package:anglers_spot/features/catch_log/view/catch_log_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catch_log_provider.dart';
import 'catch_log_form.dart';

class CatchLogListPage extends ConsumerWidget {
  const CatchLogListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLogs = ref.watch(catchLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("My Catch Logs")),
      body: asyncLogs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error: $e")),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text("No catches logged yet."));
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: log.photoUrl != null
                      ? Image.network(
                          log.photoUrl!,
                          width: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported, size: 40),
                  title: Text(
                    log.species,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${log.locationName ?? 'Unknown location'} • "
                    "${log.createdAt.toLocal().toString().split(' ').first}",
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (log.weight != null) Text("${log.weight} kg"),
                      if (log.length != null) Text("${log.length} cm"),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CatchLogDetailPage(log: log),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CatchLogForm()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
