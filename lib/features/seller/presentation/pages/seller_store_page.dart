import 'package:flutter/material.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/uicons.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '_store_edit_sheet.dart';

class SellerStorePage extends StatefulWidget {
  const SellerStorePage({super.key});

  @override
  State<SellerStorePage> createState() => _SellerStorePageState();
}

class _SellerStorePageState extends State<SellerStorePage> {
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final client = sl<ApiClient>();
      final res = await client.get(ApiConstants.sellerStore);
      final data = res.data;
      if (data is List) {
        _stores = data.cast<Map<String, dynamic>>();
      } else if (data is Map<String, dynamic>) {
        _stores = [data];
      } else {
        _stores = [];
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  int get _localCount => _stores.where((s) => (s['type'] ?? 'local').toString().toLowerCase() == 'local').length;
  int get _globalCount => _stores.where((s) => (s['type'] ?? 'local').toString().toLowerCase() == 'global').length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My Stores')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Uicons.circleExclamation, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadStores, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStores,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      Text('My Stores', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      const SizedBox(height: 4),
                      Text('Manage all physical selling locations connected to your seller account.',
                        style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4))),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showStoreEditSheet(context, null),
                          icon: const Icon(Uicons.plus, size: 18),
                          label: const Text('Add Store', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildStat(cs, '${_stores.length}', 'Total stores'),
                          const SizedBox(width: 8),
                          _buildStat(cs, '$_localCount', 'Local stores'),
                          const SizedBox(width: 8),
                          _buildStat(cs, '$_globalCount', 'Global stores'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._stores.asMap().entries.map((e) => _buildStoreCard(context, e.value, e.key + 1)),
                      if (_stores.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                Icon(Uicons.shop, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                Text('No stores yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                                const SizedBox(height: 8),
                                Text('Add your first physical store to start listing products.',
                                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
                                  textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
  Widget _buildStat(ColorScheme cs, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context, Map<String, dynamic> store, int index) {
    final cs = Theme.of(context).colorScheme;
    final name = store['store_name']?.toString() ?? store['name']?.toString() ?? 'Unnamed Store';
    final type = (store['type'] ?? 'local').toString().toUpperCase();
    final isLocal = type == 'LOCAL';
    final status = store['status']?.toString() ?? 'draft';
    final logoUrl = ApiConstants.resolveImageUrl(store['logo_url']?.toString());

    final locationParts = <String>[];
    if (store['country'] != null) locationParts.add(store['country'].toString());
    if (store['region'] != null) locationParts.add(store['region'].toString());
    if (store['district'] != null) locationParts.add(store['district'].toString());
    final location = locationParts.isNotEmpty ? locationParts.join(', ') : 'Location not configured';

    final pickupLat = store['pickup_latitude'] ?? store['latitude'];
    final pickupLng = store['pickup_longitude'] ?? store['longitude'];
    final hasPickup = pickupLat != null && pickupLng != null;
    final pickupText = hasPickup ? 'Pickup GPS configured' : 'Pickup GPS not configured';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$index', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.3))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isLocal ? cs.primary : const Color(0xFF8B5CF6)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(type,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: isLocal ? cs.primary : const Color(0xFF8B5CF6))),
                ),
                const Spacer(),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(_capitalize(status),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AppNetworkImage(imageUrl: logoUrl, width: 48, height: 48, borderRadius: 10, placeholderIcon: Uicons.shop),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Uicons.mapPin, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
              const SizedBox(width: 6),
              Expanded(child: Text(location, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Uicons.location, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
              const SizedBox(width: 6),
              Text(pickupText, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => _showStoreEditSheet(context, store),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreEditSheet(BuildContext context, Map<String, dynamic>? store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StoreEditSheet(store: store, onSaved: _loadStores),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return const Color(0xFF22C55E);
      case 'pending': return const Color(0xFFF59E0B);
      case 'suspended':
      case 'rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFF9CA3AF);
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
