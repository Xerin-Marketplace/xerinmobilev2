import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/broker_cubit.dart';

class MawingaReferralPage extends StatefulWidget {
  const MawingaReferralPage({super.key});

  @override
  State<MawingaReferralPage> createState() => _MawingaReferralPageState();
}

class _MawingaReferralPageState extends State<MawingaReferralPage> {
  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Invite a Mawinga'),
      ),
      body: SafeArea(
        child: BlocBuilder<BrokerCubit, BrokerState>(
          builder: (context, state) {
            if (state is BrokerDashboardLoaded) {
              final broker = state.broker;
              final referralCode = 'MWG-${broker.brokerCode}';
              final inviteLink = 'https://xerin.co/invite/${broker.brokerCode}';

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Uicons.user, size: 24, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Invite friends to become Mawinga and earn rewards!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildReferralCodeCard(referralCode, cs),
                  const SizedBox(height: 16),
                  _buildInviteLinkCard(inviteLink, cs),
                  const SizedBox(height: 16),
                  _buildShareButtons(context, inviteLink, cs),
                  const SizedBox(height: 24),
                  _buildHowItWorks(cs),
                  const SizedBox(height: 16),
                  _buildRewardsInfo(cs),
                ],
              );
            }
            if (state is BrokerLoading || state is BrokerInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: Text('Unable to load referral info'));
          },
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(String code, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Referral Code',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: 1),
                ),
              ),
              IconButton(
                icon: const Icon(Uicons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  NotificationService().success('Referral code copied!');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteLinkCard(String link, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              link,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Uicons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              NotificationService().success('Invite link copied!');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShareButtons(BuildContext context, String link, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _shareButton('WhatsApp', Uicons.comment, const Color(0xFF25D366), link),
        _shareButton('Instagram', Uicons.camera, const Color(0xFFE1306C), link),
        _shareButton('TikTok', Uicons.music, const Color(0xFF000000), link),
        _shareButton('Facebook', Uicons.globe, const Color(0xFF1877F2), link),
      ],
    );
  }

  Widget _shareButton(String label, IconData icon, Color color, String link) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: link));
        NotificationService().success('$label link copied! Open $label and paste.');
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(ColorScheme cs) {
    final steps = [
      {'icon': Uicons.user, 'title': 'Share your code', 'desc': 'Send your referral code to friends.'},
      {'icon': Uicons.shieldCheck, 'title': 'They register', 'desc': 'Your friend signs up as a Mawinga.'},
      {'icon': Uicons.sackDollar, 'title': 'They start selling', 'desc': 'When they make real sales, you earn rewards.'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How It Works',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(step['icon'] as IconData, size: 16, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step['title'] as String,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                        Text(step['desc'] as String,
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRewardsInfo(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Uicons.circleInfo, size: 20, color: Colors.amber.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Referral rewards are paid based on real sales activity, not just registration.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
