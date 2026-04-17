import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';

class LocataireShell extends ConsumerWidget {
  final Widget child;
  const LocataireShell({super.key, required this.child});

  static const _navItems = <_NavItem>[
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Accueil', path: '/locataire'),
    _NavItem(icon: Icons.description_outlined, activeIcon: Icons.description, label: 'Contrat', path: '/locataire/contrat'),
    _NavItem(icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Paiements', path: '/locataire/paiements'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Factures', path: '/locataire/factures'),
    _NavItem(icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'Plus', path: ''),
  ];

  static const _moreItems = <_NavItem>[
    _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Échéances', path: '/locataire/echeances'),
    _NavItem(icon: Icons.chat_outlined, activeIcon: Icons.chat, label: 'Messagerie', path: '/locataire/messagerie'),
    _NavItem(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Documents', path: '/locataire/documents'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', path: '/locataire/profil'),
  ];

  int _currentIndex(String path) {
    for (int i = 0; i < _navItems.length - 1; i++) {
      if (path == _navItems[i].path) return i;
    }
    for (final item in _moreItems) {
      if (path == item.path) return _navItems.length - 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final idx = _currentIndex(currentPath);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(size: 34),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, size: 22), onPressed: () {}),
          IconButton(
            icon: const CircleAvatar(radius: 15, backgroundColor: AppColors.locataireColor, child: Icon(Icons.person, size: 16, color: Colors.white)),
            onPressed: () => context.go('/locataire/profil'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        selectedItemColor: AppColors.locataireColor,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (i) {
          if (i == _navItems.length - 1) {
            _showMoreSheet(context);
            return;
          }
          context.go(_navItems[i].path);
        },
        items: _navItems.map((n) => BottomNavigationBarItem(
          icon: Icon(n.icon, size: 22),
          activeIcon: Icon(n.activeIcon, size: 22),
          label: n.label,
        )).toList(),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ..._moreItems.map((item) => ListTile(
                leading: Icon(item.icon, color: AppColors.locataireColor),
                title: Text(item.label),
                onTap: () { Navigator.pop(context); context.go(item.path); },
              )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text('Déconnexion', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Navigator.pop(context);
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.path});
}
