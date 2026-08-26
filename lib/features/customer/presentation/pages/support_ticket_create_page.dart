import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../presentation/cubit/support_cubit.dart';
import '../../presentation/cubit/support_state.dart';

class SupportTicketCreatePage extends StatefulWidget {
  const SupportTicketCreatePage({super.key});

  @override
  State<SupportTicketCreatePage> createState() =>
      _SupportTicketCreatePageState();
}

class _SupportTicketCreatePageState extends State<SupportTicketCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _category = 'general';
  String _priority = 'medium';

  static const _categories = [
    {'value': 'general', 'label': 'General Inquiry'},
    {'value': 'order', 'label': 'Order Issue'},
    {'value': 'payment', 'label': 'Payment Issue'},
    {'value': 'delivery', 'label': 'Delivery Issue'},
    {'value': 'product', 'label': 'Product Issue'},
    {'value': 'account', 'label': 'Account Issue'},
    {'value': 'refund', 'label': 'Refund Request'},
    {'value': 'other', 'label': 'Other'},
  ];

  static const _priorities = [
    {'value': 'low', 'label': 'Low'},
    {'value': 'medium', 'label': 'Medium'},
    {'value': 'high', 'label': 'High'},
    {'value': 'urgent', 'label': 'Urgent'},
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SupportCubit>().createTicket(
          subject: _subjectCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          category: _category,
          priority: _priority,
        );
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
        title: const Text('New Support Ticket'),
      ),
      body: SafeArea(
        child: BlocConsumer<SupportCubit, SupportState>(
          listener: (context, state) {
            if (state is SupportTicketCreated) {
              NotificationService().success('Ticket created successfully');
              context.pop();
            }
            if (state is SupportError) {
              NotificationService().error(state.message);
            }
          },
          builder: (context, state) {
            final isLoading = state is SupportLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How can we help you?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fill in the details below and our team will get back to you.',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel(cs, 'Subject'),
                    TextFormField(
                      controller: _subjectCtrl,
                      decoration: _inputDecoration(cs, 'Brief summary'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter a subject';
                        }
                        if (v.trim().length < 3) {
                          return 'Subject must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLabel(cs, 'Category'),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: _inputDecoration(cs, ''),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c['value'],
                                child: Text(c['label']!),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? 'general'),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel(cs, 'Priority'),
                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: _inputDecoration(cs, ''),
                      items: _priorities
                          .map((p) => DropdownMenuItem(
                                value: p['value'],
                                child: Text(p['label']!),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _priority = v ?? 'medium'),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel(cs, 'Description'),
                    TextFormField(
                      controller: _descriptionCtrl,
                      decoration: _inputDecoration(
                        cs,
                        'Describe your issue in detail...',
                        multiline: true,
                      ),
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit Ticket'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(ColorScheme cs, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(ColorScheme cs, String hint,
      {bool multiline = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
      filled: true,
      fillColor: cs.onSurface.withValues(alpha: 0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
  }
}
