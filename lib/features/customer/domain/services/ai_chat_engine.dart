import 'dart:async';

enum MessageRole { user, assistant }

enum MessagePartType { text, reasoning, toolCall, toolResult, error, productCard }

class ProductCardData {
  final String name;
  final String image;
  final double price;
  final double? originalPrice;
  final String store;
  final double rating;
  final int reviews;
  final List<String> specs;
  final String? badge;

  ProductCardData({
    required this.name,
    required this.image,
    required this.price,
    this.originalPrice,
    required this.store,
    required this.rating,
    required this.reviews,
    required this.specs,
    this.badge,
  });

  factory ProductCardData.fromMap(Map<String, dynamic> m) {
    return ProductCardData(
      name: m['name'] ?? '',
      image: m['image'] ?? '',
      price: (m['price'] ?? 0).toDouble(),
      originalPrice: m['originalPrice']?.toDouble(),
      store: m['store'] ?? '',
      rating: (m['rating'] ?? 0).toDouble(),
      reviews: (m['reviews'] ?? 0).toInt(),
      specs: List<String>.from(m['specs'] ?? []),
      badge: m['badge'],
    );
  }
}

class MessagePart {
  final MessagePartType type;
  final String? text;
  final String? toolName;
  final Map<String, dynamic>? toolInput;
  final Map<String, dynamic>? toolOutput;
  final String? errorText;
  final bool isStreaming;
  final ProductCardData? product;

  MessagePart({
    required this.type,
    this.text,
    this.toolName,
    this.toolInput,
    this.toolOutput,
    this.errorText,
    this.isStreaming = false,
    this.product,
  });
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final List<MessagePart> parts;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.parts,
    required this.createdAt,
  });

  String get fullText =>
      parts.where((p) => p.type == MessagePartType.text).map((p) => p.text ?? '').join();
}

class _PredefinedTurn {
  final String userText;
  final List<_ScriptedPart> assistantParts;

  _PredefinedTurn({
    required this.userText,
    required this.assistantParts,
  });
}

class _ScriptedPart {
  final MessagePartType type;
  final String? text;
  final String? toolName;
  final Map<String, dynamic>? toolInput;
  final Map<String, dynamic>? toolOutput;
  final ProductCardData? product;
  final int delayMs;
  final bool instant;

  _ScriptedPart({
    required this.type,
    this.text,
    this.toolName,
    this.toolInput,
    this.toolOutput,
    this.product,
    this.delayMs = 40,
    this.instant = false,
  });
}

class AiChatEngine {
  final List<_PredefinedTurn> _turns = [];
  final List<ChatMessage> _messages = [];
  int _turnIndex = 0;
  int _msgCounter = 0;

  String get _nextId => 'msg_${_msgCounter++}';

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool get hasMoreTurns => _turnIndex < _turns.length;

  String? get nextUserPrompt {
    if (_turnIndex >= _turns.length) return null;
    return _turns[_turnIndex].userText;
  }

  AiChatEngine user(String text) {
    _turns.add(_PredefinedTurn(userText: text, assistantParts: []));
    return this;
  }

  AiChatEngine assistant(String text, {int delayMs = 40, bool instant = false}) {
    if (_turns.isEmpty) {
      _turns.add(_PredefinedTurn(userText: '', assistantParts: []));
    }
    _turns.last.assistantParts.add(_ScriptedPart(
      type: MessagePartType.text,
      text: text,
      delayMs: delayMs,
      instant: instant,
    ));
    return this;
  }

  AiChatEngine reasoning(String text, {int delayMs = 40, bool instant = false}) {
    if (_turns.isEmpty) {
      _turns.add(_PredefinedTurn(userText: '', assistantParts: []));
    }
    _turns.last.assistantParts.add(_ScriptedPart(
      type: MessagePartType.reasoning,
      text: text,
      delayMs: delayMs,
      instant: instant,
    ));
    return this;
  }

  AiChatEngine tool(
    String name, {
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
    int delayMs = 600,
  }) {
    if (_turns.isEmpty) {
      _turns.add(_PredefinedTurn(userText: '', assistantParts: []));
    }
    _turns.last.assistantParts.add(_ScriptedPart(
      type: MessagePartType.toolCall,
      toolName: name,
      toolInput: input,
      toolOutput: output,
      delayMs: delayMs,
    ));
    return this;
  }

  AiChatEngine product(ProductCardData product, {int delayMs = 200}) {
    if (_turns.isEmpty) {
      _turns.add(_PredefinedTurn(userText: '', assistantParts: []));
    }
    _turns.last.assistantParts.add(_ScriptedPart(
      type: MessagePartType.productCard,
      product: product,
      delayMs: delayMs,
    ));
    return this;
  }

  AiChatEngine sleep(int ms) {
    if (_turns.isEmpty) {
      _turns.add(_PredefinedTurn(userText: '', assistantParts: []));
    }
    _turns.last.assistantParts.add(_ScriptedPart(
      type: MessagePartType.text,
      text: '',
      delayMs: ms,
      instant: true,
    ));
    return this;
  }

  Stream<ChatMessage> sendNext() async* {
    if (_turnIndex >= _turns.length) return;

    final turn = _turns[_turnIndex];
    _turnIndex++;

    final userMsg = ChatMessage(
      id: _nextId,
      role: MessageRole.user,
      parts: [MessagePart(type: MessagePartType.text, text: turn.userText)],
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);

    final assistantId = _nextId;
    final assistantMsg = ChatMessage(
      id: assistantId,
      role: MessageRole.assistant,
      parts: [],
      createdAt: DateTime.now(),
    );
    _messages.add(assistantMsg);

    for (final scripted in turn.assistantParts) {
      if (scripted.type == MessagePartType.text && scripted.text!.isEmpty) {
        await Future.delayed(Duration(milliseconds: scripted.delayMs));
        continue;
      }

      if (scripted.type == MessagePartType.toolCall) {
        final toolPart = MessagePart(
          type: MessagePartType.toolCall,
          toolName: scripted.toolName,
          toolInput: scripted.toolInput,
          isStreaming: true,
        );
        assistantMsg.parts.add(toolPart);
        yield _cloneMessage(assistantMsg);

        await Future.delayed(Duration(milliseconds: scripted.delayMs));

        assistantMsg.parts.removeLast();
        assistantMsg.parts.add(MessagePart(
          type: MessagePartType.toolCall,
          toolName: scripted.toolName,
          toolInput: scripted.toolInput,
          toolOutput: scripted.toolOutput,
          isStreaming: false,
        ));
        yield _cloneMessage(assistantMsg);
        continue;
      }

      if (scripted.type == MessagePartType.productCard) {
        await Future.delayed(Duration(milliseconds: scripted.delayMs));
        assistantMsg.parts.add(MessagePart(
          type: MessagePartType.productCard,
          product: scripted.product,
        ));
        yield _cloneMessage(assistantMsg);
        continue;
      }

      if (scripted.instant) {
        assistantMsg.parts.add(MessagePart(
          type: scripted.type,
          text: scripted.text,
        ));
        yield _cloneMessage(assistantMsg);
        continue;
      }

      final words = scripted.text!.split(' ');
      final partIndex = assistantMsg.parts.length;
      assistantMsg.parts.add(MessagePart(
        type: scripted.type,
        text: '',
        isStreaming: true,
      ));

      for (int i = 0; i < words.length; i++) {
        await Future.delayed(Duration(milliseconds: scripted.delayMs));
        assistantMsg.parts[partIndex] = MessagePart(
          type: scripted.type,
          text: words.sublist(0, i + 1).join(' '),
          isStreaming: i < words.length - 1,
        );
        yield _cloneMessage(assistantMsg);
      }
    }

    for (int i = 0; i < assistantMsg.parts.length; i++) {
      if (assistantMsg.parts[i].isStreaming) {
        assistantMsg.parts[i] = MessagePart(
          type: assistantMsg.parts[i].type,
          text: assistantMsg.parts[i].text,
          toolName: assistantMsg.parts[i].toolName,
          toolInput: assistantMsg.parts[i].toolInput,
          toolOutput: assistantMsg.parts[i].toolOutput,
          errorText: assistantMsg.parts[i].errorText,
          isStreaming: false,
          product: assistantMsg.parts[i].product,
        );
      }
    }
    yield _cloneMessage(assistantMsg);
  }

  ChatMessage _cloneMessage(ChatMessage msg) {
    return ChatMessage(
      id: msg.id,
      role: msg.role,
      parts: msg.parts.map((p) => MessagePart(
        type: p.type,
        text: p.text,
        toolName: p.toolName,
        toolInput: p.toolInput,
        toolOutput: p.toolOutput,
        errorText: p.errorText,
        isStreaming: p.isStreaming,
        product: p.product,
      )).toList(),
      createdAt: msg.createdAt,
    );
  }

  void reset() {
    _messages.clear();
    _turnIndex = 0;
    _msgCounter = 0;
  }
}
