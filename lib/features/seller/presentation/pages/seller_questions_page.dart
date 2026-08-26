import 'package:flutter/material.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../../../customer/data/datasources/product_qa_remote_datasource.dart';
import '../../../customer/data/models/product_qa_model.dart';

class SellerQuestionsPage extends StatefulWidget {
  const SellerQuestionsPage({super.key});

  @override
  State<SellerQuestionsPage> createState() => _SellerQuestionsPageState();
}

class _SellerQuestionsPageState extends State<SellerQuestionsPage> {
  List<ProductQuestionModel> _questions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ds = sl<ProductQaRemoteDataSource>();
      final questions = await ds.getSellerQuestions();
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Q&A')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadQuestions, child: const Text('Retry')),
                    ],
                  ),
                )
              : _questions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Uicons.circleQuestion, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('No questions yet', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadQuestions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) => _buildQuestionCard(context, _questions[index]),
                      ),
                    ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, ProductQuestionModel question) {
    final isAnswered = question.answers.isNotEmpty;
    final answerText = isAnswered ? question.answers.first.answer : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Uicons.circleQuestion, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.question,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Asked: ${_formatDate(question.createdAt ?? '')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (isAnswered) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Answer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                    const SizedBox(height: 4),
                    Text(answerText!, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAnswerDialog(context, question),
                  icon: const Icon(Uicons.reply, size: 16),
                  label: const Text('Answer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAnswerDialog(BuildContext context, ProductQuestionModel question) {
    final answerController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Answer Question'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q: ${question.question}', style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              TextFormField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Your Answer *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                try {
                  final ds = sl<ProductQaRemoteDataSource>();
                  await ds.sellerAnswerQuestion(
                    questionId: question.id,
                    answer: answerController.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Answer posted'), backgroundColor: Colors.green),
                    );
                    _loadQuestions();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
