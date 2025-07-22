import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // Store the name in user metadata
      );

      // If signup successful and user is confirmed, create profile
      if (response.user != null) {
        await _createUserProfile(
          userId: response.user!.id,
          name: name,
          email: email,
        );
      }

      return response;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Create user profile in database
Future<void> _createUserProfile({
  required String userId,
  required String name,
  required String email,
}) async {
  try {
    final response = await _supabase.from('users').insert({
      'user_id': userId,
      'name': name,
      'email': email,
      'registration_date': DateTime.now().toIso8601String(),
    });

    if (response.error != null) {
      print('Insert error: ${response.error!.message}');
    } else {
      print('User profile created successfully!');
    }
  } catch (e) {
    print('Exception during profile creation: $e');
  }
}


  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isLoggedIn) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_id', currentUser!.id)
          .single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  void logout() {}
}