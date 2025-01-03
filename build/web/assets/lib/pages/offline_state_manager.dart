import 'dart:async';

class OfflineStateManager {
  static final OfflineStateManager _instance = OfflineStateManager._internal();
  factory OfflineStateManager() => _instance;
  OfflineStateManager._internal();

  // Stream controllers
  final _userIdController = StreamController<String>.broadcast();
  
  // Current values
  String? _currentUserId;

  // Getters
  Stream<String> get userIdStream => _userIdController.stream;
  String? get currentUserId => _currentUserId;

  // Setters
  void setUserId(String userId) {
    _currentUserId = userId;
    _userIdController.add(userId);
  }

  // Cleanup
  void dispose() {
    _userIdController.close();
  }
}
