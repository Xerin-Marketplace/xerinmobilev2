import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/product_qa_cubit.dart';
import '../../data/models/product_qa_model.dart';
import '../../../../core/theme/uicons.dart';

class ProductQaPage extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductQaPage({
    super.key,
    required this.productId,
    this.productName = 'Product',
  });

  @override
  State<ProductQaPage> createState() => _ProductQaPageState();
}

class _ProductQaPageState extends State<ProductQaPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductQaCubit>().loadQuestions(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Q&A - ${widget.productName}'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.circleQuestion),
            onPressed: () => _showAskQuestionDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<ProductQaCubit, ProductQaState>(
        builder: (context, state) {
          if (state is ProductQaLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProductQaError) {
            return Center(child: Text(state.message));
          }
          if (state is ProductQaLoaded) {
            if (state.questions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Uicons.comment, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No questions yet'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _showAskQuestionDialog(context),
                      icon: const Icon(Uicons.add),
                      label: const Text('Ask a Question'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.questions.length,
              itemBuilder: (context, index) {
                return _QuestionCard(
                  question: state.questions[index],
                  productId: widget.productId,
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showAskQuestionDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ask a Question'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Your question',
            hintText: 'e.g. Is this product available in other colors?',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<ProductQaCubit>().askQuestion(
                      productId: widget.productId,
                      question: controller.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final ProductQuestionModel question;
  final String productId;

  const _QuestionCard({required this.question, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(question.question, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Text(question.customerName ?? 'Anonymous'),
            const SizedBox(width: 8),
            Text('${question.answerCount} answers'),
            const SizedBox(width: 8),
            Text('${question.helpfulCount} helpful'),
          ],
        ),
        children: [
          ...question.answers.map((answer) => _AnswerTile(answer: answer)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showAnswerDialog(context, question.id),
                icon: const Icon(Uicons.reply),
                label: const Text('Answer this question'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnswerDialog(BuildContext context, String questionId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your Answer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Write your answer...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<ProductQaCubit>().answerQuestion(
                      questionId: questionId,
                      answer: controller.text.trim(),
                      productId: productId,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final ProductAnswerModel answer;

  const _AnswerTile({required this.answer});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text((answer.userName ?? 'U')[0].toUpperCase()),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              answer.userName ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (answer.isSellerAnswer) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Seller',
                style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(answer.answer),
      trailing: TextButton.icon(
        onPressed: () => context.read<ProductQaCubit>().voteHelpful(answer.id),
        icon: const Icon(Uicons.thumbsUpTrust, size: 16),
        label: Text('${answer.helpfulCount}'),
      ),
    );
  }
}
