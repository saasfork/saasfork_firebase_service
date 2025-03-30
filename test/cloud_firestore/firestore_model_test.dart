import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saasfork_firebase_service/cloud_firestore/firestore_model.dart';

// Génération des mocks avec Mockito - Avec les types génériques corrects
@GenerateMocks(
  [],
  customMocks: [
    MockSpec<FirebaseFirestore>(as: #MockFirebaseFirestore),
    MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocumentSnapshot),
    MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockQuerySnapshot),
    MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(
      as: #MockQueryDocumentSnapshot,
    ),
    MockSpec<CollectionReference<Map<String, dynamic>>>(
      as: #MockCollectionReference,
    ),
    MockSpec<DocumentReference<Map<String, dynamic>>>(
      as: #MockDocumentReference,
    ),
    MockSpec<Query<Map<String, dynamic>>>(as: #MockQuery),
  ],
)
import 'firestore_model_test.mocks.dart';

// Modèle de test pour les tests
class TestModel extends FirestoreModel<TestModel> {
  String? name;
  int? age;
  String? excludedField;

  TestModel({
    super.id,
    this.name,
    this.age,
    this.excludedField,
    super.firestore,
  });

  @override
  String get collectionName => 'test_collection';

  @override
  Map<String, dynamic> toMap() {
    return {'name': name, 'age': age, 'excludedField': excludedField};
  }

  @override
  TestModel fromMap(Map<String, dynamic> data, {String? id}) {
    return TestModel(
      id: id,
      name: data['name'],
      age: data['age'],
      excludedField: data['excludedField'],
      firestore: firestore,
    );
  }

  @override
  Set<String> get excludeFromSave => {'excludedField'};

  @override
  TestModel createEmptyInstance() {
    return TestModel(firestore: firestore);
  }
}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollectionReference;
  late MockDocumentReference mockDocumentReference;
  late MockDocumentSnapshot mockDocumentSnapshot;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockQueryDocumentSnapshot mockQueryDocumentSnapshot;

  setUp(() {
    // Configuration des mocks
    mockFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference();
    mockDocumentReference = MockDocumentReference();
    mockDocumentSnapshot = MockDocumentSnapshot();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();
    mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

    // Configuration des comportements par défaut
    when(
      mockFirestore.collection('test_collection'),
    ).thenReturn(mockCollectionReference);

    // Configuration du comportement pour data() sur MockQueryDocumentSnapshot
    when(mockQueryDocumentSnapshot.data()).thenReturn({});
  });

  group('FirestoreModel', () {
    group('save', () {
      test('devrait créer un nouveau document quand id est null', () async {
        // Arrange
        final model = TestModel(
          name: 'Test Name',
          age: 30,
          excludedField: 'Ne pas sauvegarder',
          firestore: mockFirestore,
        );

        when(
          mockCollectionReference.add(any),
        ).thenAnswer((_) async => mockDocumentReference);
        when(mockDocumentReference.id).thenReturn('new_doc_id');

        // Act
        await model.save();

        // Assert
        verify(
          mockCollectionReference.add({
            'name': 'Test Name',
            'age': 30,
            // excludedField ne devrait pas être inclus
          }),
        );
        expect(model.id, 'new_doc_id');
      });

      test(
        'devrait mettre à jour un document existant quand id n\'est pas null',
        () async {
          // Arrange
          final model = TestModel(
            id: 'existing_id',
            name: 'Test Name',
            age: 30,
            excludedField: 'Ne pas sauvegarder',
            firestore: mockFirestore,
          );

          when(
            mockCollectionReference.doc('existing_id'),
          ).thenReturn(mockDocumentReference);

          // Act
          await model.save();

          // Assert
          verify(
            mockDocumentReference.set({
              'name': 'Test Name',
              'age': 30,
              // excludedField ne devrait pas être inclus
            }),
          );
        },
      );
    });

    group('saveWithExclusion', () {
      test('devrait exclure les champs additionnels spécifiés', () async {
        // Arrange
        final model = TestModel(
          id: 'existing_id',
          name: 'Test Name',
          age: 30,
          excludedField: 'Ne pas sauvegarder',
          firestore: mockFirestore,
        );

        when(
          mockCollectionReference.doc('existing_id'),
        ).thenReturn(mockDocumentReference);

        // Act
        await model.saveWithExclusion({'age'});

        // Assert
        verify(
          mockDocumentReference.set({
            'name': 'Test Name',
            // age et excludedField ne devraient pas être inclus
          }),
        );
      });
    });

    group('delete', () {
      test('devrait supprimer le document quand id n\'est pas null', () async {
        // Arrange
        final model = TestModel(id: 'doc_to_delete', firestore: mockFirestore);

        when(
          mockCollectionReference.doc('doc_to_delete'),
        ).thenReturn(mockDocumentReference);

        // Act
        await model.delete();

        // Assert
        verify(mockDocumentReference.delete());
      });
    });

    group('findById', () {
      test('devrait retourner le modèle quand le document existe', () async {
        // Arrange
        final model = TestModel(firestore: mockFirestore);
        const docId = 'existing_doc_id';

        when(
          mockCollectionReference.doc(docId),
        ).thenReturn(mockDocumentReference);
        when(
          mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.id).thenReturn(docId);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(
          mockDocumentSnapshot.data(),
        ).thenReturn({'name': 'Found Name', 'age': 25});

        // Act
        final result = await model.findById(docId);

        // Assert
        expect(result, isNotNull);
        expect(result?.id, docId);
        expect(result?.name, 'Found Name');
        expect(result?.age, 25);
      });

      test('devrait retourner null quand le document n\'existe pas', () async {
        // Arrange
        final model = TestModel(firestore: mockFirestore);
        const docId = 'non_existing_doc_id';

        when(
          mockCollectionReference.doc(docId),
        ).thenReturn(mockDocumentReference);
        when(
          mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(false);

        // Act
        final result = await model.findById(docId);

        // Assert
        expect(result, isNull);
      });
    });

    group('findAll', () {
      test('devrait retourner une liste de tous les documents', () async {
        // Arrange
        final model = TestModel(firestore: mockFirestore);
        final mockQueryDocSnap1 = MockQueryDocumentSnapshot();
        final mockQueryDocSnap2 = MockQueryDocumentSnapshot();
        final docs = [mockQueryDocSnap1, mockQueryDocSnap2];

        // Ajout des stubs pour la méthode data()
        when(
          mockQueryDocSnap1.data(),
        ).thenReturn({'name': 'Name 1', 'age': 20});
        when(
          mockQueryDocSnap2.data(),
        ).thenReturn({'name': 'Name 2', 'age': 30});

        when(
          mockCollectionReference.get(),
        ).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(docs);

        when(mockQueryDocSnap1.id).thenReturn('doc1');
        when(mockQueryDocSnap2.id).thenReturn('doc2');

        // Act
        final results = await model.findAll();

        // Assert
        expect(results.length, 2);
        expect(results[0].id, 'doc1');
        expect(results[0].name, 'Name 1');
        expect(results[0].age, 20);
        expect(results[1].id, 'doc2');
        expect(results[1].name, 'Name 2');
        expect(results[1].age, 30);
      });
    });

    group('findWhere', () {
      test('devrait retourner les documents filtrés', () async {
        // Arrange
        final model = TestModel(firestore: mockFirestore);
        final mockQueryDocSnap = MockQueryDocumentSnapshot();
        final docs = [mockQueryDocSnap];

        // Ajout du stub pour la méthode data()
        when(
          mockQueryDocSnap.data(),
        ).thenReturn({'name': 'Specific Name', 'age': 40});

        when(
          mockCollectionReference.where('name', isEqualTo: 'Specific Name'),
        ).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(docs);

        when(mockQueryDocSnap.id).thenReturn('filtered_doc');

        // Act
        final results = await model.findWhere(
          field: 'name',
          isEqualTo: 'Specific Name',
        );

        // Assert
        expect(results.length, 1);
        expect(results[0].id, 'filtered_doc');
        expect(results[0].name, 'Specific Name');
        expect(results[0].age, 40);
      });

      test('devrait limiter les résultats quand limit est spécifié', () async {
        // Arrange
        final model = TestModel(firestore: mockFirestore);
        final mockQueryDocSnap = MockQueryDocumentSnapshot();
        final docs = [mockQueryDocSnap];

        // Ajout des stubs pour la méthode data() et la propriété id
        when(mockQueryDocSnap.data()).thenReturn({'age': 30});
        when(mockQueryDocSnap.id).thenReturn('doc_with_age_30');

        when(
          mockCollectionReference.where('age', isEqualTo: 30),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(docs);

        // Act
        await model.findWhere(field: 'age', isEqualTo: 30, limit: 1);

        // Assert
        verify(mockQuery.limit(1));
      });
    });

    group('exists', () {
      test('devrait retourner true quand le document existe', () async {
        // Arrange
        final model = TestModel(firestore: mockFirestore);
        final mockQueryDocSnap = MockQueryDocumentSnapshot();
        final docs = [mockQueryDocSnap];

        // Ajout des stubs pour la méthode data() et la propriété id
        when(mockQueryDocSnap.data()).thenReturn({'name': 'Existing Name'});
        when(mockQueryDocSnap.id).thenReturn('existing_doc_id');

        when(
          mockCollectionReference.where('name', isEqualTo: 'Existing Name'),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(docs);

        // Act
        final result = await model.exists(
          field: 'name',
          value: 'Existing Name',
        );

        // Assert
        expect(result, true);
      });

      test('devrait retourner false quand le document n\'existe pas', () async {
        // Arrange
        final model = TestModel(firestore: mockFirestore);
        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

        when(
          mockCollectionReference.where('name', isEqualTo: 'Non-Existing Name'),
        ).thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(docs);

        // Act
        final result = await model.exists(
          field: 'name',
          value: 'Non-Existing Name',
        );

        // Assert
        expect(result, false);
      });
    });
  });
}
