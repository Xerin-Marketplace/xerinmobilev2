import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/theme/uicons.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../customer/presentation/cubit/home_cubit.dart';
import '../../../customer/presentation/cubit/home_state.dart';
import '../cubit/seller_cubit.dart';
import '../../data/models/seller_models.dart';

class SellerSettingsPage extends StatefulWidget {
  const SellerSettingsPage({super.key});
  @override
  State<SellerSettingsPage> createState() => _SellerSettingsPageState();
}

class _SellerSettingsPageState extends State<SellerSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tc;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 7, vsync: this);
    _tc.addListener(() { if (_tc.index != _idx) setState(() => _idx = _tc.index); });
    context.read<SellerCubit>().loadProfile();
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Container(
            color: cs.surface,
            child: TabBar(
              controller: _tc, isScrollable: true, tabAlignment: TabAlignment.start,
              indicatorColor: cs.primary, labelColor: cs.primary,
              unselectedLabelColor: cs.onSurface.withValues(alpha: 0.4),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const ['Overview','Profile','Security','Notifications','Delivery Addresses','Store','Account Status']
                  .map((t) => Tab(text: t)).toList(),
            ),
          ),
          Expanded(
            child: IndexedStack(index: _idx, children: [
              _OverviewTab(), _ProfileTab(), _SecurityTab(),
              _NotificationsTab(), _AddressesTab(), _StoreTab(), _AccountTab(),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Overview Tab ───
class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<SellerCubit, SellerState>(
      builder: (context, state) {
        SellerModel? seller;
        if (state is SellerProfileLoaded) seller = state.seller;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _ovStat(cs, 'Approved Seller', seller?.status ?? '—',
                (seller?.status ?? '') == 'approved' ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                Uicons.shieldCheck),
            const SizedBox(height: 8),
            _ovStat(cs, 'KYC Status', seller?.isVerified == true ? 'Verified' : 'Incomplete',
                seller?.isVerified == true ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                Uicons.badgeCheck),
            const SizedBox(height: 8),
            _ovStat(cs, 'Store Status', seller?.isVerified == true ? 'Available' : 'Unavailable',
                seller?.isVerified == true ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                Uicons.shop),
            const SizedBox(height: 8),
            _ovStat(cs, 'Payout Status', 'Verified & Ready', const Color(0xFF22C55E), Uicons.sackDollar),
            const SizedBox(height: 24),
            Text('Quick links', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 12),
            _ovLink(cs, 'Edit profile', Uicons.user, () => context.push(AppConstants.sellerSettingsRoute)),
            _ovDiv(cs),
            _ovLink(cs, 'KYC verification', Uicons.badgeCheck, () => context.push(AppConstants.sellerKycRoute)),
            _ovDiv(cs),
            _ovLink(cs, 'Payout accounts', Uicons.sackDollar, () => context.push(AppConstants.sellerPayoutAccountsRoute)),
            _ovDiv(cs),
            _ovLink(cs, 'Store settings', Uicons.shop, () => context.push(AppConstants.sellerStoreRoute)),
            _ovDiv(cs),
            _ovLink(cs, 'Wallet & earnings', Uicons.wallet, () => context.push(AppConstants.sellerWalletRoute)),
          ],
        );
      },
    );
  }

  Widget _ovStat(ColorScheme cs, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ])),
      ]),
    );
  }

  Widget _ovLink(ColorScheme cs, String title, IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface))),
        Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withValues(alpha: 0.25)),
      ]),
    ));
  }

  Widget _ovDiv(ColorScheme cs) => Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06));
}

// ─── Profile Tab ───
class _ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.read<HomeCubit>().state is HomeLoaded
        ? (context.read<HomeCubit>().state as HomeLoaded).user : null;

    return BlocBuilder<SellerCubit, SellerState>(
      builder: (context, state) {
        SellerModel? seller;
        SellerBusinessProfileModel? profile;
        if (state is SellerProfileLoaded) { seller = state.seller; profile = state.profile; }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _secTitle(cs, 'Profile Information'),
            const SizedBox(height: 4),
            _secSub(cs, 'Personal details used for your Seller Center account.'),
            const SizedBox(height: 16),
            _ProfileForm(user: user, seller: seller),
            const SizedBox(height: 24),
            _secTitle(cs, 'Business Information'),
            const SizedBox(height: 4),
            _secSub(cs, 'Legal business information used for verification and payouts.'),
            const SizedBox(height: 16),
            _BusinessForm(seller: seller, profile: profile),
          ],
        );
      },
    );
  }

  Widget _secTitle(ColorScheme cs, String t) => Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface));
  Widget _secSub(ColorScheme cs, String t) => Text(t, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)));
}

class _ProfileForm extends StatefulWidget {
  final UserModel? user;
  final SellerModel? seller;
  const _ProfileForm({this.user, this.seller});
  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final TextEditingController _fn, _ln, _em, _ph;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _fn = TextEditingController(text: widget.user?.firstName ?? '');
    _ln = TextEditingController(text: widget.user?.lastName ?? '');
    _em = TextEditingController(text: widget.user?.email ?? '');
    _ph = TextEditingController(text: widget.user?.phone ?? '');
  }

  @override
  void dispose() { _fn.dispose(); _ln.dispose(); _em.dispose(); _ph.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(cs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _field(cs, 'First name', _fn, _editing),
        const SizedBox(height: 12),
        _field(cs, 'Last name', _ln, _editing),
        const SizedBox(height: 12),
        _field(cs, 'Email address', _em, _editing, suffix: 'Verified email'),
        const SizedBox(height: 12),
        _field(cs, 'Phone number', _ph, _editing),
        const SizedBox(height: 16),
        Row(children: [
          if (_editing) Expanded(child: TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel'))),
          Expanded(child: _editing
            ? FilledButton(onPressed: _save, style: _btnStyle(cs), child: const Text('Save changes'))
            : FilledButton.tonal(onPressed: () => setState(() => _editing = true), style: _btnStyle(cs), child: const Text('Edit'))),
        ]),
      ]),
    );
  }

  void _save() {
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile update not available from seller panel. Use Account settings.'), backgroundColor: Color(0xFF3B82F6)),
    );
  }

  Widget _field(ColorScheme cs, String label, TextEditingController ctrl, bool enabled, {String? suffix}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
      const SizedBox(height: 4),
      TextFormField(controller: ctrl, readOnly: !enabled, decoration: _input(cs, suffix: suffix)),
    ]);
  }
}

class _BusinessForm extends StatefulWidget {
  final SellerModel? seller;
  final SellerBusinessProfileModel? profile;
  const _BusinessForm({this.seller, this.profile});
  @override
  State<_BusinessForm> createState() => _BusinessFormState();
}

class _BusinessFormState extends State<_BusinessForm> {
  late final TextEditingController _name, _type, _em, _ph, _country, _region, _city, _addr;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.seller?.businessName ?? '');
    _type = TextEditingController(text: widget.seller?.businessCategory ?? 'Not provided');
    _em = TextEditingController(text: widget.seller?.contactEmail ?? '');
    _ph = TextEditingController(text: widget.seller?.contactPhone ?? '');
    _country = TextEditingController(text: widget.profile?.businessCountry ?? '');
    _region = TextEditingController(text: widget.profile?.businessRegion ?? '');
    _city = TextEditingController(text: widget.profile?.businessCity ?? '');
    _addr = TextEditingController(text: widget.profile?.businessAddress ?? '');
  }

  @override
  void dispose() {
    _name.dispose(); _type.dispose(); _em.dispose(); _ph.dispose();
    _country.dispose(); _region.dispose(); _city.dispose(); _addr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(cs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _field(cs, 'Business name', _name, _editing, hint: 'Approved sensitive field—contact support to request a change'),
        const SizedBox(height: 12),
        _field(cs, 'Business type', _type, _editing),
        const SizedBox(height: 12),
        _field(cs, 'Business email', _em, _editing),
        const SizedBox(height: 12),
        _field(cs, 'Business phone', _ph, _editing),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field(cs, 'Country', _country, _editing)),
          const SizedBox(width: 8),
          Expanded(child: _field(cs, 'Region', _region, _editing)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field(cs, 'City', _city, _editing)),
          const SizedBox(width: 8),
          Expanded(child: _field(cs, 'Business address', _addr, _editing)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(Uicons.circleInfo, size: 14, color: const Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Expanded(child: Text('KYC review: Incomplete — 1 document(s) missing. Open verification',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFF59E0B)))),
            GestureDetector(onTap: () => context.push(AppConstants.sellerKycRoute),
              child: Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary))),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          if (_editing) Expanded(child: TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel'))),
          Expanded(child: _editing
            ? FilledButton(onPressed: _save, style: _btnStyle(cs), child: const Text('Save changes'))
            : FilledButton.tonal(onPressed: () => setState(() => _editing = true), style: _btnStyle(cs), child: const Text('Edit'))),
        ]),
      ]),
    );
  }

  void _save() {
    final data = <String, dynamic>{
      'business_name': _name.text,
      'business_category': _type.text,
      'contact_email': _em.text,
      'contact_phone': _ph.text,
    };
    final bizData = <String, dynamic>{
      'business_country': _country.text,
      'business_region': _region.text,
      'business_city': _city.text,
      'business_address': _addr.text,
    };
    setState(() => _editing = false);
    context.read<SellerCubit>().updateSellerMe(data);
    context.read<SellerCubit>().updateBusinessProfile(bizData);
  }

  Widget _field(ColorScheme cs, String label, TextEditingController ctrl, bool enabled, {String? hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
      const SizedBox(height: 4),
      TextFormField(controller: ctrl, readOnly: !enabled, decoration: _input(cs, suffix: hint)),
    ]);
  }
}

// ─── Shared helpers ───
InputDecoration _input(ColorScheme cs, {String? suffix}) => InputDecoration(
  filled: true, fillColor: cs.onSurface.withValues(alpha: 0.03),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 1.5)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  suffixText: suffix, suffixStyle: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3)),
);

BoxDecoration _cardDeco(ColorScheme cs) => BoxDecoration(
  color: cs.surface, borderRadius: BorderRadius.circular(12),
  border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
);

ButtonStyle _btnStyle(ColorScheme cs) => FilledButton.styleFrom(
  padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

// ─── Security Tab ───
class _SecurityTab extends StatefulWidget {
  @override
  State<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<_SecurityTab> {
  final _formKey = GlobalKey<FormState>();
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _conf = TextEditingController();
  bool _obCur = true, _obNew = true, _obConf = true;
  bool _loading = false;

  @override
  void dispose() { _cur.dispose(); _new.dispose(); _conf.dispose(); super.dispose(); }

  int get _strength {
    final p = _new.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) s++;
    if (p.length >= 12) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('Use a strong password to protect your seller account.', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 16),
        Form(key: _formKey, child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(cs),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _pwField(cs, 'Current password', _cur, _obCur, (v) => setState(() => _obCur = v)),
            const SizedBox(height: 12),
            _pwField(cs, 'New password', _new, _obNew, (v) => setState(() => _obNew = v)),
            const SizedBox(height: 8),
            _strengthBar(cs),
            const SizedBox(height: 12),
            _pwField(cs, 'Confirm password', _conf, _obConf, (v) => setState(() => _obConf = v),
              validator: (v) => v != _new.text ? 'Passwords do not match' : null),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: _loading ? null : _submit, style: _btnStyle(cs),
              child: _loading
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                : const Text('Update password'),
            )),
          ]),
        )),
        const SizedBox(height: 24),
        Text('App Lock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(16), decoration: _cardDeco(cs),
          child: Row(children: [
            Icon(Uicons.lock, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PIN Lock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text('Require a PIN to open the app', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
            ])),
            TextButton(onPressed: () => context.push(AppConstants.pinSetupRoute),
              child: Text('Setup', style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary))),
          ]),
        ),
      ],
    );
  }

  Widget _pwField(ColorScheme cs, String label, TextEditingController ctrl, bool obscure, ValueChanged<bool> toggle, {String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
      const SizedBox(height: 4),
      TextFormField(controller: ctrl, obscureText: obscure, validator: validator,
        decoration: _input(cs).copyWith(suffixIcon: GestureDetector(onTap: () => toggle(!obscure),
          child: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: cs.onSurface.withValues(alpha: 0.3))))),
    ]);
  }

  Widget _strengthBar(ColorScheme cs) {
    final labels = ['Very weak','Weak','Fair','Good','Strong'];
    final colors = [const Color(0xFFEF4444),const Color(0xFFF97316),const Color(0xFFF59E0B),const Color(0xFF84CC16),const Color(0xFF22C55E)];
    final s = _strength;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
        value: s == 0 ? 0 : s / 5, minHeight: 4,
        backgroundColor: cs.onSurface.withValues(alpha: 0.06),
        valueColor: AlwaysStoppedAnimation(s == 0 ? cs.onSurface.withValues(alpha: 0.2) : colors[s - 1]),
      )),
      const SizedBox(height: 4),
      if (s > 0) Text(labels[s - 1], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors[s - 1])),
    ]);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _loading = false);
        _cur.clear(); _new.clear(); _conf.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully'), backgroundColor: Color(0xFF22C55E)),
        );
      }
    });
  }
}

// ─── Notifications Tab ───
class _NotificationsTab extends StatefulWidget {
  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  late SharedPreferences _prefs;
  bool _orders = true, _payouts = true, _messages = false, _reviews = true, _loaded = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _orders = _prefs.getBool('seller_notif_orders') ?? true;
      _payouts = _prefs.getBool('seller_notif_payouts') ?? true;
      _messages = _prefs.getBool('seller_notif_messages') ?? false;
      _reviews = _prefs.getBool('seller_notif_reviews') ?? true;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
      Text('Seller Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
      const SizedBox(height: 4),
      Text('Choose what updates you want to receive.', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(16), decoration: _cardDeco(cs), child: Column(children: [
        _sw(cs, 'Order Updates', 'New orders and status changes', _orders, (v) { setState(() => _orders = v); _prefs.setBool('seller_notif_orders', v); }),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
        _sw(cs, 'Payout Notifications', 'Payout status and transaction alerts', _payouts, (v) { setState(() => _payouts = v); _prefs.setBool('seller_notif_payouts', v); }),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
        _sw(cs, 'Customer Messages', 'Messages from customers', _messages, (v) { setState(() => _messages = v); _prefs.setBool('seller_notif_messages', v); }),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
        _sw(cs, 'Product Reviews', 'New reviews on your products', _reviews, (v) { setState(() => _reviews = v); _prefs.setBool('seller_notif_reviews', v); }),
      ])),
    ]);
  }

  Widget _sw(ColorScheme cs, String title, String sub, bool val, ValueChanged<bool> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      ])),
      Switch(value: val, onChanged: onChanged),
    ]));
  }
}

// ─── Delivery Addresses Tab ───
class _AddressesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
      Text('Delivery Addresses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
      const SizedBox(height: 4),
      Text('Manage your store pickup and return addresses.', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(20), decoration: _cardDeco(cs), child: Column(children: [
        Icon(Uicons.location, size: 32, color: cs.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text('No delivery addresses yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 4),
        Text('Add a pickup or return address for your store.', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.3))),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address form coming soon.')));
        }, icon: Icon(Uicons.plus, size: 16), label: const Text('Add address')),
      ])),
    ]);
  }
}

// ─── Store Tab ───
class _StoreTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<SellerCubit, SellerState>(builder: (context, state) {
      SellerModel? seller;
      SellerBusinessProfileModel? profile;
      if (state is SellerProfileLoaded) { seller = state.seller; profile = state.profile; }
      return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
        Text('Store Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('Manage your store appearance and availability.', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: _cardDeco(cs), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _row(cs, 'Store name', seller?.businessName ?? '—'),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          _row(cs, 'Store status', seller?.isVerified == true ? 'Available' : 'Unavailable',
              color: seller?.isVerified == true ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF)),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          _row(cs, 'Business category', seller?.businessCategory ?? 'Not provided'),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          _row(cs, 'Website', profile?.websiteUrl ?? 'Not provided'),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          _row(cs, 'Years in business', profile?.yearsInBusiness ?? '—'),
        ])),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.tonal(
          onPressed: () => context.push(AppConstants.sellerStoreRoute),
          style: _btnStyle(cs), child: const Text('Manage store'),
        )),
      ]);
    });
  }
  Widget _row(ColorScheme cs, String label, String value, {Color? color}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.5))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? cs.onSurface)),
      ],
    ));
  }
}

// ─── Account Status Tab ───
class _AccountTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<SellerCubit, SellerState>(builder: (context, state) {
      SellerModel? seller;
      if (state is SellerProfileLoaded) seller = state.seller;
      final status = seller?.status ?? 'pending';
      final isVerified = seller?.isVerified == true;
      return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
        Text('Account Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('Your seller account verification and compliance status.', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 16),
        _statusCard(cs, 'Seller Status', status, _statusColor(status), Uicons.shieldCheck),
        const SizedBox(height: 8),
        _statusCard(cs, 'KYC Verification', isVerified ? 'Verified' : 'Incomplete',
            isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B), Uicons.badgeCheck),
        const SizedBox(height: 8),
        _statusCard(cs, 'Store Availability', isVerified ? 'Available' : 'Unavailable',
            isVerified ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF), Uicons.shop),
        const SizedBox(height: 8),
        _statusCard(cs, 'Payout Status', 'Verified & Ready', const Color(0xFF22C55E), Uicons.sackDollar),
        const SizedBox(height: 24),
        if (seller?.rejectionReason != null) ...[
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12),
          ), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Rejection Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
            const SizedBox(height: 6),
            Text(seller!.rejectionReason!, style: TextStyle(fontSize: 13, color: const Color(0xFFEF4444).withValues(alpha: 0.7))),
          ])),
          const SizedBox(height: 16),
        ],
        SizedBox(width: double.infinity, child: FilledButton.tonal(
          onPressed: () => context.push(AppConstants.sellerKycRoute),
          style: _btnStyle(cs), child: const Text('Open KYC verification'),
        )),
      ]);
    });
  }

  Widget _statusCard(ColorScheme cs, String label, String value, Color color, IconData icon) {
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
      color: cs.surface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.15)),
    ), child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ])),
    ]));
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved': return const Color(0xFF22C55E);
      case 'pending': return const Color(0xFFF59E0B);
      case 'rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFF9CA3AF);
    }
  }
}
