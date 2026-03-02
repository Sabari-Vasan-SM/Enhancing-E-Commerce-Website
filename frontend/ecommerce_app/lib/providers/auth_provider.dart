import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce_app/core/constants.dart';
import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/services/api_service.dart';
import 'package:ecommerce_app/services/websocket_service.dart';

/// Global API service instance.
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Global WebSocket service instance.
final webSocketServiceProvider = Provider<WebSocketService>((ref) => WebSocketService());

/// Authentication state - holds the current user or null.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AsyncValue.data(null)) {
    _loadSavedSession();
  }

  /// Load saved auth session from SharedPreferences.
  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        final api = ref.read(apiServiceProvider);
        api.setToken(token);
        final profileData = await api.getProfile();
        final user = UserModel.fromJson(profileData);
        state = AsyncValue.data(user);

        // Connect WebSocket
        final ws = ref.read(webSocketServiceProvider);
        ws.connect(user.id, token);

        // Listen for user type changes
        _listenForTypeChanges(user.id);
      }
    } catch (e) {
      // Token expired or invalid - clear session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      state = const AsyncValue.data(null);
    }
  }

  Future<void> register(
      String email, String username, String password, String? fullName) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiServiceProvider);
      await api.register(email, username, password, fullName);

      // Auto-login after register
      await login(email, password);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiServiceProvider);
      final tokenData = await api.login(email, password);
      final token = AuthToken.fromJson(tokenData);

      // Save token
      api.setToken(token.accessToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token.accessToken);
      await prefs.setInt(AppConstants.userIdKey, token.userId);
      await prefs.setString(AppConstants.userTypeKey, token.userType);

      // Get full profile
      final profileData = await api.getProfile();
      final user = UserModel.fromJson(profileData);
      state = AsyncValue.data(user);

      // Connect WebSocket
      final ws = ref.read(webSocketServiceProvider);
      ws.connect(user.id, token.accessToken);
      _listenForTypeChanges(user.id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final api = ref.read(apiServiceProvider);
    api.clearToken();

    final ws = ref.read(webSocketServiceProvider);
    ws.disconnect();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userTypeKey);

    state = const AsyncValue.data(null);
  }

  /// Listen for real-time user type changes via WebSocket.
  void _listenForTypeChanges(int userId) {
    final ws = ref.read(webSocketServiceProvider);
    ws.stream?.listen((message) {
      if (message['event'] == 'user_type_changed') {
        final data = message['data'];
        final currentUser = state.value;
        if (currentUser != null) {
          state = AsyncValue.data(
            currentUser.copyWith(
              userType: data['user_type'],
              userTypeConfidence: (data['confidence'] ?? 0.0).toDouble(),
            ),
          );

          // Update user type provider
          ref.read(userTypeProvider.notifier).state = data['user_type'];
        }
      }
    });
  }
}

/// Current user type - drives UI selection.
final userTypeProvider = StateProvider<String>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.userType ?? AppConstants.typeExploration;
});

/// Whether user is logged in.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).value != null;
});
