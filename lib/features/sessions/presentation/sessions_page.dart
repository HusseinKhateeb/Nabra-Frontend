import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/main_bottom_nav_bar.dart';
import '../domain/session_models.dart';
import '../utils/session_formatters.dart';
import 'session_history_controller.dart';

const Color _darkRed = Color(0xFFD32F2F);

class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({super.key});

  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionHistoryControllerProvider.notifier).refresh();
    });
  }

  Future<void> _confirmAndClearHistory(
    BuildContext context,
    SessionHistoryController controller,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('مسح كل الجلسات؟', textDirection: TextDirection.rtl),
          content: const Text(
            'سيتم حذف كل سجل الجلسات بشكل نهائي.',
            textDirection: TextDirection.rtl,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('مسح الكل'),
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
                ? 'تم مسح سجل الجلسات بنجاح.'
                : (ref.read(sessionHistoryControllerProvider).error ??
                    'فشل مسح سجل الجلسات.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SessionHistoryState state = ref.watch(sessionHistoryControllerProvider);
    final SessionHistoryController controller =
        ref.read(sessionHistoryControllerProvider.notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: 'العودة',
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.red,
              size: 18,
              textDirection: TextDirection.ltr,
            ),
            onPressed: () => context.go(AppRoutes.lipReading),
          ),
          title: const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(
                'سجل الجلسات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            IconButton(
              tooltip: 'مسح كل السجل',
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              onPressed: () async {
                await _confirmAndClearHistory(context, controller);
              },
            ),
          ],
        ),
        body: Column(
        children: <Widget>[
          if (state.loading) const LinearProgressIndicator(minHeight: 2),
          if (state.error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
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
                    child: const Text('إعادة المحاولة'),
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                                      ? 'تم حذف الجلسة بنجاح.'
                                      : (ref
                                              .read(sessionHistoryControllerProvider)
                                              .error ??
                                          'فشل حذف الجلسة.'),
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
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPrev: state.page > 0 ? () => controller.setPage(state.page - 1) : null,
            onNext: (state.totalPages > 0 && state.page < state.totalPages - 1)
                ? () => controller.setPage(state.page + 1)
                : null,
          ),
        ],
        ),
        bottomNavigationBar: Directionality(
          textDirection: TextDirection.ltr,
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
      ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.zero,
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
              'النتيجة النهائية: $finalResult',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'نتيجة الصوت: $audioResult',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('حذف'),
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
    required this.totalPages,
    required this.totalElements,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int totalElements;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: <Widget>[
          Text('الإجمالي: $totalElements'),
          const Spacer(),
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(totalPages == 0 ? 'الصفحة 0 / 0' : 'الصفحة ${page + 1} / $totalPages'),
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Icon(Icons.history, size: 56, color: Colors.grey),
            SizedBox(height: 8),
            Text('لا توجد جلسات حتى الآن.'),
          ],
        ),
      ),
    );
  }
}
