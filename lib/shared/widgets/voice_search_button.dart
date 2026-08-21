import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../core/theme/uicons.dart';

class VoiceSearchButton extends StatefulWidget {
  final ColorScheme colorScheme;
  final ValueChanged<String> onResult;
  final double size;

  const VoiceSearchButton({
    super.key,
    required this.colorScheme,
    required this.onResult,
    this.size = 20,
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _isAvailable = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Voice search is not available on this device'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: widget.colorScheme.onSurface.withValues(alpha: 0.85),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      localeId: 'en_US',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isNotEmpty) {
          widget.onResult(words);
        }
      },
    );

    if (mounted) setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = _isListening
        ? widget.colorScheme.primary
        : widget.colorScheme.onSurface.withValues(alpha: 0.45);

    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _isListening
              ? widget.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isListening ? Uicons.microphoneAlt : Uicons.microphone,
          color: color,
          size: widget.size,
        ),
      ),
    );
  }
}
