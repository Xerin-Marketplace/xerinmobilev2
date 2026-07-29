import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/app_icon.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final _messageCtrl = TextEditingController();

  final List<Map<String, dynamic>> _faqs = const [
    {
      'question': 'How do I place an order?',
      'answer': 'Browse products, add items to your cart, select your delivery address, choose a payment method, and confirm your order.',
    },
    {
      'question': 'What payment methods are accepted?',
      'answer': 'We accept M-Pesa, Tigo Pesa, Airtel Money, bank transfers (CRDB, NBC, NMB), and card payments.',
    },
    {
      'question': 'How long does delivery take?',
      'answer': 'Delivery takes 1-3 business days within Dar es Salaam and 3-7 business days for upcountry locations.',
    },
    {
      'question': 'Can I return an item?',
      'answer': 'Yes, you can return items within 7 days of delivery. Items must be unused and in original packaging.',
    },
    {
      'question': 'How do I track my order?',
      'answer': 'Go to Order History in your profile. You can see real-time tracking information for shipped orders.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BackIconButton(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          },
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Text('Help & Support',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Need help?',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text('We are here for you 24/7',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Contact Options',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    _buildContactOption(Icons.phone_rounded, 'Call Support', '+255 800 123 456', const Color(0xFF22C55E), colorScheme),
                    const SizedBox(height: 10),
                    _buildContactOption(Icons.email_rounded, 'Email Us', 'support@xerin.co.tz', const Color(0xFF3B82F6), colorScheme),
                    const SizedBox(height: 10),
                    _buildContactOption(Icons.chat_rounded, 'Live Chat', 'Available now', const Color(0xFFF59E0B), colorScheme),
                    const SizedBox(height: 10),
                    _buildContactOption(Icons.chat_bubble_rounded, 'WhatsApp', '+255 712 345 678', const Color(0xFF22C55E), colorScheme),
                    const SizedBox(height: 24),
                    Text('Frequently Asked Questions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    ..._faqs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final faq = entry.value;
                      return AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final delay = index * 0.1;
                          final value = Curves.easeOutCubic.transform(
                            (_animController.value - delay).clamp(0.0, 1.0),
                          );
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: _FaqItem(
                          question: faq['question'] as String,
                          answer: faq['answer'] as String,
                          colorScheme: colorScheme,
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    Text('Send us a Message',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _messageCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe your issue...',
                          hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_messageCtrl.text.isNotEmpty) {
                            _messageCtrl.clear();
                            NotificationService().success('Message sent to support');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Send Message',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String title, String subtitle, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          IconContainer(
            icon: icon,
            color: color,
            size: 44,
            iconSize: AppIconSize.lg,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          TrailingChevron(color: colorScheme.onSurface.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final ColorScheme colorScheme;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.colorScheme,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotation = Tween<double>(begin: 0, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
                if (_expanded) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(widget.question,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: widget.colorScheme.onSurface),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotation,
                    child: Icon(Icons.add_rounded, color: widget.colorScheme.primary, size: 22),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(widget.answer,
                      style: TextStyle(fontSize: 13, height: 1.5,
                        color: widget.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
