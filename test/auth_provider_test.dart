import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:saasfork_core/saasfork_core.dart';
import 'package:saasfork_firebase_service/exceptions/auth_exceptions.dart';
import 'package:saasfork_firebase_service/auth_provider.dart';
import 'package:saasfork_firebase_service/models/auth_state_model.dart';
import 'package:saasfork_firebase_service/services/auth_service_interface.dart';
import 'package:saasfork_firebase_service/services/firebase_auth_service.dart';

@GenerateMocks([AuthServiceInterface, FirebaseAuthService])
import 'auth_provider_test.mocks.dart';

void main() {
  late MockAuthServiceInterface mockAuthService;
  late MockFirebaseAuthService mockFirebaseAuthService;
  late StreamController<UserModel?> authStateController;
  late ProviderContainer container;

  setUp(() {
    mockAuthService = MockAuthServiceInterface();
    mockFirebaseAuthService = MockFirebaseAuthService();
    authStateController = StreamController<UserModel?>.broadcast();

    when(
      mockAuthService.authStateChanges(),
    ).thenAnswer((_) => authStateController.stream);

    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => AuthNotifier(auth: mockAuthService)),
      ],
    );
  });

  tearDown(() {
    authStateController.close();
    container.dispose();
  });

  test('build - initializes with idle state', () {
    expect(container.read(authProvider).state, equals(AuthState.idle));
    expect(container.read(authProvider).user, isNull);
  });

  group('login', () {
    test('successful login updates state to authenticated', () async {
      final userModel = UserModel(
        uid: 'test-uid',
        email: 'test@example.com',
        username: 'testuser',
        claims: UserClaims(role: Roles.user),
      );

      when(
        mockAuthService.signInWithEmailAndPassword(
          'test@example.com',
          'password',
        ),
      ).thenAnswer((_) async => userModel);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.login('test@example.com', 'password');

      expect(result.state, equals(AuthState.authenticated));
      expect(result.user, equals(userModel));
      expect(result.errorMessage, isNull);

      verify(
        mockAuthService.signInWithEmailAndPassword(
          'test@example.com',
          'password',
        ),
      ).called(1);
    });

    test('login with invalid credentials updates state to error', () async {
      when(
        mockAuthService.signInWithEmailAndPassword(
          'test@example.com',
          'wrong-password',
        ),
      ).thenThrow(InvalidCredentialsException());

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.login('test@example.com', 'wrong-password');

      expect(result.state, equals(AuthState.error));
      expect(result.user, isNull);

      expect(result.errorMessage, equals('invalid_credentials'));
    });

    test('login with user not found updates state to error', () async {
      when(
        mockAuthService.signInWithEmailAndPassword(
          'nonexistent@example.com',
          'password',
        ),
      ).thenThrow(UserNotFoundException());

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.login(
        'nonexistent@example.com',
        'password',
      );

      expect(result.state, equals(AuthState.error));
      expect(result.user, isNull);

      expect(result.errorMessage, equals('user_not_found'));
    });

    test('login with unexpected error updates state to error', () async {
      when(
        mockAuthService.signInWithEmailAndPassword(
          'test@example.com',
          'password',
        ),
      ).thenThrow(Exception('Unexpected error'));

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.login('test@example.com', 'password');

      expect(result.state, equals(AuthState.error));
      expect(result.user, isNull);

      expect(result.errorMessage, equals('unknown'));
    });
  });

  group('register', () {
    test('successful registration updates state to authenticated', () async {
      final userModel = UserModel(
        uid: 'new-user-uid',
        email: 'new@example.com',
        username: 'newuser',
        claims: UserClaims(role: Roles.user),
      );

      when(
        mockAuthService.createUserWithEmailAndPassword(
          'new@example.com',
          'password',
        ),
      ).thenAnswer((_) async => userModel);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.register('new@example.com', 'password');

      expect(result.state, equals(AuthState.authenticated));
      expect(result.user, equals(userModel));
      expect(result.errorMessage, isNull);
    });

    test('registration with existing email updates state to error', () async {
      when(
        mockAuthService.createUserWithEmailAndPassword(
          'existing@example.com',
          'password',
        ),
      ).thenThrow(EmailAlreadyInUseException());

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.register(
        'existing@example.com',
        'password',
      );

      expect(result.state, equals(AuthState.error));
      expect(result.user, isNull);

      expect(result.errorMessage, equals('email_already_in_use'));
    });

    test('registration with unexpected error updates state to error', () async {
      when(
        mockAuthService.createUserWithEmailAndPassword(
          'new@example.com',
          'password',
        ),
      ).thenThrow(Exception('Unexpected error'));

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.register('new@example.com', 'password');

      expect(result.state, equals(AuthState.error));
      expect(result.user, isNull);

      expect(result.errorMessage, equals('unknown'));
    });
  });

  group('resetPassword', () {
    test('successful password reset returns idle state', () async {
      when(
        mockAuthService.sendPasswordResetEmail(email: 'test@example.com'),
      ).thenAnswer((_) async {
        return;
      });

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.resetPassword('test@example.com');

      expect(result.state, equals(AuthState.idle));
      expect(result.errorMessage, isNull);
    });

    test('password reset for non-existent user returns error state', () async {
      when(
        mockAuthService.sendPasswordResetEmail(
          email: 'nonexistent@example.com',
        ),
      ).thenThrow(UserNotFoundException());

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.resetPassword('nonexistent@example.com');

      expect(result.state, equals(AuthState.error));

      expect(result.errorMessage, equals('user_not_found'));
    });
  });

  group('signOut', () {
    test('successful sign out updates state to unauthenticated', () async {
      when(mockAuthService.signOut()).thenAnswer((_) async {
        return;
      });

      final notifier = container.read(authProvider.notifier);

      authStateController.add(
        UserModel(
          uid: 'test-uid',
          email: 'test@example.com',
          claims: UserClaims(role: Roles.user),
        ),
      );

      await Future.microtask(() {});

      await notifier.signOut();

      expect(
        container.read(authProvider).state,
        equals(AuthState.unauthenticated),
      );
      expect(container.read(authProvider).user, isNull);
      expect(container.read(authProvider).errorMessage, isNull);

      verify(mockAuthService.signOut()).called(1);
    });

    test('sign out with error still tries to update state', () async {
      when(mockAuthService.signOut()).thenThrow(Exception('Sign out error'));

      final notifier = container.read(authProvider.notifier);

      authStateController.add(
        UserModel(
          uid: 'test-uid',
          email: 'test@example.com',
          claims: UserClaims(role: Roles.user),
        ),
      );

      await Future.microtask(() {});

      await notifier.signOut();

      expect(
        container.read(authProvider).state,
        equals(AuthState.authenticated),
      );
    });
  });

  group('updateUserProfile', () {
    setUp(() {
      container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => AuthNotifier(auth: mockFirebaseAuthService),
          ),
        ],
      );

      when(
        mockFirebaseAuthService.authStateChanges(),
      ).thenAnswer((_) => authStateController.stream);
    });

    test('profile update with no user returns error', () async {
      final notifier = container.read(authProvider.notifier);
      final result = await notifier.updateUserProfile(username: 'newUsername');

      expect(result.state, equals(AuthState.error));

      expect(result.errorMessage, equals('unknown'));
    });

    test('profile update with username and email is successful', () async {
      // Set up initial authenticated state
      final initialUser = UserModel(
        uid: 'test-uid',
        email: 'test@example.com',
        username: 'oldUsername',
        claims: UserClaims(role: Roles.user),
      );

      // Setup updated user model
      final updatedUser = UserModel(
        uid: 'test-uid',
        email: 'new@example.com',
        username: 'newUsername',
        claims: UserClaims(role: Roles.user),
      );

      // Set the initial state directly on the notifier (important!)
      final notifier = container.read(authProvider.notifier);
      notifier.state = AuthStateModel(
        state: AuthState.authenticated,
        user: initialUser,
      );

      // Mock updateUserProfile to return updated user
      when(
        mockFirebaseAuthService.updateUserProfile(
          username: 'newUsername',
          email: 'new@example.com',
        ),
      ).thenAnswer((_) async => updatedUser);

      // Call the method with both username and email
      final result = await notifier.updateUserProfile(
        username: 'newUsername',
        email: 'new@example.com',
      );

      // Verify the result is correct
      expect(result.state, equals(AuthState.authenticated));
      expect(result.user, equals(updatedUser));
      expect(result.user?.username, equals('newUsername'));
      expect(result.user?.email, equals('new@example.com'));
      expect(result.errorMessage, isNull);

      // Verify the service was called with correct parameters
      verify(
        mockFirebaseAuthService.updateUserProfile(
          username: 'newUsername',
          email: 'new@example.com',
        ),
      ).called(1);
    });
  });

  group('deleteUserAccount', () {
    test('successful account deletion returns unauthenticated state', () async {
      when(mockAuthService.deleteAccount()).thenAnswer((_) async {
        return;
      });

      final notifier = container.read(authProvider.notifier);
      notifier.state = AuthStateModel(
        state: AuthState.authenticated,
        user: UserModel(
          uid: 'test-uid',
          email: 'test@example.com',
          claims: UserClaims(role: Roles.user),
        ),
      );

      final result = await notifier.deleteUserAccount();

      expect(result.state, equals(AuthState.unauthenticated));
      expect(result.user, isNull);
      expect(result.errorMessage, isNull);

      verify(mockAuthService.deleteAccount()).called(1);
    });

    test('account deletion with no user returns error', () async {
      final notifier = container.read(authProvider.notifier);
      final result = await notifier.deleteUserAccount();

      expect(result.state, equals(AuthState.error));
      expect(result.errorMessage, equals('unknown'));
    });

    test('account deletion requiring recent login returns error', () async {
      when(
        mockAuthService.deleteAccount(),
      ).thenThrow(RecentLoginRequiredException());

      final notifier = container.read(authProvider.notifier);
      notifier.state = AuthStateModel(
        state: AuthState.authenticated,
        user: UserModel(
          uid: 'test-uid',
          email: 'test@example.com',
          claims: UserClaims(role: Roles.user),
        ),
      );

      expect(container.read(authProvider).user?.uid, equals('test-uid'));

      final result = await notifier.deleteUserAccount();

      expect(result.state, equals(AuthState.error));

      expect(result.errorMessage, equals('recent_login_required'));

      verify(mockAuthService.deleteAccount()).called(1);
    });
  });

  group('Provider dependencies', () {
    test('currentUserProvider returns current user from authProvider', () {
      final userModel = UserModel(
        uid: 'test-uid',
        email: 'test@example.com',
        username: 'testuser',
        claims: UserClaims(role: Roles.user),
      );

      // Set authenticated state with user
      container.read(authProvider.notifier).state = AuthStateModel(
        state: AuthState.authenticated,
        user: userModel,
      );

      // Check user provider returns the correct user
      expect(container.read(currentUserProvider), equals(userModel));

      // Set unauthenticated state
      container.read(authProvider.notifier).state = AuthStateModel(
        state: AuthState.unauthenticated,
        user: null,
      );

      // Check user provider returns null when unauthenticated
      expect(container.read(currentUserProvider), isNull);
    });

    test(
      'currentUserIdProvider returns user ID or null based on authentication state',
      () {
        final userModel = UserModel(
          uid: 'test-uid',
          email: 'test@example.com',
          username: 'testuser',
          claims: UserClaims(role: Roles.user),
        );

        // Set authenticated state with user
        container.read(authProvider.notifier).state = AuthStateModel(
          state: AuthState.authenticated,
          user: userModel,
        );

        // Check user ID provider returns the correct ID
        expect(container.read(currentUserIdProvider), equals('test-uid'));

        // Set unauthenticated state
        container.read(authProvider.notifier).state = AuthStateModel(
          state: AuthState.unauthenticated,
          user: null,
        );

        // Check user ID provider returns null when unauthenticated
        expect(container.read(currentUserIdProvider), isNull);
      },
    );
  });
}
