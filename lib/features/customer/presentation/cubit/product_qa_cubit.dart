import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/product_qa_remote_datasource.dart';
import '../../data/models/product_qa_model.dart';

abstract class ProductQaState {
  const ProductQaState();
}

class ProductQaInitial extends ProductQaState {
  const ProductQaInitial();
}

class ProductQaLoading extends ProductQaState {
  const ProductQaLoading();
}

class ProductQaLoaded extends ProductQaState {
  final List<ProductQuestionModel> questions;
  final int total;

  const ProductQaLoaded({required this.questions, this.total = 0});
}

class ProductQaSubmitting extends ProductQaState {
  const ProductQaSubmitting();
}

class ProductQaError extends ProductQaState {
  final String message;
  const ProductQaError(this.message);
}

class ProductQaCubit extends Cubit<ProductQaState> {
  final ProductQaRemoteDataSource _dataSource;
  final Logger _logger;

  ProductQaCubit({
    required ProductQaRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const ProductQaInitial());

  Future<void> loadQuestions(String productId, {int page = 1}) async {
    emit(const ProductQaLoading());
    try {
      final response = await _dataSource.getQuestions(productId, page: page);
      emit(ProductQaLoaded(questions: response.results, total: response.total));
    } catch (e) {
      _logger.e('❌ Failed to load Q&A: $e');
      emit(ProductQaError(e.toString()));
    }
  }

  Future<void> askQuestion({required String productId, required String question}) async {
    emit(const ProductQaSubmitting());
    try {
      await _dataSource.askQuestion(productId: productId, question: question);
      _logger.i('✅ Question submitted');
      await loadQuestions(productId);
    } catch (e) {
      _logger.e('❌ Failed to submit question: $e');
      emit(ProductQaError(e.toString()));
    }
  }

  Future<void> answerQuestion({required String questionId, required String answer, String? productId}) async {
    try {
      await _dataSource.answerQuestion(questionId: questionId, answer: answer);
      _logger.i('✅ Answer submitted');
      if (productId != null) await loadQuestions(productId);
    } catch (e) {
      _logger.e('❌ Failed to submit answer: $e');
    }
  }

  Future<void> voteHelpful(String questionId) async {
    try {
      await _dataSource.voteQuestionHelpful(questionId);
    } catch (e) {
      _logger.e('❌ Failed to vote: $e');
    }
  }
}
