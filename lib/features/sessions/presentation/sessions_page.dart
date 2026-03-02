import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../session_history/presentation/session_history_providers.dart';
import '../../session_history/domain/session_history_model.dart';

const _darkRed = Color(0xFF8B0000);

class SessionsPage extends ConsumerWidget {
  const SessionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionHistoriesAsync = ref.watch(sessionHistoriesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _darkRed,
        foregroundColor: Colors.white,
        title: const Text('Session History'),
        elevation: 0,
      ),
      body: sessionHistoriesAsync.when(
        data: (sessionHistories) {
          if (sessionHistories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: _darkRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'There is no history session',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: _darkRed),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: sessionHistories.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final history = sessionHistories[index];
              return SessionHistoryCard(history: history);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: _darkRed),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: _darkRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading session history',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: _darkRed),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: _darkRed),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ref.invalidate(sessionHistoriesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SessionHistoryCard extends StatelessWidget {
  final SessionHistory history;

  const SessionHistoryCard({
    Key? key,
    required this.history,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: history.duration);
    final durationString =
        '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _darkRed, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.video_collection_outlined, color: _darkRed),
        title: Text(
          'Session: ${history.sessionId}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _darkRed,
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Duration: $durationString',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Started: ${_formatDateTime(history.startTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Input: ${history.inputType} • Output: ${history.outputType}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (history.notes != null)
              Text(
                'Result: ${history.notes}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to session history details
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
