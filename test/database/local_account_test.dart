import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/core/constants/app_constants.dart';
import 'package:macromate_india/data/database/database_helper.dart';
import 'package:macromate_india/data/models/food_item.dart';
import 'package:macromate_india/data/models/meal_entry.dart';
import 'package:macromate_india/data/models/shopping_item.dart';
import 'package:macromate_india/services/auth_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late LocalAccountRepository repository;
  final helper = DatabaseHelper.instance;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await helper.switchAccount(null);
    await helper.close();
    final root = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(root, 'macromate_accounts.db'));
    await DatabaseHelper.deleteAccountDatabase(1);
    await DatabaseHelper.deleteAccountDatabase(2);
    repository = LocalAccountRepository();
  });

  tearDown(() async {
    await repository.close();
    await helper.switchAccount(null);
  });

  test(
    'stores a password hash and restores the active local session',
    () async {
      final account = await repository.register(
        'Macro.Tester',
        'strong-pass-1',
      );
      expect(account.id, 1);
      expect(await repository.getSavedAccountId(), account.id);

      final rows = await (await repository.database).query('local_accounts');
      final storedHash = rows.single['password_hash'] as String;
      expect(storedHash, startsWith('pbkdf2-sha256\$600000\$'));
      expect(storedHash, isNot('strong-pass-1'));

      await repository.signOut();
      final signedIn = await repository.signIn('macro.tester', 'strong-pass-1');
      expect(signedIn.id, account.id);
      expect(await repository.getSavedAccountId(), account.id);
    },
  );

  test('account switches open isolated database files', () async {
    final first = await repository.register(
      'first@test.example',
      'password-one',
    );
    final firstDbFoods = await helper.getAllFoods();
    final customFood = FoodItem(
      name: 'Private account food',
      category: AppConstants.catOther,
      dietaryClassification: AppConstants.dietVeg,
      caloriesPer100: 90,
      proteinPer100: 4,
      carbsPer100: 12,
      fatPer100: 2,
      measurementUnit: AppConstants.unitGrams,
      preparationBasis: AppConstants.prepRaw,
      estimatedUnitPrice: 50,
      priceQuantityBasis: 500,
      isCustom: true,
    );
    await helper.insertFood(customFood);
    final today = DateTime.now();
    await helper.insertMealEntry(
      MealEntry.fromFoodItem(
        food: customFood,
        entryDate: today,
        mealType: AppConstants.mealLunch,
        quantity: 100,
      ),
    );
    await helper.insertShoppingItem(
      ShoppingItem(name: 'Private rice list', quantity: 500, unit: 'g'),
    );
    final profile = await helper.getUserProfile();
    await helper.updateUserProfile(
      profile.copyWith(displayName: 'First account'),
    );
    expect(firstDbFoods, isNotEmpty);

    final second = await repository.register(
      'second@test.example',
      'password-two',
    );
    expect(second.id, isNot(first.id));
    expect(
      (await helper.getAllFoods()).any((food) => food.name == customFood.name),
      isFalse,
    );
    expect((await helper.getMealEntriesForDate(today)), isEmpty);
    expect((await helper.getShoppingItems()), isEmpty);
    expect((await helper.getUserProfile()).displayName, isNot('First account'));

    await repository.signIn(first.identifier, 'password-one');
    expect(
      (await helper.getAllFoods()).any((food) => food.name == customFood.name),
      isTrue,
    );
    expect((await helper.getMealEntriesForDate(today)), hasLength(1));
    expect((await helper.getShoppingItems()).single.name, 'Private rice list');
    expect((await helper.getUserProfile()).displayName, 'First account');
  });

  test('rejects weak passwords and invalid account identifiers', () async {
    expect(
      repository.register('ab', 'short'),
      throwsA(isA<LocalAuthException>()),
    );
    expect(
      repository.register('valid.user', 'short'),
      throwsA(isA<LocalAuthException>()),
    );
  });

  test(
    'changes a password and deletes only the verified local account',
    () async {
      final account = await repository.register(
        'owner@test.example',
        'password-old',
      );
      await helper.getAllFoods();
      await repository.changePassword(
        account: account,
        currentPassword: 'password-old',
        newPassword: 'password-new',
      );
      await repository.signOut();
      await expectLater(
        repository.signIn('owner@test.example', 'password-old'),
        throwsA(isA<LocalAuthException>()),
      );
      await repository.signIn('owner@test.example', 'password-new');
      final owner = (await repository.getAccount(account.id))!;
      await repository.deleteAccount(account: owner, password: 'password-new');

      expect(await repository.getAccount(account.id), isNull);
      expect(await repository.getSavedAccountId(), isNull);
    },
  );
}
