import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/database_factory_helper.dart';
import '../data/database/database_helper.dart';

@immutable
class LocalAccount {
  const LocalAccount({
    required this.id,
    required this.identifier,
    required this.onboardingComplete,
  });

  final int id;
  final String identifier;
  final bool onboardingComplete;

  LocalAccount copyWith({bool? onboardingComplete}) => LocalAccount(
    id: id,
    identifier: identifier,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
  );
}

class LocalAuthException implements Exception {
  const LocalAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Accounts are device-local. Passwords are stored as PBKDF2-HMAC-SHA256 hashes.
class LocalAccountRepository {
  static const _databaseName = 'macromate_accounts.db';
  static const _sessionKey = 'macromate_active_local_account';
  static const _iterations = 600000;

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    initDatabaseFactory();
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, _databaseName),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE local_accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            identifier TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL,
            onboarding_complete INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _database!;
  }

  static String normalizeIdentifier(String value) => value.trim().toLowerCase();

  static bool isValidIdentifier(String value) {
    final normalized = normalizeIdentifier(value);
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized) ||
        RegExp(r'^[a-z0-9_.-]{3,32}$').hasMatch(normalized);
  }

  Future<int?> getSavedAccountId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_sessionKey);
  }

  Future<void> _saveSession(int? accountId) async {
    final preferences = await SharedPreferences.getInstance();
    if (accountId == null) {
      await preferences.remove(_sessionKey);
    } else {
      await preferences.setInt(_sessionKey, accountId);
    }
  }

  Future<LocalAccount?> getAccount(int id) async {
    final rows = await (await database).query(
      'local_accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _accountFromRow(rows.first);
  }

  Future<LocalAccount> register(String identifier, String password) async {
    final normalized = normalizeIdentifier(identifier);
    if (!isValidIdentifier(normalized)) {
      throw const LocalAuthException('Enter a valid email or username.');
    }
    if (password.length < 8) {
      throw const LocalAuthException(
        'Use a password with at least 8 characters.',
      );
    }
    final db = await database;
    final existing = await db.query(
      'local_accounts',
      columns: ['id'],
      where: 'identifier = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const LocalAuthException(
        'An account already uses that email or username. Sign in instead.',
      );
    }
    final hash = await _hashPassword(password);
    try {
      final id = await db.insert('local_accounts', {
        'identifier': normalized,
        'password_hash': hash,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      final account = LocalAccount(
        id: id,
        identifier: normalized,
        onboardingComplete: false,
      );
      await _activate(account);
      return account;
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const LocalAuthException(
          'An account already uses that email or username. Sign in instead.',
        );
      }
      rethrow;
    }
  }

  Future<LocalAccount> signIn(String identifier, String password) async {
    final rows = await (await database).query(
      'local_accounts',
      where: 'identifier = ?',
      whereArgs: [normalizeIdentifier(identifier)],
      limit: 1,
    );
    if (rows.isEmpty ||
        !await _verifyPassword(
          password,
          rows.first['password_hash'] as String,
        )) {
      throw const LocalAuthException(
        'Email/username or password is incorrect.',
      );
    }
    final account = _accountFromRow(rows.first);
    await _activate(account);
    return account;
  }

  Future<void> _activate(LocalAccount account) async {
    await DatabaseHelper.instance.switchAccount(account.id);
    await _saveSession(account.id);
  }

  Future<void> signOut() async {
    await _saveSession(null);
    await DatabaseHelper.instance.switchAccount(null);
  }

  Future<LocalAccount> markOnboardingComplete(int id) async {
    final db = await database;
    await db.update(
      'local_accounts',
      {'onboarding_complete': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    final account = await getAccount(id);
    if (account == null) throw const LocalAuthException('Account not found.');
    return account;
  }

  Future<void> changePassword({
    required LocalAccount account,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      throw const LocalAuthException(
        'Use a password with at least 8 characters.',
      );
    }
    final db = await database;
    final rows = await db.query(
      'local_accounts',
      where: 'id = ?',
      whereArgs: [account.id],
      limit: 1,
    );
    if (rows.isEmpty ||
        !await _verifyPassword(
          currentPassword,
          rows.first['password_hash'] as String,
        )) {
      throw const LocalAuthException('Current password is incorrect.');
    }
    await db.update(
      'local_accounts',
      {'password_hash': await _hashPassword(newPassword)},
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount({
    required LocalAccount account,
    required String password,
  }) async {
    final db = await database;
    final rows = await db.query(
      'local_accounts',
      columns: ['password_hash'],
      where: 'id = ?',
      whereArgs: [account.id],
      limit: 1,
    );
    if (rows.isEmpty ||
        !await _verifyPassword(
          password,
          rows.first['password_hash'] as String,
        )) {
      throw const LocalAuthException('Password is incorrect.');
    }
    await signOut();
    await DatabaseHelper.deleteAccountDatabase(account.id);
    await db.delete('local_accounts', where: 'id = ?', whereArgs: [account.id]);
    final preferences = await SharedPreferences.getInstance();
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith('daily_plan_${account.id}_'),
    )) {
      await preferences.remove(key);
    }
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) await _database!.close();
    _database = null;
  }

  static LocalAccount _accountFromRow(Map<String, Object?> row) => LocalAccount(
    id: row['id'] as int,
    identifier: row['identifier'] as String,
    onboardingComplete: row['onboarding_complete'] == 1,
  );

  static Future<String> _hashPassword(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    return compute(_hashPasswordWorker, [
      password,
      base64Url.encode(salt),
      '$_iterations',
    ]);
  }

  static Future<bool> _verifyPassword(String password, String encoded) =>
      compute(_verifyPasswordWorker, [password, encoded]);
}

String _hashPasswordWorker(List<String> input) {
  final iterations = int.parse(input[2]);
  final salt = base64Url.decode(input[1]);
  final bytes = _pbkdf2(utf8.encode(input[0]), salt, iterations);
  return 'pbkdf2-sha256\$$iterations\$'
      '${base64Url.encode(salt)}\$${base64Url.encode(bytes)}';
}

bool _verifyPasswordWorker(List<String> input) {
  final password = input[0];
  final encoded = input[1];
  final parts = encoded.split('\$');
  if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
  final iterations = int.tryParse(parts[1]);
  if (iterations == null || iterations < 100000 || iterations > 2000000) {
    return false;
  }
  try {
    final salt = base64Url.decode(parts[2]);
    final expected = base64Url.decode(parts[3]);
    final actual = _pbkdf2(utf8.encode(password), salt, iterations);
    if (actual.length != expected.length) return false;
    var difference = 0;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual[i] ^ expected[i];
    }
    return difference == 0;
  } catch (_) {
    return false;
  }
}

List<int> _pbkdf2(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final result = List<int>.from(block);
  for (var i = 1; i < iterations; i++) {
    block = hmac.convert(block).bytes;
    for (var j = 0; j < result.length; j++) {
      result[j] ^= block[j];
    }
  }
  return result;
}

class AuthController extends ChangeNotifier {
  AuthController({LocalAccountRepository? repository})
    : _repository = repository ?? LocalAccountRepository();

  final LocalAccountRepository _repository;
  LocalAccount? account;
  bool loading = true;
  String? error;

  bool get isSignedIn => account != null;

  Future<void> initialize() async {
    try {
      final id = await _repository.getSavedAccountId();
      if (id != null) {
        account = await _repository.getAccount(id);
        if (account != null) {
          await DatabaseHelper.instance.switchAccount(account!.id);
        } else {
          await _repository.signOut();
        }
      } else {
        await DatabaseHelper.instance.switchAccount(null);
      }
    } catch (_) {
      error = 'Could not restore the local account. Try signing in again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String identifier, String password) async {
    account = await _repository.register(identifier, password);
    error = null;
    notifyListeners();
  }

  Future<void> signIn(String identifier, String password) async {
    account = await _repository.signIn(identifier, password);
    error = null;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final current = account;
    if (current == null) throw const LocalAuthException('Sign in first.');
    account = await _repository.markOnboardingComplete(current.id);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _repository.signOut();
    account = null;
    error = null;
    notifyListeners();
  }

  Future<void> changePassword(String current, String updated) async {
    final active = account;
    if (active == null) throw const LocalAuthException('Sign in first.');
    await _repository.changePassword(
      account: active,
      currentPassword: current,
      newPassword: updated,
    );
  }

  Future<void> deleteAccount(String password) async {
    final active = account;
    if (active == null) throw const LocalAuthException('Sign in first.');
    await _repository.deleteAccount(account: active, password: password);
    account = null;
    notifyListeners();
  }
}
