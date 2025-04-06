import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:saasfork_firebase_service/cloud_firestore/firestore_repository.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  Query,
  WriteBatch,
  Transaction,
  QueryDocumentSnapshot,
])
import 'firestore_repository_test.mocks.dart';

class TestModel {
  final String? id;
  final String name;
  final int age;
  final String? relatedId;
  final List<String>? relatedIds;
  final List<TestRelatedModel>? relatedEntities;
  final TestRelatedModel? singleRelatedEntity;

  TestModel({
    this.id,
    required this.name,
    required this.age,
    this.relatedId,
    this.relatedIds,
    this.relatedEntities,
    this.singleRelatedEntity,
  });

  TestModel copyWith({
    String? id,
    String? name,
    int? age,
    String? relatedId,
    List<String>? relatedIds,
    List<TestRelatedModel>? relatedEntities,
    TestRelatedModel? singleRelatedEntity,
  }) {
    return TestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      relatedId: relatedId ?? this.relatedId,
      relatedIds: relatedIds ?? this.relatedIds,
      relatedEntities: relatedEntities ?? this.relatedEntities,
      singleRelatedEntity: singleRelatedEntity ?? this.singleRelatedEntity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      if (relatedId != null) 'relatedId': relatedId,
      if (relatedIds != null) 'relatedIds': relatedIds,
    };
  }
}

class TestRelatedModel {
  final String? id;
  final String title;
  final String? parentId;

  TestRelatedModel({this.id, required this.title, this.parentId});

  Map<String, dynamic> toMap() {
    return {'title': title, if (parentId != null) 'parentId': parentId};
  }
}

class TestRepository extends FirestoreRepository<TestModel> {
  TestRepository({super.firestore}) : super(collectionName: 'tests');

  @override
  void initializeRelations() {
    addRelation<TestRelatedModel>(
      'relatedEntities',
      'related',
      'parentId',
      (doc) => TestRelatedModel(
        id: doc.id,
        title: doc.data['title'],
        parentId: doc.data['parentId'],
      ),
      autoLoad: true,
    );

    addReferenceRelation<TestRelatedModel>(
      'singleRelatedEntity',
      'related',
      'relatedId',
      (doc) => TestRelatedModel(id: doc.id, title: doc.data['title']),
      autoLoad: true,
    );

    addArrayRelation<TestRelatedModel>(
      'arrayRelatedEntities',
      'related',
      'relatedIds',
      (doc) => TestRelatedModel(id: doc.id, title: doc.data['title']),
      autoLoad: true,
    );
  }

  @override
  TestModel fromDocument(FirestoreDocument document) {
    return TestModel(
      id: document.id,
      name: document.data['name'] ?? '',
      age: document.data['age'] ?? 0,
      relatedId: document.data['relatedId'],
      relatedIds:
          document.data['relatedIds'] != null
              ? List<String>.from(document.data['relatedIds'])
              : null,
    );
  }

  @override
  Map<String, dynamic> toMap(TestModel entity) {
    return entity.toMap();
  }

  @override
  TestModel assignId(TestModel entity, String id) {
    return entity.copyWith(id: id);
  }

  @override
  String? getId(TestModel entity) {
    return entity.id;
  }

  @override
  Future<TestModel> updateEntityWithRelation(
    TestModel entity,
    String relationName,
    List<dynamic> relatedEntities,
  ) async {
    if (relationName == 'relatedEntities') {
      return entity.copyWith(
        relatedEntities: List<TestRelatedModel>.from(relatedEntities),
      );
    } else if (relationName == 'singleRelatedEntity' &&
        relatedEntities.isNotEmpty) {
      return entity.copyWith(
        singleRelatedEntity: relatedEntities.first as TestRelatedModel,
      );
    }
    return entity;
  }
}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late TestRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference<Map<String, dynamic>>();
    mockDocRef = MockDocumentReference<Map<String, dynamic>>();

    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocRef);

    repository = TestRepository(firestore: mockFirestore);
  });

  group('FirestoreRepository', () {
    test('findById should return null when document does not exist', () async {
      final mockSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockSnapshot.exists).thenReturn(false);
      when(mockSnapshot.id).thenReturn('test-id');
      when(mockSnapshot.data()).thenReturn(null);
      when(mockDocRef.get()).thenAnswer((_) async => mockSnapshot);

      final result = await repository.findById('test-id');

      expect(result, isNull);
      verify(mockFirestore.collection('tests')).called(1);
      verify(mockCollection.doc('test-id')).called(1);
      verify(mockDocRef.get()).called(1);
    });

    test('findById should return entity when document exists', () async {
      final mockSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.id).thenReturn('test-id');
      when(mockSnapshot.data()).thenReturn({'name': 'Test Name', 'age': 30});
      when(mockDocRef.get()).thenAnswer((_) async => mockSnapshot);

      final result = await repository.findById('test-id');

      expect(result, isNotNull);
      expect(result?.id, equals('test-id'));
      expect(result?.name, equals('Test Name'));
      expect(result?.age, equals(30));
      verify(mockFirestore.collection('tests')).called(1);
      verify(mockCollection.doc('test-id')).called(1);
      verify(mockDocRef.get()).called(1);
    });

    test('findAll should return empty list when collection is empty', () async {
      final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      final result = await repository.findAll();

      expect(result, isEmpty);
      verify(mockFirestore.collection('tests')).called(1);
      verify(mockCollection.get()).called(1);
    });

    test(
      'findAll should return list of entities when collection has documents',
      () async {
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(mockDoc1.id).thenReturn('id-1');
        when(mockDoc1.data()).thenReturn({'name': 'Name 1', 'age': 25});
        when(mockDoc1.exists).thenReturn(true);

        when(mockDoc2.id).thenReturn('id-2');
        when(mockDoc2.data()).thenReturn({'name': 'Name 2', 'age': 30});
        when(mockDoc2.exists).thenReturn(true);

        when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        final result = await repository.findAll();

        expect(result, hasLength(2));
        expect(result[0].id, equals('id-1'));
        expect(result[0].name, equals('Name 1'));
        expect(result[0].age, equals(25));
        expect(result[1].id, equals('id-2'));
        expect(result[1].name, equals('Name 2'));
        expect(result[1].age, equals(30));
        verify(mockFirestore.collection('tests')).called(1);
        verify(mockCollection.get()).called(1);
      },
    );

    test('save should create new document if entity has no ID', () async {
      final entity = TestModel(name: 'New Entity', age: 35);
      when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);
      when(mockDocRef.id).thenReturn('new-id');

      final result = await repository.save(entity);

      expect(result.id, equals('new-id'));
      expect(result.name, equals('New Entity'));
      expect(result.age, equals(35));
      verify(mockFirestore.collection('tests')).called(1);
      verify(mockCollection.add({'name': 'New Entity', 'age': 35})).called(1);
    });

    test('save should update document if entity has ID', () async {
      final entity = TestModel(
        id: 'existing-id',
        name: 'Updated Entity',
        age: 40,
      );

      final result = await repository.save(entity);

      expect(result.id, equals('existing-id'));
      verify(mockFirestore.collection('tests')).called(1);
      verify(mockCollection.doc('existing-id')).called(1);
      verify(
        mockDocRef.set({'name': 'Updated Entity', 'age': 40}, any),
      ).called(1);
    });

    test('delete should return true when successfully deleted', () async {
      final entity = TestModel(id: 'to-delete-id', name: 'Delete Me', age: 45);
      when(mockDocRef.delete()).thenAnswer((_) async => {});

      final result = await repository.delete(entity);

      expect(result, isTrue);
      verify(mockFirestore.collection('tests')).called(1);
      verify(mockCollection.doc('to-delete-id')).called(1);
      verify(mockDocRef.delete()).called(1);
    });

    test('findWhere should return entities that match criteria', () async {
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockCollection.where('age', isEqualTo: 30)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      when(mockDoc.id).thenReturn('match-id');
      when(mockDoc.data()).thenReturn({'name': 'Matched Entity', 'age': 30});
      when(mockDoc.exists).thenReturn(true);

      when(mockQuerySnapshot.docs).thenReturn([mockDoc]);

      final result = await repository.findWhere(field: 'age', isEqualTo: 30);

      expect(result, hasLength(1));
      expect(result[0].id, equals('match-id'));
      expect(result[0].name, equals('Matched Entity'));
      expect(result[0].age, equals(30));
      verify(mockFirestore.collection('tests')).called(1);
      verify(mockCollection.where('age', isEqualTo: 30)).called(1);
      verify(mockQuery.get()).called(1);
    });

    test('findWhere with limit should apply the limit', () async {
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockLimitedQuery = MockQuery<Map<String, dynamic>>();
      final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockCollection.where('age', isEqualTo: 30)).thenReturn(mockQuery);
      when(mockQuery.limit(1)).thenReturn(mockLimitedQuery);
      when(mockLimitedQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);

      await repository.findWhere(field: 'age', isEqualTo: 30, limit: 1);

      verify(mockFirestore.collection('tests')).called(1);
      verify(mockCollection.where('age', isEqualTo: 30)).called(1);
      verify(mockQuery.limit(1)).called(1);
      verify(mockLimitedQuery.get()).called(1);
    });

    test('runBatch should create a batch and commit it', () async {
      final mockBatch = MockWriteBatch();
      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockBatch.commit()).thenAnswer((_) async => {});

      await repository.runBatch((batch) {});

      verify(mockFirestore.batch()).called(1);
      verify(mockBatch.commit()).called(1);
    });
  });
}
