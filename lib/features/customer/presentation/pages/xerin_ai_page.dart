import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/constants/app_constants.dart';
import '../../data/models/product_model.dart';
import '../../domain/services/ai_chat_engine.dart';

class XerinAiPage extends StatefulWidget {
  const XerinAiPage({super.key});

  @override
  State<XerinAiPage> createState() => _XerinAiPageState();
}

class _XerinAiPageState extends State<XerinAiPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputCtrl = TextEditingController();

  bool _isAtBottom = true;
  bool _showJumpButton = false;
  bool _isStreaming = false;

  late AiChatEngine _engine;
  List<ChatMessage> _messages = [];
  List<_ChatHistoryEntry> _history = [];

  static const _storageKey = 'xerin_ai_chat_history';

  final List<String> _suggestedPrompts = [
    'Find me iPhone 15 deals under 2M TZS',
    'What\'s trending in electronics?',
    'Compare Samsung S24 vs iPhone 15',
    'Best wholesale deals this week',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _pulseController.repeat(reverse: true);

    _scrollController.addListener(_onScroll);
    _engine = _buildConversation();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? [];
      if (mounted) {
        setState(() {
          _history = raw.map((e) {
            final json = jsonDecode(e) as Map<String, dynamic>;
            return _ChatHistoryEntry(
              id: json['id'] ?? '',
              title: json['title'] ?? 'New Chat',
              preview: json['preview'] ?? '',
              timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
              messageCount: json['messageCount'] ?? 0,
            );
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCurrentChat() async {
    if (_messages.isEmpty) return;
    final firstUserMsg = _messages.firstWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => _messages.first,
    );
    final title = firstUserMsg.fullText;
    final preview = _messages.last.fullText;
    final entry = _ChatHistoryEntry(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      title: title.length > 40 ? '${title.substring(0, 40)}...' : title,
      preview: preview.length > 60 ? '${preview.substring(0, 60)}...' : preview,
      timestamp: DateTime.now(),
      messageCount: _messages.length,
    );
    _history.insert(0, entry);
    if (_history.length > 20) _history = _history.sublist(0, 20);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _storageKey,
        _history.map((e) => jsonEncode({
          'id': e.id,
          'title': e.title,
          'preview': e.preview,
          'timestamp': e.timestamp.toIso8601String(),
          'messageCount': e.messageCount,
        })).toList(),
      );
    } catch (_) {}
  }

  void _startNewChat() {
    setState(() {
      _engine = _buildConversation();
      _messages = [];
      _isStreaming = false;
      _showJumpButton = false;
      _isAtBottom = true;
    });
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A1A)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Chat History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (_history.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove(_storageKey);
                            setState(() => _history = []);
                          },
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: cs.onSurface.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No chat history yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your conversations will appear here',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.25),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final entry = _history[index];
                            return _buildHistoryTile(entry, cs, dark);
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTile(_ChatHistoryEntry entry, ColorScheme cs, bool dark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: dark
            ? cs.onSurface.withValues(alpha: 0.04)
            : cs.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.chat_rounded,
            size: 18,
            color: Color(0xFFFF9800),
          ),
        ),
        title: Text(
          entry.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              entry.preview,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 11, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text(
                  _formatTime(entry.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 11, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text(
                  '${entry.messageCount} msgs',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: cs.onSurface.withValues(alpha: 0.2),
        ),
        onTap: () {
          Navigator.pop(context);
          _startNewChat();
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  AiChatEngine _buildConversation() {
    return AiChatEngine()
        .user('Find me iPhone 15 deals under 2M TZS')
        .reasoning(
            'User wants iPhone 15 deals. I should search for current listings and filter by price.')
        .tool('searchProducts',
            input: {'query': 'iPhone 15', 'maxPrice': 2000000},
            output: {'count': 3})
        .assistant('I found 3 great deals on iPhone 15 under 2M TZS!',
            instant: true)
        .product(ProductCardData(
          name: 'iPhone 15 128GB',
          image:
              'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400',
          price: 1800000,
          originalPrice: 2200000,
          store: 'TechWorld',
          rating: 4.8,
          reviews: 234,
          specs: ['128GB Storage', '6.1" OLED', 'A16 Bionic', '48MP Camera'],
          badge: 'Best Value',
        ))
        .product(ProductCardData(
          name: 'iPhone 15 256GB',
          image:
              'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400',
          price: 1950000,
          originalPrice: 2500000,
          store: 'GadgetHub',
          rating: 4.6,
          reviews: 189,
          specs: ['256GB Storage', '6.1" OLED', 'A16 Bionic', '48MP Camera'],
        ))
        .product(ProductCardData(
          name: 'iPhone 15 (Refurbished)',
          image:
              'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400',
          price: 1450000,
          store: 'RefurbStore',
          rating: 4.3,
          reviews: 97,
          specs: ['128GB Storage', '6.1" OLED', 'A16 Bionic', '90-day warranty'],
          badge: 'Budget Pick',
        ))
        .assistant(
            '\n\nThe best value is the 128GB at TechWorld — great rating and 18% off! Want me to compare them in detail? 🔍')
        .user('What are the trending products in electronics?')
        .reasoning(
            'User is asking about trending electronics. Let me fetch the current trending list.')
        .tool('getTrending',
            input: {'category': 'electronics', 'limit': 5},
            output: {'count': 5})
        .assistant('Electronics trending right now in Tanzania:',
            instant: true)
        .product(ProductCardData(
          name: 'Samsung Galaxy S24 Ultra',
          image:
              'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=400',
          price: 2800000,
          originalPrice: 3200000,
          store: 'TechWorld',
          rating: 4.9,
          reviews: 412,
          specs: ['256GB', '6.8" QHD+', 'Snapdragon 8 Gen 3', '200MP Camera'],
          badge: '95% Trending',
        ))
        .product(ProductCardData(
          name: 'AirPods Pro 2',
          image:
              'https://images.unsplash.com/photo-1606220588913-b3aacb4d2f46?w=400',
          price: 650000,
          originalPrice: 800000,
          store: 'GadgetHub',
          rating: 4.7,
          reviews: 328,
          specs: ['Active Noise Cancellation', 'USB-C', 'Adaptive Audio', '6h battery'],
          badge: '88% Trending',
        ))
        .product(ProductCardData(
          name: 'Sony WH-1000XM5',
          image:
              'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=400',
          price: 900000,
          originalPrice: 1100000,
          store: 'AudioPro',
          rating: 4.8,
          reviews: 256,
          specs: ['Industry-best ANC', '30h battery', 'Multipoint BT', 'LDAC'],
          badge: '82% Trending',
        ))
        .assistant(
            '\n\nShall I show you the best prices for any of these? ⚡');
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final distance = maxScroll - currentScroll;
    final atBottom = distance < 80;

    if (atBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = atBottom;
        _showJumpButton = !atBottom;
      });
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(position);
    }
  }

  Future<void> _sendNext() async {
    if (_isStreaming || !_engine.hasMoreTurns) return;

    setState(() => _isStreaming = true);

    final stream = _engine.sendNext();
    await for (final _ in stream) {
      if (!mounted) return;
      setState(() {
        _messages = List.from(_engine.messages);
      });
      if (_isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }

    if (mounted) {
      setState(() => _isStreaming = false);
      _saveCurrentChat();
    }
  }

  Future<void> _sendCustom(String text) async {
    if (_isStreaming || text.trim().isEmpty) return;

    setState(() => _isStreaming = true);

    final lower = text.toLowerCase();
    _engine.user(text);

    if (lower.contains('iphone') || lower.contains('phone') || lower.contains('samsung')) {
      _engine
          .reasoning('User is asking about phones. Let me search for relevant products.')
          .tool('searchProducts',
              input: {'query': text, 'limit': 3}, output: {'count': 2})
          .assistant('Here are some phones I found for you:', instant: true)
          .product(ProductCardData(
            name: 'Samsung Galaxy S24 Ultra',
            image:
                'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=400',
            price: 2800000,
            originalPrice: 3200000,
            store: 'TechWorld',
            rating: 4.9,
            reviews: 412,
            specs: ['256GB', '6.8" QHD+', 'Snapdragon 8 Gen 3', '200MP Camera'],
            badge: 'Best Seller',
          ))
          .product(ProductCardData(
            name: 'iPhone 15 128GB',
            image:
                'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400',
            price: 1800000,
            originalPrice: 2200000,
            store: 'TechWorld',
            rating: 4.8,
            reviews: 234,
            specs: ['128GB Storage', '6.1" OLED', 'A16 Bionic', '48MP Camera'],
            badge: 'Best Value',
          ))
          .assistant('\n\nWould you like more details on any of these? 📱');
    } else if (lower.contains('trend') || lower.contains('popular') || lower.contains('hot')) {
      _engine
          .reasoning('User wants trending products. Fetching current trends.')
          .tool('getTrending',
              input: {'category': 'all', 'limit': 3}, output: {'count': 3})
          .assistant('Here\'s what\'s trending right now:', instant: true)
          .product(ProductCardData(
            name: 'AirPods Pro 2',
            image:
                'https://images.unsplash.com/photo-1606220588913-b3aacb4d2f46?w=400',
            price: 650000,
            originalPrice: 800000,
            store: 'GadgetHub',
            rating: 4.7,
            reviews: 328,
            specs: ['Active Noise Cancellation', 'USB-C', 'Adaptive Audio', '6h battery'],
            badge: '88% Trending',
          ))
          .product(ProductCardData(
            name: 'Sony WH-1000XM5',
            image:
                'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=400',
            price: 900000,
            originalPrice: 1100000,
            store: 'AudioPro',
            rating: 4.8,
            reviews: 256,
            specs: ['Industry-best ANC', '30h battery', 'Multipoint BT', 'LDAC'],
            badge: '82% Trending',
          ))
          .assistant('\n\nThese are flying off the shelves! Want me to find deals? 🔥');
    } else if (lower.contains('deal') || lower.contains('cheap') || lower.contains('discount') || lower.contains('wholesale')) {
      _engine
          .reasoning('User is looking for deals. Let me find the best discounts.')
          .tool('searchDeals',
              input: {'type': 'flash', 'limit': 3}, output: {'count': 2})
          .assistant('I found some amazing deals for you! 💰', instant: true)
          .product(ProductCardData(
            name: 'iPhone 15 (Refurbished)',
            image:
                'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400',
            price: 1450000,
            originalPrice: 2200000,
            store: 'RefurbStore',
            rating: 4.3,
            reviews: 97,
            specs: ['128GB Storage', '6.1" OLED', 'A16 Bionic', '90-day warranty'],
            badge: '34% OFF',
          ))
          .product(ProductCardData(
            name: 'AirPods Pro 2',
            image:
                'https://images.unsplash.com/photo-1606220588913-b3aacb4d2f46?w=400',
            price: 650000,
            originalPrice: 800000,
            store: 'GadgetHub',
            rating: 4.7,
            reviews: 328,
            specs: ['Active Noise Cancellation', 'USB-C', 'Adaptive Audio', '6h battery'],
            badge: '19% OFF',
          ))
          .assistant('\n\nThese are the best discounts available right now! 🏷️');
    } else {
      _engine.assistant(
          'I\'m XerinAI, your shopping assistant! I can help you find products, compare prices, and discover deals. Try asking me about specific products or what\'s trending! 🛍️',
          instant: true);
    }

    final stream = _engine.sendNext();
    await for (final _ in stream) {
      if (!mounted) return;
      setState(() {
        _messages = List.from(_engine.messages);
      });
      if (_isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }

    if (mounted) {
      setState(() => _isStreaming = false);
      _saveCurrentChat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/icons/uicons-thin-rounded/ai.png',
              width: 26,
              height: 26,
            ),
            const SizedBox(width: 10),
            Text(
              'XerinAI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'BETA',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded,
                size: 20, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            onPressed: _showHistorySheet,
            tooltip: 'Chat History',
          ),
          IconButton(
            icon: Icon(Icons.add_comment_outlined,
                size: 20, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _messages.isEmpty
                    ? _buildWelcome(colorScheme, isDark)
                    : _buildMessageList(colorScheme, isDark),
                if (_showJumpButton) _buildJumpToLatest(colorScheme),
              ],
            ),
          ),
          _buildInputBar(colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildWelcome(ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 48),
          _buildPulseLogo(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'COMING SOON',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your AI Shopping Assistant',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Discover products, compare prices, find deals, and shop smarter — all through natural conversation.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._suggestedPrompts.map((prompt) => _buildSuggestedPrompt(
                prompt,
                colorScheme,
                isDark,
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompt(
      String text, ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _isStreaming ? null : () => _sendNext(),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.onSurface.withValues(alpha: 0.04)
                : colorScheme.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseLogo() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFF9800).withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Image.asset(
          'assets/icons/uicons-thin-rounded/ai.png',
          width: 44,
          height: 44,
        ),
      ),
    );
  }

  Widget _buildMessageList(ColorScheme colorScheme, bool isDark) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final msg = _messages[index];
                return _MessageBubble(
                  key: ValueKey(msg.id),
                  message: msg,
                  colorScheme: colorScheme,
                  isDark: isDark,
                );
              },
              childCount: _messages.length,
            ),
          ),
        ),
        if (_isStreaming) _buildThinkingIndicator(colorScheme),
      ],
    );
  }

  Widget _buildThinkingIndicator(ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 32, bottom: 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/uicons-thin-rounded/ai.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            _ShimmerText(
              text: 'Thinking...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              duration: const Duration(milliseconds: 1500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJumpToLatest(ColorScheme colorScheme) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => _scrollToBottom(),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Jump to latest',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.arrow_downward_rounded,
                size: 14,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme, bool isDark) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          border: Border(
            top: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.onSurface.withValues(alpha: 0.06)
                      : colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  enabled: !_isStreaming,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask XerinAI anything...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.mic_none_rounded,
                        size: 20,
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _sendCustom(text);
                      _inputCtrl.clear();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isStreaming
                  ? null
                  : () {
                      final text = _inputCtrl.text.trim();
                      if (text.isNotEmpty) {
                        _sendCustom(text);
                        _inputCtrl.clear();
                      } else if (_engine.hasMoreTurns) {
                        _sendNext();
                      }
                    },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isStreaming
                      ? colorScheme.onSurface.withValues(alpha: 0.1)
                      : const Color(0xFFFF9800),
                  shape: BoxShape.circle,
                ),
                child: _isStreaming
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme colorScheme;
  final bool isDark;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Image.asset(
              'assets/icons/uicons-thin-rounded/ai.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children:
                  message.parts.map((p) => _buildPart(context, p, isUser)).toList(),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildPart(BuildContext context, MessagePart part, bool isUser) {
    switch (part.type) {
      case MessagePartType.text:
        return _buildTextBubble(part.text ?? '', isUser, part.isStreaming);
      case MessagePartType.reasoning:
        return _buildReasoning(part.text ?? '', part.isStreaming);
      case MessagePartType.toolCall:
        return _buildToolCard(part);
      case MessagePartType.productCard:
        return _buildProductCard(context, part.product!);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextBubble(String text, bool isUser, bool isStreaming) {
    if (text.isEmpty && isStreaming) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser
            ? colorScheme.primary
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        border: isUser
            ? null
            : Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: isUser || isDark
            ? null
            : [
                BoxShadow(
                  color: colorScheme.onSurface.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
          if (isStreaming) ...[
            const SizedBox(width: 4),
            const _BlinkingCursor(),
          ],
        ],
      ),
    );
  }

  Widget _buildReasoning(String text, bool isStreaming) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: isStreaming
                ? _ShimmerText(
                    text: text,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      height: 1.3,
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      height: 1.3,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(MessagePart part) {
    final isRunning = part.isStreaming;
    final hasOutput = part.toolOutput != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isRunning)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF9800),
                  ),
                )
              else
                Icon(
                  hasOutput ? Icons.check_circle : Icons.error_outline,
                  size: 14,
                  color: hasOutput ? Colors.green : Colors.red,
                ),
              const SizedBox(width: 8),
              Text(
                _toolDisplayName(part.toolName ?? ''),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF9800),
                ),
              ),
              const Spacer(),
              Text(
                isRunning ? 'Running...' : 'Done',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          if (part.toolInput != null) ...[
            const SizedBox(height: 6),
            Text(
              _formatInput(part.toolInput!),
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontFamily: 'monospace',
              ),
            ),
          ],
          if (hasOutput) ...[
            const SizedBox(height: 6),
            Text(
              '${_countResults(part.toolOutput!)} results found',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductCardData product) {
    final hasDiscount =
        product.originalPrice != null && product.originalPrice! > product.price;
    final discountPercent = hasDiscount
        ? ((1 - product.price / product.originalPrice!) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () {
        final productModel = ProductModel(
          id: product.name.replaceAll(' ', '-').toLowerCase(),
          sellerId: '',
          categoryId: '',
          sku: '',
          name: product.name,
          slug: product.name.replaceAll(' ', '-').toLowerCase(),
          price: product.price,
          salePrice: hasDiscount ? product.price : null,
          rating: product.rating,
          images: [product.image],
        );
        GoRouter.of(context).push(
          AppConstants.productDetailRoute,
          extra: {
            'product': productModel,
            'category': 'AI Recommendation',
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Small image with badge
            Stack(
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                    child: Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.06),
                          child: Icon(
                            Icons.image_outlined,
                            size: 24,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.2),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.04),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress
                                            .expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFFFF9800),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (product.badge != null)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasDiscount
                            ? const Color(0xFFE53935)
                            : const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.badge!,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Store + rating
                    Row(
                      children: [
                        Icon(Icons.storefront_outlined,
                            size: 10,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.4)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            product.store,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded,
                            size: 11, color: Colors.amber[600]),
                        const SizedBox(width: 1),
                        Text(
                          '${product.rating}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Top 2 specs
                    if (product.specs.isNotEmpty)
                      Text(
                        product.specs.take(2).join(' · '),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.35),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatPrice(product.price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            _formatPrice(product.originalPrice!),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '-$discountPercent%',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _toolDisplayName(String name) {
    switch (name) {
      case 'searchProducts':
        return '🔍 Search Products';
      case 'getTrending':
        return '📈 Get Trending';
      case 'searchDeals':
        return '💰 Search Deals';
      default:
        return name;
    }
  }

  String _formatInput(Map<String, dynamic> input) {
    return input.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  int _countResults(Map<String, dynamic> output) {
    final results = output['results'] ?? output['products'] ?? output['count'];
    if (results is List) return results.length;
    if (results is int) return results;
    return 0;
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)}M TZS';
    } else if (price >= 1000) {
      return '${(price / 1000).round()}K TZS';
    }
    return '${price.round()} TZS';
  }
}

class _ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const _ShimmerText({
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 0.3, 0),
              end: Alignment(_animation.value + 0.3, 0),
              colors: [
                widget.style.color ?? Colors.grey,
                Colors.white,
                widget.style.color ?? Colors.grey,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style.copyWith(color: Colors.white),
          ),
        );
      },
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _controller.value < 0.5 ? 1.0 : 0.0,
          child: Container(
            width: 2,
            height: 14,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}

class _ChatHistoryEntry {
  final String id;
  final String title;
  final String preview;
  final DateTime timestamp;
  final int messageCount;

  _ChatHistoryEntry({
    required this.id,
    required this.title,
    required this.preview,
    required this.timestamp,
    required this.messageCount,
  });
}
