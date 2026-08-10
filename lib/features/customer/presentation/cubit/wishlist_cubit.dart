import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/wishlist_remote_datasource.dart';
import '../../data/models/wishlist_item_model.dart';
import 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  final WishlistRemoteDataSource _dataSource;
  final Logger _logger;

  WishlistCubit({
    required this._dataSource,
    required this._logger,
  })  : super(const WishlistInitial());

  Future<void> loadWishlist() async {
    emit(const WishlistLoading());
    try {
      final items = await _dataSource.getWishlist();
      _logger.i('✅ Wishlist loaded: ${items.length} items');
      emit(WishlistLoaded(items: items));
    } catch (e) {
      _logger.e('❌ Failed to load wishlist: $e');
      emit(WishlistError(e.toString()));
    }
  }

  void toggleSelection(String itemId) {
    final current = state;
    if (current is! WishlistLoaded) return;
    final selected = Set<String>.from(current.selectedIds);
    if (selected.contains(itemId)) {
      selected.remove(itemId);
    } else {
      selected.add(itemId);
    }
    emit(current.copyWith(selectedIds: selected));
  }

  void selectAll() {
    final current = state;
    if (current is! WishlistLoaded) return;
    emit(current.copyWith(
      selectedIds: current.items.map((i) => i.id).toSet(),
    ));
  }

  void clearSelection() {
    final current = state;
    if (current is! WishlistLoaded) return;
    emit(current.copyWith(selectedIds: const {}));
  }

  Future<void> removeItem(String itemId) async {
    final current = state;
    if (current is! WishlistLoaded) return;
    final item = current.items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;
    try {
      await _dataSource.removeFromWishlist(productId: item.productId);
      final updated = current.items.where((i) => i.id != itemId).toList();
      final selected = Set<String>.from(current.selectedIds)..remove(itemId);
      _logger.i('✅ Wishlist item removed: $itemId');
      emit(current.copyWith(items: updated, selectedIds: selected));
    } catch (e) {
      _logger.e('❌ Failed to remove wishlist item: $e');
    }
  }

  Future<void> removeSelected() async {
    final current = state;
    if (current is! WishlistLoaded || current.selectedIds.isEmpty) return;
    try {
      for (final item in current.items.where((i) => current.selectedIds.contains(i.id))) {
        await _dataSource.removeFromWishlist(productId: item.productId);
      }
      final updated = current.items.where((i) => !current.selectedIds.contains(i.id)).toList();
      _logger.i('✅ Removed ${current.selectedIds.length} wishlist items');
      emit(WishlistLoaded(items: updated));
    } catch (e) {
      _logger.e('❌ Failed to remove selected wishlist items: $e');
    }
  }

  Future<void> toggleProductWishlist({required String productId}) async {
    try {
      await _dataSource.toggleWishlistItem(productId: productId);
      _logger.i('✅ Wishlist toggled for product: $productId');
      await loadWishlist();
    } catch (e) {
      _logger.e('❌ Failed to toggle wishlist: $e');
    }
  }

  List<WishlistItemModel> get selectedItems {
    final current = state;
    if (current is! WishlistLoaded) return [];
    return current.items.where((i) => current.selectedIds.contains(i.id)).toList();
  }
}
