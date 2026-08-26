import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/security/admin_access.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';
import '../../data/models/admin_models.dart';

class AdminRolesPage extends StatefulWidget {
  const AdminRolesPage({super.key});

  @override
  State<AdminRolesPage> createState() => _AdminRolesPageState();
}

class _AdminRolesPageState extends State<AdminRolesPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadRoles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roles & Permissions')),
      body: BlocBuilder<AdminCubit, AdminState>(
        buildWhen: (prev, curr) =>
            curr is AdminRolesLoaded ||
            curr is AdminLoading ||
            curr is AdminError ||
            curr is AdminRolePermissionsLoaded ||
            curr is AdminUserPermissionsLoaded ||
            curr is AdminActionSuccess,
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminError) {
            return _errorView(context, state.message);
          }
          if (state is AdminRolePermissionsLoaded) {
            return _rolePermissionsView(context, state);
          }
          if (state is AdminUserPermissionsLoaded) {
            return _userPermissionsView(context, state);
          }
          if (state is AdminRolesLoaded) {
            return _rolesList(context, state);
          }
          if (state is AdminActionSuccess) {
            return _rolesList(context, null);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _errorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Uicons.triangleWarning, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<AdminCubit>().loadRoles(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ─── Roles List ───
  Widget _rolesList(BuildContext context, AdminRolesLoaded? state) {
    if (state == null) {
      context.read<AdminCubit>().loadRoles();
      return const Center(child: CircularProgressIndicator());
    }

    final canAssign = AdminAccess.canAccessItem(
        GetIt.instance<TokenStorage>().currentUser, 'users.view');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('System Roles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('${state.roles.length} roles • ${state.allPermissions.length} permissions',
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 16),
        ...state.roles.map((role) => _roleCard(context, role, canAssign)),
        const SizedBox(height: 24),
        const Text('All Permissions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...state.allPermissions.map((p) => _permissionTile(p)),
      ],
    );
  }

  Widget _roleCard(BuildContext context, AdminRoleModel role, bool canAssign) {
    final color = _roleColor(role.name);
    final isSuperAdmin = role.name == 'super_admin';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Uicons.userShield, color: color),
        ),
        title: Text(_roleDisplayName(role.name),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (role.description != null) ...[
              const SizedBox(height: 4),
              Text(role.description!, style: const TextStyle(fontSize: 12)),
            ],
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(isSuperAdmin ? 'All Permissions' : 'Custom Permissions',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
        trailing: canAssign && !isSuperAdmin
            ? const Icon(Uicons.angleRight)
            : null,
        onTap: canAssign && !isSuperAdmin
            ? () => context.read<AdminCubit>().loadRolePermissions(role.id)
            : null,
      ),
    );
  }

  Widget _permissionTile(AdminPermissionModel perm) {
    return ListTile(
      dense: true,
      leading: Icon(Uicons.checkCircle, size: 16, color: Colors.blue.shade300),
      title: Text(perm.code, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
      subtitle: perm.description != null
          ? Text(perm.description!, style: const TextStyle(fontSize: 11))
          : null,
    );
  }

  // ─── Role Permissions Editor ───
  Widget _rolePermissionsView(
      BuildContext context, AdminRolePermissionsLoaded state) {
    final rolePerms = state.rolePermissions;
    final allPerms = state.allPermissions;
    final selected = Set<String>.from(rolePerms.permissions);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Uicons.angleLeft),
                onPressed: () => context.read<AdminCubit>().loadRoles(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_roleDisplayName(rolePerms.roleName),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${selected.length} of ${allPerms.length} permissions',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allPerms.length,
                      itemBuilder: (context, index) {
                        final perm = allPerms[index];
                        final isChecked = selected.contains(perm.code);
                        return CheckboxListTile(
                          value: isChecked,
                          title: Text(perm.code,
                              style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                          subtitle: perm.description != null
                              ? Text(perm.description!, style: const TextStyle(fontSize: 11))
                              : null,
                          onChanged: (val) {
                            setLocalState(() {
                              if (val == true) {
                                selected.add(perm.code);
                              } else {
                                selected.remove(perm.code);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white),
                        icon: const Icon(Uicons.checkCircle, size: 18),
                        label: const Text('Save Permissions'),
                        onPressed: () {
                          context
                              .read<AdminCubit>()
                              .updateRolePermissions(rolePerms.roleId, selected.toList());
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── User Permissions Editor ───
  Widget _userPermissionsView(
      BuildContext context, AdminUserPermissionsLoaded state) {
    final userPerms = state.userPermissions;
    final allPerms = state.allPermissions;
    final selected = Set<String>.from(userPerms.permissions);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Uicons.angleLeft),
                onPressed: () => context.read<AdminCubit>().loadRoles(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.userName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${selected.length} direct permissions',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allPerms.length,
                      itemBuilder: (context, index) {
                        final perm = allPerms[index];
                        final isChecked = selected.contains(perm.code);
                        return CheckboxListTile(
                          value: isChecked,
                          title: Text(perm.code,
                              style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                          subtitle: perm.description != null
                              ? Text(perm.description!, style: const TextStyle(fontSize: 11))
                              : null,
                          onChanged: (val) {
                            setLocalState(() {
                              if (val == true) {
                                selected.add(perm.code);
                              } else {
                                selected.remove(perm.code);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white),
                        icon: const Icon(Uicons.checkCircle, size: 18),
                        label: const Text('Save Permissions'),
                        onPressed: () {
                          context
                              .read<AdminCubit>()
                              .assignUserPermissions(userPerms.userId, selected.toList());
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───
  Color _roleColor(String name) {
    switch (name) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.blue;
      case 'seller':
        return Colors.orange;
      case 'customer':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  String _roleDisplayName(String name) {
    switch (name) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'seller':
        return 'Seller';
      case 'customer':
        return 'Customer';
      default:
        return name.split('_').map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }
  }
}
