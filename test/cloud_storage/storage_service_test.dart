import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:saasfork_firebase_service/cloud_storage/storage_service.dart';

import 'storage_service_test.mocks.dart';

// Générer les mocks pour FirebaseStorage et classes associées
@GenerateMocks([FirebaseStorage, Reference, TaskSnapshot, UploadTask])
void main() {
  late MockFirebaseStorage mockStorage;
  late MockReference mockStorageRef;
  late MockTaskSnapshot mockTaskSnapshot;
  late MockUploadTask mockUploadTask;
  late SFStorageService storageService;

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockStorageRef = MockReference();
    mockTaskSnapshot = MockTaskSnapshot();
    mockUploadTask = MockUploadTask();
    storageService = SFStorageService(storage: mockStorage);

    // Configuration des mocks - utiliser thenAnswer pour les Futures
    when(mockStorage.ref(any)).thenAnswer((_) => mockStorageRef);
    when(mockStorageRef.putFile(any, any)).thenAnswer((_) => mockUploadTask);
    when(mockStorageRef.putData(any, any)).thenAnswer((_) => mockUploadTask);
    when(
      mockStorageRef.getDownloadURL(),
    ).thenAnswer((_) async => 'https://example.com/download-url');
    when(mockUploadTask.snapshot).thenAnswer((_) => mockTaskSnapshot);
    when(mockTaskSnapshot.ref).thenAnswer((_) => mockStorageRef);
    when(mockStorage.refFromURL(any)).thenAnswer((_) => mockStorageRef);

    // Ajouter un stub pour la méthode then de UploadTask
    // Pour simuler le comportement de Future.then
    when(mockUploadTask.then(any, onError: anyNamed('onError'))).thenAnswer((
      invocation,
    ) {
      final callback =
          invocation.positionalArguments[0] as Function(TaskSnapshot);
      return Future.value(callback(mockTaskSnapshot));
    });
  });

  group('SFStorageService', () {
    group('uploadXFile', () {
      test(
        'should upload a file and return its download URL on mobile/desktop',
        () async {
          // Créer un fichier temporaire pour les tests non-web
          final tempDir = Directory.systemTemp;
          final testFilePath = '${tempDir.path}/test_image.jpg';
          final testFile = File(testFilePath)..createSync();
          testFile.writeAsBytesSync(Uint8List.fromList([1, 2, 3]));

          final xFile = XFile(testFilePath);

          // Test pour les plateformes non-web
          debugDefaultTargetPlatformOverride = TargetPlatform.android;

          final result = await storageService.uploadXFile(
            file: xFile,
            folder: 'images',
            userId: 'user123',
            metadata: {'owner': 'test-user'},
          );

          // Vérifier que les méthodes attendues ont été appelées
          verify(
            mockStorage.ref(argThat(contains('uploads/users/user123/images/'))),
          ).called(1);
          verify(mockStorageRef.putFile(any, any)).called(1);
          verify(mockStorageRef.getDownloadURL()).called(1);

          // Vérifier le résultat
          expect(result, 'https://example.com/download-url');

          // Nettoyage
          testFile.deleteSync();
          debugDefaultTargetPlatformOverride = null;
        },
      );

      test('should use custom filename if provided', () async {
        final tempDir = Directory.systemTemp;
        final testFilePath = '${tempDir.path}/test_image.jpg';
        final testFile = File(testFilePath)..createSync();
        testFile.writeAsBytesSync(Uint8List.fromList([1, 2, 3]));

        final xFile = XFile(testFilePath);
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        await storageService.uploadXFile(
          file: xFile,
          customFileName: 'custom_filename.jpg',
        );

        verify(
          mockStorage.ref(argThat(contains('custom_filename.jpg'))),
        ).called(1);

        testFile.deleteSync();
        debugDefaultTargetPlatformOverride = null;
      });
    });

    group('uploadData', () {
      test('should upload data and return download URL', () async {
        final testData = Uint8List.fromList([1, 2, 3, 4]);

        final result = await storageService.uploadData(
          data: testData,
          fileName: 'test_file.pdf',
          contentType: 'application/pdf',
          folder: 'documents',
        );

        verify(
          mockStorage.ref(argThat(contains('uploads/documents/test_file.pdf'))),
        ).called(1);
        verify(mockStorageRef.putData(testData, any)).called(1);
        expect(result, 'https://example.com/download-url');
      });
    });

    group('deleteFile', () {
      test('should delete file by URL', () async {
        when(mockStorageRef.delete()).thenAnswer((_) async => {});

        await storageService.deleteFile('https://example.com/file.jpg');

        verify(
          mockStorage.refFromURL('https://example.com/file.jpg'),
        ).called(1);
        verify(mockStorageRef.delete()).called(1);
      });

      test('should rethrow exception when delete fails', () async {
        when(mockStorageRef.delete()).thenThrow(Exception('Delete failed'));

        expect(
          () => storageService.deleteFile('https://example.com/file.jpg'),
          throwsException,
        );
      });
    });

    group('getSignedUrl', () {
      test('should return a signed URL for a file', () async {
        final result = await storageService.getSignedUrl(
          'https://example.com/file.jpg',
          expirationDuration: const Duration(hours: 2),
        );

        verify(
          mockStorage.refFromURL('https://example.com/file.jpg'),
        ).called(1);
        verify(mockStorageRef.getDownloadURL()).called(1);
        expect(result, 'https://example.com/download-url');
      });
    });

    group('Storage path construction', () {
      test('should build storage path correctly with all parameters', () async {
        // Test la construction du chemin indirectement via uploadData
        await storageService.uploadData(
          data: Uint8List.fromList([1, 2, 3]),
          fileName: 'file.jpg',
          contentType: 'image/jpeg',
          folder: 'images',
          userId: 'user123',
        );

        verify(
          mockStorage.ref('uploads/users/user123/images/file.jpg'),
        ).called(1);
      });

      test('should build storage path without userId', () async {
        await storageService.uploadData(
          data: Uint8List.fromList([1, 2, 3]),
          fileName: 'file.jpg',
          contentType: 'image/jpeg',
          folder: 'images',
        );

        verify(mockStorage.ref('uploads/images/file.jpg')).called(1);
      });

      test('should build storage path without folder', () async {
        await storageService.uploadData(
          data: Uint8List.fromList([1, 2, 3]),
          fileName: 'file.jpg',
          contentType: 'image/jpeg',
          userId: 'user123',
        );

        verify(mockStorage.ref('uploads/users/user123/file.jpg')).called(1);
      });

      test('should build storage path with only filename', () async {
        await storageService.uploadData(
          data: Uint8List.fromList([1, 2, 3]),
          fileName: 'file.jpg',
          contentType: 'image/jpeg',
        );

        verify(mockStorage.ref('uploads/file.jpg')).called(1);
      });
    });
  });
}
