import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final String? deviceUuid;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.deviceUuid,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    String? deviceUuid,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      deviceUuid: deviceUuid ?? this.deviceUuid,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthState(deviceUuid: ApiClient.instance.deviceUuid)) {
    // If running in development demo mode, initialize with demo cashier
    _initDemoSession();
  }

  void _initDemoSession() {
    state = state.copyWith(
      user: const UserModel(
        uuid: 'cashier-demo-uuid',
        name: 'Sarah Miller',
        email: 'cashier1@smartshop.com',
        role: 'cashier',
        store: StoreModel(
          uuid: 'store-main-uuid',
          name: 'Main Downtown Store',
          currencySymbol: 'Rs.',
          currencyCode: 'LKR',
          address: '42 Galle Road, Colombo 03',
          phone: '+94 11 234 5678',
          receiptHeader: 'SMARTSHOP RETAIL PVT LTD',
          receiptFooter: 'Thank you for shopping! Come again.',
        ),
      ),
      deviceUuid: ApiClient.instance.deviceUuid,
    );
  }

  Future<bool> loginWithPin({required String pinCode, required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.login(email: email, pinCode: pinCode);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> loginWithPassword({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = state.copyWith(clearUser: true);
  }

  Future<bool> pairDevice({required String pairingCode, required String deviceName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.pairDevice(pairingCode: pairingCode, deviceName: deviceName);
      state = state.copyWith(isLoading: false, deviceUuid: ApiClient.instance.deviceUuid);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
