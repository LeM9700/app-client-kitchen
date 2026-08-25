import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/account/models/session.dart';
import 'package:app_client/features/account/providers/account_provider.dart';

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} à '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Sessions actives — `GET /auth/sessions?current_session_id=` (plan-18,
/// api-corrections-phase-d §8). La session courante ([Session.isCurrent])
/// n'est jamais révocable depuis cet écran — protection contre
/// l'auto-déconnexion accidentelle (Décision d'architecture n°1, plan-18).
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final Set<int> _revokingIds = {};

  Future<void> _revoke(Session session) async {
    setState(() => _revokingIds.add(session.id));
    try {
      await ref.read(sessionActionsProvider).revoke(session.id);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _revokingIds.remove(session.id));
    }
  }

  Future<void> _confirmRevoke(Session session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Révoquer cette session ?'),
        content: const Text(
          'Cet appareil sera déconnecté immédiatement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
            ),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _revoke(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sessions actives')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(sessionsProvider),
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: e is AppException
                ? e.message
                : 'Impossible de charger les sessions.',
            onRetry: () => ref.invalidate(sessionsProvider),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Aucune session active.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final session = sessions[i];
                final isRevoking = _revokingIds.contains(session.id);
                return ListTile(
                  leading: Icon(
                    session.isMobileDevice
                        ? Icons.phone_android
                        : Icons.computer,
                  ),
                  title: Text(
                    session.userAgent?.isNotEmpty == true
                        ? session.userAgent!
                        : 'Appareil inconnu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${session.ipAddress ?? 'IP inconnue'} · '
                    'Créée le ${_formatDateTime(session.createdAt)}',
                  ),
                  trailing: session.isCurrent
                      ? const Chip(label: Text('Actuelle'))
                      : isRevoking
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Color(0xFFB71C1C),
                              ),
                              tooltip: 'Révoquer cette session',
                              onPressed: () => _confirmRevoke(session),
                            ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ),
        ),
      ],
    );
  }
}
