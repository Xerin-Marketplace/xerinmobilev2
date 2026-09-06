import 'package:flutter/material.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

class QuestionChoice {
  final String value;
  final String label;
  final String? description;

  const QuestionChoice({
    required this.value,
    required this.label,
    this.description,
  });
}

class QuestionItem {
  final String name;
  final String prompt;
  final String? description;
  final List<QuestionChoice> choices;
  final bool multiple;
  final bool required_;
  final bool allowFreeform;
  final String? freeformLabel;
  final String? freeformPlaceholder;

  const QuestionItem({
    required this.name,
    required this.prompt,
    this.description,
    required this.choices,
    this.multiple = false,
    this.required_ = true,
    this.allowFreeform = false,
    this.freeformLabel,
    this.freeformPlaceholder,
  });
}

class QuestionnaireResult {
  final Map<String, dynamic> answers;

  QuestionnaireResult(this.answers);

  String? getSingle(String name) => answers[name] as String?;
  List<String>? getMultiple(String name) => answers[name] as List<String>?;
}

// ─── Questionnaire Widget ────────────────────────────────────────────────────

class Questionnaire extends StatefulWidget {
  final List<QuestionItem> items;
  final ValueChanged<QuestionnaireResult> onSubmit;
  final VoidCallback? onCancelled;
  final String title;
  final String submitLabel;

  const Questionnaire({
    super.key,
    required this.items,
    required this.onSubmit,
    this.onCancelled,
    this.title = 'Questionnaire',
    this.submitLabel = 'Submit',
  });

  @override
  State<Questionnaire> createState() => _QuestionnaireState();
}

class _QuestionnaireState extends State<Questionnaire>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<String, dynamic> _answers = {};
  final TextEditingController _freeformCtrl = TextEditingController();
  String? _error;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _freeformCtrl.dispose();
    super.dispose();
  }

  void _animateTransition(bool forward) {
    _slideController.reset();
    _slideAnimation = Tween<Offset>(
      begin: Offset(forward ? 1.0 : -1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  bool _isAnswered(QuestionItem item) {
    final answer = _answers[item.name];
    if (answer == null) return false;
    if (item.multiple) return (answer as List).isNotEmpty;
    return (answer as String).isNotEmpty;
  }

  bool _validate() {
    final item = widget.items[_currentIndex];
    if (!item.required_) return true;
    if (_isAnswered(item)) return true;
    setState(() => _error = 'Please select an option to continue');
    return false;
  }

  void _goNext() {
    if (!_validate()) return;
    setState(() => _error = null);

    if (_currentIndex < widget.items.length - 1) {
      _currentIndex++;
      _freeformCtrl.clear();
      _animateTransition(true);
    } else {
      widget.onSubmit(QuestionnaireResult(Map.from(_answers)));
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      setState(() => _error = null);
      _currentIndex--;
      _freeformCtrl.clear();
      _animateTransition(false);
    }
  }

  void _skip() {
    setState(() {
      _error = null;
      _answers.remove(widget.items[_currentIndex].name);
    });
    if (_currentIndex < widget.items.length - 1) {
      _currentIndex++;
      _freeformCtrl.clear();
      _animateTransition(true);
    } else {
      widget.onSubmit(QuestionnaireResult(Map.from(_answers)));
    }
  }

  void _selectSingle(QuestionItem item, String value) {
    setState(() {
      _answers[item.name] = value;
      _error = null;
    });
  }

  void _toggleMultiple(QuestionItem item, String value) {
    final current = List<String>.from(_answers[item.name] as List? ?? []);
    setState(() {
      if (current.contains(value)) {
        current.remove(value);
      } else {
        current.add(value);
      }
      _answers[item.name] = current;
      _error = null;
    });
  }

  void _setFreeform(QuestionItem item, String value) {
    setState(() {
      if (value.isNotEmpty) {
        _answers[item.name] = value;
      } else {
        _answers.remove(item.name);
      }
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.items[_currentIndex];
    final isLast = _currentIndex == widget.items.length - 1;
    final progress = (_currentIndex + 1) / widget.items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProgress(colorScheme, progress),
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildQuestion(item, colorScheme, isDark),
            ),
          ),
        ),
        if (_error != null) _buildError(colorScheme),
        _buildActions(colorScheme, item, isLast),
      ],
    );
  }

  Widget _buildProgress(ColorScheme colorScheme, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentIndex + 1} of ${widget.items.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(
    QuestionItem item,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            item.prompt,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          if (item.description != null) ...[
            const SizedBox(height: 8),
            Text(
              item.description!,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 28),
          // Choices
          ...item.choices.map((choice) => _buildChoiceTile(
                item,
                choice,
                colorScheme,
                isDark,
              )),
          // Freeform input
          if (item.allowFreeform) ...[
            const SizedBox(height: 12),
            _buildFreeformInput(item, colorScheme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceTile(
    QuestionItem item,
    QuestionChoice choice,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isSelected = item.multiple
        ? (_answers[item.name] as List? ?? []).contains(choice.value)
        : _answers[item.name] == choice.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (item.multiple) {
              _toggleMultiple(item, choice.value);
            } else {
              _selectSingle(item, choice.value);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.06)
                  : (isDark
                      ? colorScheme.onSurface.withValues(alpha: 0.04)
                      : colorScheme.onSurface.withValues(alpha: 0.02)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.08),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: item.multiple
                        ? BoxShape.rectangle
                        : BoxShape.circle,
                    borderRadius:
                        item.multiple ? BorderRadius.circular(6) : null,
                    color: isSelected ? colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          item.multiple ? Icons.check : Icons.circle,
                          size: item.multiple ? 14 : 8,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (choice.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          choice.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.45),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeformInput(
    QuestionItem item,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.freeformLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              item.freeformLabel!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        TextField(
          controller: _freeformCtrl,
          onChanged: (value) => _setFreeform(item, value),
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: item.freeformPlaceholder ?? 'Type your answer...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            filled: true,
            fillColor: isDark
                ? colorScheme.onSurface.withValues(alpha: 0.04)
                : colorScheme.onSurface.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: colorScheme.error),
          const SizedBox(width: 6),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    ColorScheme colorScheme,
    QuestionItem item,
    bool isLast,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        children: [
          if (_currentIndex > 0)
            _buildNavButton(
              label: 'Back',
              icon: Icons.arrow_back_rounded,
              onTap: _goPrevious,
              colorScheme: colorScheme,
              isPrimary: false,
            ),
          const Spacer(),
          if (!item.required_)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          _buildNavButton(
            label: isLast ? widget.submitLabel : 'Next',
            icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
            onTap: _goNext,
            colorScheme: colorScheme,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.12),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPrimary) ...[
              Icon(icon, size: 16, color: colorScheme.onSurface),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : colorScheme.onSurface,
              ),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
