import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/search_cubit.dart';
import '../../data/models/product_model.dart';
import 'product_detail_page.dart';
import '../../../../core/theme/uicons.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _sort = 'relevance';

  @override
  void initState() {
    super.initState();
    context.read<SearchCubit>().loadTrending();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      context.read<SearchCubit>().search(query: query, sort: _sort);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Uicons.search),
              onPressed: _performSearch,
            ),
          ),
          onSubmitted: (_) => _performSearch(),
          autofocus: true,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Uicons.sort),
            onSelected: (value) {
              setState(() => _sort = value);
              _performSearch();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'relevance', child: Text('Relevance')),
              PopupMenuItem(value: 'newest', child: Text('Newest')),
              PopupMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
              PopupMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
              PopupMenuItem(value: 'popular', child: Text('Most Popular')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SearchError) {
            return Center(child: Text(state.message));
          }
          if (state is SearchLoaded) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('${state.total} results for "${state.query}"'),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      return _SearchProductCard(product: state.results[index]);
                    },
                  ),
                ),
              ],
            );
          }
          if (state is SearchTrendingLoaded) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Trending Searches',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: state.trending.map((item) {
                    return ActionChip(
                      label: Text(item.term),
                      onPressed: () {
                        _controller.text = item.term;
                        _performSearch();
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          }
          return const Center(child: Text('Start searching...'));
        },
      ),
    );
  }
}

class _SearchProductCard extends StatelessWidget {
  final ProductModel product;

  const _SearchProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/product-detail', extra: {'product': product});
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Icon(Uicons.image, size: 48),
                    )
                  : const Icon(Uicons.image, size: 48),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
