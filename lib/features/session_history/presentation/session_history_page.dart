import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_history_providers.dart';
import '../domain/session_history_model.dart';

class SessionHistoryPage extends ConsumerWidget {
  const SessionHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionHistoriesAsync = ref.watch(sessionHistoriesProvider);

    return Scaffold(
      appBar: AppBar(
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
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No session history found',
                    style: Theme.of(context).textTheme.bodyLarge,
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
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading session history',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildStatusIcon(history.status),
        title: Text(
          'Session: ${history.sessionId}',
          style: Theme.of(context).textTheme.titleMedium,
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
            if (history.notes != null)
              Text(
                'Notes: ${history.notes}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            history.status,
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: _getStatusColor(history.status).withOpacity(0.2),
          labelStyle: TextStyle(color: _getStatusColor(history.status)),
        ),
        onTap: () {
          // TODO: Navigate to session history details
        },
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    final color = _getStatusColor(status);
    final iconData = _getStatusIcon(status);
    return Icon(iconData, color: color);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'ACTIVE':
        return Colors.blue;
      case 'PAUSED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Icons.check_circle;
      case 'ACTIVE':
        return Icons.play_circle;
      case 'PAUSED':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
