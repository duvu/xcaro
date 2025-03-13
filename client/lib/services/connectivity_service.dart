import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  bool _hasConnection = true;

  ConnectivityService() {
    _init();
  }

  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool get hasConnection => _hasConnection;

  void _init() {
    _checkConnection();
    _connectivity.onConnectivityChanged.listen((_) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _hasConnection = result != ConnectivityResult.none;
    } catch (e) {
      _hasConnection = false;
    }
    _controller.add(_hasConnection);
  }

  void dispose() {
    _controller.close();
  }
}
