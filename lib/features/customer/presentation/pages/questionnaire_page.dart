import 'package:flutter/material.dart';

import '../../../../shared/widgets/questionnaire.dart';

class QuestionnairePage extends StatelessWidget {
  const QuestionnairePage({super.key});

  static const _questions = [
    QuestionItem(
      name: 'shopping_goal',
      prompt: 'What brings you to Xerin today?',
      description: 'Help us personalize your experience.',
      choices: [
        QuestionChoice(
          value: 'browse',
          label: 'Just browsing',
          description: 'See what\'s available and trending',
        ),
        QuestionChoice(
          value: 'specific',
          label: 'Looking for something specific',
          description: 'I have a product in mind',
        ),
        QuestionChoice(
          value: 'deals',
          label: 'Hunting for deals',
          description: 'Best prices and flash sales',
        ),
        QuestionChoice(
          value: 'wholesale',
          label: 'Wholesale / bulk buying',
          description: 'Purchasing for business',
        ),
      ],
    ),
    QuestionItem(
      name: 'categories',
      prompt: 'Which categories interest you?',
      description: 'Select all that apply. You can skip this.',
      multiple: true,
      required_: false,
      choices: [
        QuestionChoice(value: 'electronics', label: 'Electronics'),
        QuestionChoice(value: 'fashion', label: 'Fashion & Apparel'),
        QuestionChoice(value: 'home', label: 'Home & Living'),
        QuestionChoice(value: 'beauty', label: 'Beauty & Health'),
        QuestionChoice(value: 'grocery', label: 'Grocery'),
        QuestionChoice(value: 'sports', label: 'Sports & Fitness'),
      ],
    ),
    QuestionItem(
      name: 'budget',
      prompt: 'What\'s your typical budget?',
      description: 'This helps us recommend the right products.',
      choices: [
        QuestionChoice(value: 'under_100k', label: 'Under 100,000 TZS'),
        QuestionChoice(value: '100k_500k', label: '100K – 500K TZS'),
        QuestionChoice(value: '500k_2m', label: '500K – 2M TZS'),
        QuestionChoice(value: 'over_2m', label: 'Over 2M TZS'),
      ],
      allowFreeform: true,
      freeformLabel: 'Or specify your own range',
      freeformPlaceholder: 'e.g. 300K – 700K TZS',
    ),
    QuestionItem(
      name: 'delivery',
      prompt: 'How do you prefer to receive orders?',
      choices: [
        QuestionChoice(
          value: 'express',
          label: 'Xerin Express',
          description: 'Fastest delivery, same-day in Dar es Salaam',
        ),
        QuestionChoice(
          value: 'standard',
          label: 'Standard delivery',
          description: '2-5 business days nationwide',
        ),
        QuestionChoice(
          value: 'pickup',
          label: 'Pickup point',
          description: 'Collect from a nearby Xerin partner',
        ),
      ],
    ),
    QuestionItem(
      name: 'feedback',
      prompt: 'Anything else you\'d like us to know?',
      description: 'Optional — tell us what would make your experience better.',
      required_: false,
      choices: [],
      allowFreeform: true,
      freeformPlaceholder: 'Share your thoughts...',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Help us personalize',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Questionnaire(
          items: _questions,
          submitLabel: 'Finish',
          onSubmit: (result) {
            // TODO: Save answers to backend
            Navigator.of(context).pop(result);
          },
        ),
      ),
    );
  }
}
