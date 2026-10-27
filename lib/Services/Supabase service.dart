import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One place for every Supabase call the app makes. Keeps Upload,
/// Resources, CourseDetail etc. free of raw Supabase calls — they just
/// call methods on this class.
///
/// Usage:
///   final service = SupabaseService();
///   await service.signIn(email: ..., password: ...);
///
/// Setup (in main.dart, before runApp):
///   await Supabase.initialize(
///     url: 'YOUR_PROJECT_URL',
///     anonKey: 'YOUR_ANON_KEY',
///   );
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ---------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------

  /// Creates the auth user AND the matching profiles row in one go.
  /// Call this from Sign Up's onPressed.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'student' or 'admin'
    String? department,
    String? level,
  }) async {
    final AuthResponse res = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final String? userId = res.user?.id;
    if (userId == null) {
      throw Exception('Sign up did not return a user id.');
    }

    await _client.from('profiles').insert({
      'id': userId,
      'full_name': fullName,
      'role': role,
      'department': department,
      'level': level,
    });
  }

  /// Call this from Sign In's onPressed.
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    // Re-syncs this user's role against the admin_emails allowlist,
    // in case they were added/removed since they last signed in.
    await _client.rpc('refresh_my_role');
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Sends a password reset email. Call this from "Forgot password?".
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.acadly://reset-password/',
    );
  }

  /// Saves the new password after the user opens the reset link.
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Fires when the user opens the reset link from their email.
  /// Listen to this to show the "Set new password" screen.
  Stream<AuthState> get onPasswordRecovery => _client.auth.onAuthStateChange
      .where((data) => data.event == AuthChangeEvent.passwordRecovery);

  bool get isSignedIn => _client.auth.currentUser != null;

  String? get currentUserEmail => _client.auth.currentUser?.email;

  /// Deletes the user's profiles row and signs them out. This does NOT
  /// delete the underlying Supabase Auth login — that requires the
  /// service_role key, which must never live inside the Flutter app.
  /// Full deletion needs a server-side Edge Function; this is the
  /// safe client-side equivalent (no profile = no access in-app).
  Future<void> deleteAccount() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _client.from('profiles').delete().eq('id', userId);
    }
    await _client.auth.signOut();
  }

  /// True only if this user's profile row has role == 'admin'.
  /// Use this to decide whether to show "Switch to Admin" on Profile.
  Future<bool> isCurrentUserAdmin() async {
    final profile = await getMyProfile();
    return profile?['role'] == 'admin';
  }

  /// The current user's profile row (role, department, level, full_name).
  Future<Map<String, dynamic>?> getMyProfile() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return await _client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  // ---------------------------------------------------------------
  // MATERIALS — reading
  // ---------------------------------------------------------------

  /// Course count comes from your own courseData map (it's fixed
  /// curriculum data, not something Supabase needs to store). This
  /// only returns how many MATERIAL rows exist for a level+semester —
  /// what replaces the hardcoded "0 Materials" text.
  Future<int> materialsCountForLevel({
    required String level,
    required String semester,
  }) async {
    final List<dynamic> rows = await _client
        .from('materials')
        .select('id')
        .eq('level', level)
        .eq('semester', semester);
    return rows.length;
  }

  /// Every material of one type ('pdf' | 'video' | 'pq') for one course —
  /// what CourseDetail's PDFs/Videos/Past Questions tabs should show
  /// instead of "No X uploaded yet".
  Future<List<Map<String, dynamic>>> materialsForCourse({
    required String courseCode,
    required String materialType,
  }) async {
    final List<dynamic> rows = await _client
        .from('materials')
        .select()
        .eq('course_code', courseCode)
        .eq('material_type', materialType)
        .order('created_at', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  /// Total materials across the whole app — for the Admin Dashboard's
  /// "Total Materials" stat card (currently hardcoded to '0').
  Future<int> totalMaterialsCount() async {
    final List<dynamic> rows = await _client.from('materials').select('id');
    return rows.length;
  }

  // ---------------------------------------------------------------
  // MATERIALS — uploading (admin only; RLS enforces this server-side too)
  // ---------------------------------------------------------------

  static const String _bucket = 'materials';

  /// Uploads the raw file bytes to Storage and returns the storage path
  /// to save as materials.file_url. Call this from Upload._submit()
  /// before inserting the database row.
  Future<String> uploadFile({
    required List<int> bytes,
    required String fileName,
    required String level,
    required String semester,
    required String courseCode,
  }) async {
    // Namespaced path keeps the bucket organized and avoids name clashes.
    final String path =
        '$level/$semester/$courseCode/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
        );

    return path;
  }

  /// Inserts the materials row after uploadFile() succeeds.
  Future<void> insertMaterialRecord({
    required String level,
    required String semester,
    required String courseCode,
    required String materialType,
    required String fileUrl,
    required String fileName,
  }) async {
    final String? userId = _client.auth.currentUser?.id;
    await _client.from('materials').insert({
      'level': level,
      'semester': semester,
      'course_code': courseCode,
      'material_type': materialType,
      'file_url': fileUrl,
      'file_name': fileName,
      'uploaded_by': userId,
    });
  }

  /// A signed URL (valid for [expiresInSeconds]) to actually open/download
  /// a file from a private bucket. Use this wherever a student taps a
  /// material to view/download it.
  Future<String> getSignedUrl(String path, {int expiresInSeconds = 3600}) {
    return _client.storage.from(_bucket).createSignedUrl(path, expiresInSeconds);
  }

  // ---------------------------------------------------------------
  // MATERIALS — editing & deleting (admin only; RLS enforces this too)
  // ---------------------------------------------------------------

  /// Deletes both the storage file and the database row. Call this from
  /// the admin's Delete action on a material.
  Future<void> deleteMaterial({
    required String materialId,
    required String storagePath,
  }) async {
    await _client.storage.from(_bucket).remove([storagePath]);
    await _client.from('materials').delete().eq('id', materialId);
  }

  /// "Edit" a material by replacing its file: uploads the new bytes,
  /// removes the old storage file, and updates the existing row in
  /// place (same id, so it doesn't move in student/admin lists).
  Future<void> replaceMaterialFile({
    required String materialId,
    required String oldStoragePath,
    required List<int> newBytes,
    required String newFileName,
    required String level,
    required String semester,
    required String courseCode,
  }) async {
    final String newPath = await uploadFile(
      bytes: newBytes,
      fileName: newFileName,
      level: level,
      semester: semester,
      courseCode: courseCode,
    );

    await _client.from('materials').update({
      'file_url': newPath,
      'file_name': newFileName,
    }).eq('id', materialId);

    // Best-effort cleanup of the old file; don't fail the edit if this
    // errors (e.g. the old path was already gone).
    try {
      await _client.storage.from(_bucket).remove([oldStoragePath]);
    } catch (_) {}
  }

  // ---------------------------------------------------------------
  // ACTIVITY — what the current student opened / downloaded
  // ---------------------------------------------------------------

  /// Logs that the current user opened or downloaded a material.
  /// Stores a SNAPSHOT of the material's details on the activity row
  /// itself (not just a reference) — so if an admin later deletes the
  /// material, this history entry still shows what it was.
  Future<void> logActivity({
    required String materialId,
    required String action, // 'opened' or 'downloaded'
    required String fileName,
    required String materialType,
    required String level,
    required String semester,
    required String courseCode,
    required String storagePath,
  }) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('material_activity').insert({
      'user_id': userId,
      'material_id': materialId,
      'action': action,
      'file_name': fileName,
      'material_type': materialType,
      'level': level,
      'semester': semester,
      'course_code': courseCode,
      'storage_path': storagePath,
    });
  }

  /// Every material this user has opened or downloaded, most recent
  /// first — reads straight from the snapshot, so it still shows full
  /// details even if the underlying material was since deleted.
  Future<List<Map<String, dynamic>>> getMyActivity(String action) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final List<dynamic> rows = await _client
        .from('material_activity')
        .select()
        .eq('user_id', userId)
        .eq('action', action)
        .order('created_at', ascending: false);

    return rows.cast<Map<String, dynamic>>();
  }

  /// Downloads the raw bytes of a file from Storage (respecting the
  /// same read policy as everything else) — used to save it locally so
  /// the OS can show its native "Open with..." chooser.
  Future<Uint8List> downloadFileBytes(String path) {
    return _client.storage.from(_bucket).download(path);
  }
}