part of 'connectivity_cubit.dart';

enum ConnectivityStatus { initial, online, offline }

class ConnectivityState extends Equatable {
  final ConnectivityStatus status;

  const ConnectivityState._({required this.status});

  const ConnectivityState.initial()
      : this._(status: ConnectivityStatus.initial);

  const ConnectivityState.online()
      : this._(status: ConnectivityStatus.online);

  const ConnectivityState.offline()
      : this._(status: ConnectivityStatus.offline);

  bool get isOffline => status == ConnectivityStatus.offline;
  bool get isOnline =>
      status == ConnectivityStatus.online ||
      status == ConnectivityStatus.initial;

  @override
  List<Object?> get props => [status];
}
