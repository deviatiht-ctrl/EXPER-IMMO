import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static final _drawerItems = <_DrawerItem>[
    _DrawerItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', path: '/admin'),
    _DrawerItem(icon: Icons.home_work_outlined, label: 'Propriétés', path: '/admin/proprietes'),
    _DrawerItem(icon: Icons.people_outline, label: 'Propriétaires', path: '/admin/proprietaires'),
    _DrawerItem(icon: Icons.person_outline, label: 'Locataires', path: '/admin/locataires'),
    _DrawerItem(icon: Icons.description_outlined, label: 'Contrats', path: '/admin/contrats'),
    _DrawerItem(icon: Icons.payments_outlined, label: 'Paiements', path: '/admin/paiements'),
    _DrawerItem(icon: Icons.receipt_long_outlined, label: 'Factures', path: '/admin/factures'),
    _DrawerItem(icon: Icons.engineering_outlined, label: 'Opérations', path: '/admin/operations'),
    _DrawerItem(icon: Icons.bar_chart_outlined, label: 'Statistiques', path: '/admin/statistiques'),
    _DrawerItem(icon: Icons.message_outlined, label: 'Messages', path: '/admin/messages'),
    _DrawerItem(icon: Icons.settings_outlined, label: 'Paramètres', path: '/admin/parametres'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const AppLogo(size: 36),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.adminColor,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            onSelected: (v) async {
              if (v == 'logout') {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('Mon Profil')),
              const PopupMenuItem(value: 'logout', child: Text('Déconnexion')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.adminSidebar,
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: AppLogo(size: 40, light: true),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: _drawerItems.map((item) {
                    final active = currentPath == item.path;
                    return ListTile(
                      leading: Icon(item.icon, color: active ? AppColors.adminAccent : Colors.white60, size: 20),
                      title: Text(item.label, style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: active ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
                      selected: active,
                      selectedTileColor: Colors.white.withOpacity(0.06),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      dense: true,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.path);
                      },
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('EXPERIMMO Admin v1.0', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final String path;
  const _DrawerItem({required this.icon, required this.label, required this.path});
}
