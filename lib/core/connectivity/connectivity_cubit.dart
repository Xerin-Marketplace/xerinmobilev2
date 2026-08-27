import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity = Connectivity();

  ConnectivityCubit() : super(const ConnectivityState.initial()) {
    _connectivity.onConnectivityChanged.listen(_onChanged);
    check();
  }

  Future<void> check() async {
    try {
      final result = await _connectivity.checkConnectivity();
      debugPrint('ConnectivityCubit: checkConnectivity result = $result');
      _onChanged(result);
    } catch (e) {
      debugPrint('ConnectivityCubit: check error = $e');
      emit(const ConnectivityState.online());
    }
  }

  void _onChanged(List<ConnectivityResult> result) {
    debugPrint('ConnectivityCubit: stream result = $result');
    final isNone = result.isEmpty ||
        result.every((r) => r == ConnectivityResult.none);
    if (isNone) {
      emit(const ConnectivityState.offline());
    } else {
      emit(const ConnectivityState.online());
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
