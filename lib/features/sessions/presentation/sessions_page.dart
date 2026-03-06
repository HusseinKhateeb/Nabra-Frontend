import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/main_bottom_nav_bar.dart';
import '../domain/session_models.dart';
import '../utils/session_formatters.dart';
import 'session_history_controller.dart';

const Color _darkRed = Color(0xFF8B0000);

class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({super.key});

  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage> {
  final TextEditingController _minDurationController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();

  Future<void> _confirmAndClearHistory(
    BuildContext context,
    SessionHistoryController controller,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear all sessions?'),
          content: const Text(
            'This will delete all your session history permanently.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final bool ok = await controller.clearAllSessions();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Session history cleared successfully.'
                : (ref.read(sessionHistoryControllerProvider).error ??
                    'Failed to clear session history.'),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _minDurationController.dispose();
    _maxDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SessionHistoryState state = ref.watch(sessionHistoryControllerProvider);
    final SessionHistoryController controller =
        ref.read(sessionHistoryControllerProvider.notifier);

    _minDurationController.value = _minDurationController.value.copyWith(
      text: state.filters.minDuration?.toString() ?? '',
      selection: TextSelection.collapsed(
        offset: (state.filters.minDuration?.toString() ?? '').length,
      ),
      composing: TextRange.empty,
    );

    _maxDurationController.value = _maxDurationController.value.copyWith(
      text: state.filters.maxDuration?.toString() ?? '',
      selection: TextSelection.collapsed(
        offset: (state.filters.maxDuration?.toString() ?? '').length,
      ),
      composing: TextRange.empty,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53935),
        title: const Text('Session History'),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0.5,
        actions: <Widget>[
          IconButton(
            tooltip: 'Clear all history',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              await _confirmAndClearHistory(context, controller);
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (state.loading) const LinearProgressIndicator(minHeight: 2),
          _FilterPanel(
            filters: state.filters,
            minDurationController: _minDurationController,
            maxDurationController: _maxDurationController,
            onFromChanged: (value) => controller.updateFilters(<String, dynamic>{
              'from': value == null
                  ? null
                  : DateTime(value.year, value.month, value.day),
            }),
            onToChanged: (value) => controller.updateFilters(<String, dynamic>{
              'to': value == null
                  ? null
                  : DateTime(
                      value.year,
                      value.month,
                      value.day,
                      23,
                      59,
                      59,
                      999,
                    ),
            }),
            onApply: () => controller.updateFilters(
              <String, dynamic>{
                'minDuration': int.tryParse(_minDurationController.text.trim()),
                'maxDuration': int.tryParse(_maxDurationController.text.trim()),
              },
            ),
            onClearHistory: () async {
              await _confirmAndClearHistory(context, controller);
            },
            onResetFilters: () async {
              _minDurationController.clear();
              _maxDurationController.clear();
              await controller.resetFilters();
            },
          ),
          if (state.error != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFE5E5),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded, color: _darkRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: _darkRed),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: state.sessions.isEmpty && !state.loading
                ? const _EmptySessions()
                : RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: state.sessions.length,
                      itemBuilder: (BuildContext context, int index) {
                        final SessionResponse current = state.sessions[index];
                        return _SessionCard(
                          session: current,
                          onDelete: () async {
                            final bool ok = await controller.deleteSession(current.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Session deleted successfully.'
                                      : (ref
                                              .read(sessionHistoryControllerProvider)
                                              .error ??
                                          'Failed to delete session.'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
          _PaginationBar(
            page: state.page,
            size: state.size,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPrev: state.page > 0 ? () => controller.setPage(state.page - 1) : null,
            onNext: (state.totalPages > 0 && state.page < state.totalPages - 1)
                ? () => controller.setPage(state.page + 1)
                : null,
            onSizeChanged: (int newSize) => controller.setSize(newSize),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: MainBottomNavBar(
          currentIndex: 1,
          onTap: (int index) {
            switch (index) {
              case 0:
                context.go(AppRoutes.dictionary);
                break;
              case 1:
                break;
              case 2:
                context.go(AppRoutes.lipReading);
                break;
              case 3:
                context.go(AppRoutes.profile);
                break;
              case 4:
                context.go(AppRoutes.chats);
                break;
            }
          },
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.filters,
    required this.minDurationController,
    required this.maxDurationController,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onApply,
    required this.onClearHistory,
    required this.onResetFilters,
  });

  final SessionFilters filters;
  final TextEditingController minDurationController;
  final TextEditingController maxDurationController;
  final ValueChanged<DateTime?> onFromChanged;
  final ValueChanged<DateTime?> onToChanged;
  final VoidCallback onApply;
  final VoidCallback onClearHistory;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _DateFilterButton(
                    label: 'From',
                    value: filters.from,
                    onChanged: onFromChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateFilterButton(
                    label: 'To',
                    value: filters.to,
                    onChanged: onToChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Search by date range and duration only.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: minDurationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Min duration (sec)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: maxDurationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Max duration (sec)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onResetFilters,
                    child: const Text('Reset Filters'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClearHistory,
                    child: const Text('Clear History'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApply,
                    style: ElevatedButton.styleFrom(backgroundColor: _darkRed),
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final DateTime initial = value ?? DateTime.now();
        final DateTime? picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDate: initial,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text('$label: ${formatSessionDateTime(value)}'),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onDelete});

  final SessionResponse session;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final String finalResult = safeText(
      session.content?.result?.fusedWord ??
          session.content?.result?.lipWord ??
          session.resultText,
    );
    final String audioResult = safeText(
      session.content?.result?.audioText ?? session.resultText,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    formatSessionDateTime(session.startedAt),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusBadge(status: session.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Final result: $finalResult',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Audio result: $audioResult',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SessionStatus? status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case SessionStatus.active:
        color = Colors.blue;
        break;
      case SessionStatus.completed:
        color = Colors.green;
        break;
      case SessionStatus.failed:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.onPrev,
    required this.onNext,
    required this.onSizeChanged,
  });

  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: <Widget>[
          Text('Total: $totalElements'),
          const Spacer(),
          DropdownButton<int>(
            value: size,
            items: const <int>[10, 20, 50]
                .map((int value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value/page'),
                    ))
                .toList(growable: false),
            onChanged: (int? value) {
              if (value != null) onSizeChanged(value);
            },
          ),
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(totalPages == 0 ? 'Page 0 / 0' : 'Page ${page + 1} / $totalPages'),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Icon(Icons.history, size: 56, color: Colors.grey),
          SizedBox(height: 8),
          Text('No sessions found for the selected filters.'),
        ],
      ),
    );
  }
}
