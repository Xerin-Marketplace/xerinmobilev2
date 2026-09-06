import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
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
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
                        GestureDetector(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          },
                          child: Icon(Icons.arrow_back, size: 22, color: colorScheme.onSurface),
                        ),
                        const SizedBox(width: 16),
                        Text('Help & Support',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Contact Options',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    _buildContactOption(Icons.phone, 'Call Support', '+255 792 810 292', const Color(0xFF22C55E), colorScheme),
                    const SizedBox(height: 10),
                    _buildContactOption(Icons.email_outlined, 'Email Us', 'support@xerin.co.tz', const Color(0xFF3B82F6), colorScheme),
                    const SizedBox(height: 10),
                    _buildContactOption(Icons.chat_outlined, 'Live Chat', 'Available now', const Color(0xFFF59E0B), colorScheme),
                    const SizedBox(height: 10),
                    _buildContactOption(Icons.chat, 'WhatsApp', '+255 792 810 292', const Color(0xFF22C55E), colorScheme),
                    const SizedBox(height: 24),
                    Text('Frequently Asked Questions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    ..._faqs.map((faq) => _FaqItem(
                      question: faq['question'] as String,
                      answer: faq['answer'] as String,
                      colorScheme: colorScheme,
                    )),
                    const SizedBox(height: 24),
                    Text('Send us a Message',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe your issue...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 48,
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Send Message',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.3)),
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

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(widget.question,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.colorScheme.onSurface),
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: widget.colorScheme.primary, size: 22),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
