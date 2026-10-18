import '../database/database_helper.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  final DatabaseHelper _dbHelper;

  ProfileRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<UserProfile> getProfile() async {
    return await _dbHelper.getUserProfile();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _dbHelper.updateUserProfile(profile);
  }
}
