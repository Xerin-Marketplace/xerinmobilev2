import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/review_remote_datasource.dart';
import '../../data/models/review_model.dart';

abstract class ReviewState {
  const ReviewState();
}

class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

class ReviewsLoaded extends ReviewState {
  final List<ReviewModel> reviews;
  final double averageRating;
  final int total;

  const ReviewsLoaded({
    required this.reviews,
    this.averageRating = 0.0,
    this.total = 0,
  });
}

class ReviewSubmitting extends ReviewState {
  const ReviewSubmitting();
}

class ReviewSubmitted extends ReviewState {
  final ReviewModel review;

  const ReviewSubmitted(this.review);
}

class ReviewError extends ReviewState {
  final String message;
  const ReviewError(this.message);
}

class ReviewCubit extends Cubit<ReviewState> {
  final ReviewRemoteDataSource _dataSource;
  final Logger _logger;

  ReviewCubit({
    required ReviewRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const ReviewInitial());

  Future<void> loadProductReviews(String productId, {int page = 1}) async {
    emit(const ReviewLoading());
    try {
      final response = await _dataSource.getProductReviews(productId, page: page);
      emit(ReviewsLoaded(
        reviews: response.results,
        averageRating: response.averageRating,
        total: response.total,
      ));
    } catch (e) {
      _logger.e('❌ Failed to load reviews: $e');
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> loadStoreReviews(String slug, {int page = 1}) async {
    emit(const ReviewLoading());
    try {
      final response = await _dataSource.getStoreReviews(slug, page: page);
      emit(ReviewsLoaded(
        reviews: response.results,
        averageRating: response.averageRating,
        total: response.total,
      ));
    } catch (e) {
      _logger.e('❌ Failed to load store reviews: $e');
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> submitProductReview({
    required String productId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    emit(const ReviewSubmitting());
    try {
      final review = await _dataSource.createProductReview(
        productId: productId,
        rating: rating,
        title: title,
        comment: comment,
      );
      _logger.i('✅ Review submitted');
      emit(ReviewSubmitted(review));
      await loadProductReviews(productId);
    } catch (e) {
      _logger.e('❌ Failed to submit review: $e');
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> submitStoreReview({
    required String slug,
    required int rating,
    String? title,
    String? comment,
  }) async {
    emit(const ReviewSubmitting());
    try {
      final review = await _dataSource.createStoreReview(
        slug: slug,
        rating: rating,
        title: title,
        comment: comment,
      );
      _logger.i('✅ Store review submitted');
      emit(ReviewSubmitted(review));
      await loadStoreReviews(slug);
    } catch (e) {
      _logger.e('❌ Failed to submit store review: $e');
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> deleteReview(String reviewId, {String? productId}) async {
    try {
      await _dataSource.deleteReview(reviewId);
      _logger.i('✅ Review deleted');
      if (productId != null) await loadProductReviews(productId);
    } catch (e) {
      _logger.e('❌ Failed to delete review: $e');
    }
  }
}
