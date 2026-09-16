import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  const OnboardingStorage();

  static const completedKey = 'kitchen_onboarding_completed_v1';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(completedKey) ?? false;
  }

  Future<void> setCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completedKey, true);
  }
}

final onboardingStorageProvider = Provider<OnboardingStorage>(
  (ref) => const OnboardingStorage(),
);

final onboardingCompletedProvider = FutureProvider<bool>(
  (ref) => ref.watch(onboardingStorageProvider).isCompleted(),
);
