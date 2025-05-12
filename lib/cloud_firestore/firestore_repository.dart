import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saasfork_core/saasfork_core.dart';

/// Interface abstraite pour encapsuler les types Firestore
abstract class FirestoreDocument {
  String get id;
  Map<String, dynamic> get data;
  bool get exists;
}

/// Implémentation de FirestoreDocument basée sur DocumentSnapshot
class _FirestoreDocumentImpl implements FirestoreDocument {
  final DocumentSnapshot<Map<String, dynamic>> _snapshot;
  _FirestoreDocumentImpl(this._snapshot);

  @override
  String get id => _snapshot.id;

  @override
  Map<String, dynamic> get data => _snapshot.data() ?? {};

  @override
  bool get exists => _snapshot.exists;
}

/// Définition d'une relation entre entités
class EntityRelation<T> {
  /// Nom de la collection cible
  final String targetCollection;

  /// Champ dans la collection cible qui fait référence à l'entité parente
  final String foreignKey;

  /// Fonction pour créer une entité à partir d'un document
  final T Function(FirestoreDocument document) fromDocument;

  /// Indique si la relation est à charger automatiquement
  final bool autoLoad;

  /// Constructeur pour définir une relation
  EntityRelation({
    required this.targetCollection,
    required this.foreignKey,
    required this.fromDocument,
    this.autoLoad = false,
  });
}

/// Classe spéciale pour les relations de référence
class _ReferenceRelation<T> extends EntityRelation<T> {
  /// Champ dans l'entité locale qui contient l'ID de l'entité référencée
  final String localKeyField;

  _ReferenceRelation({
    required super.targetCollection,
    required this.localKeyField,
    required super.fromDocument,
    super.autoLoad,
  }) : super(foreignKey: '_invalid_');
}

/// Définition d'une relation par tableau d'IDs
class ArrayRelation<T> {
  /// Nom de la collection cible
  final String targetCollection;

  /// Nom du champ dans l'entité parent qui contient le tableau d'IDs
  final String arrayField;

  /// Fonction pour créer une entité à partir d'un document
  final T Function(FirestoreDocument document) fromDocument;

  /// Indique si la relation est à charger automatiquement
  final bool autoLoad;

  /// Constructeur pour définir une relation de type tableau
  ArrayRelation({
    required this.targetCollection,
    required this.arrayField,
    required this.fromDocument,
    this.autoLoad = false,
  });
}

/// Enum représentant les opérateurs de comparaison pour les requêtes Firestore
enum FirestoreOperator {
  equalTo,
  notEqualTo,
  lessThan,
  lessThanOrEqualTo,
  greaterThan,
  greaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
}

/// Classe représentant une condition de requête pour Firestore
class FirestoreQueryCondition {
  final String field;
  final FirestoreOperator operator;
  final dynamic value;

  FirestoreQueryCondition({
    required this.field,
    required this.operator,
    required this.value,
  });
}

/// Repository générique pour Firestore avec support de relations
abstract class FirestoreRepository<T> {
  /// Instance Firestore
  final FirebaseFirestore firestore;

  /// Nom de la collection
  final String collectionName;

  /// Relations définies pour ce repository
  final Map<String, EntityRelation<dynamic>> _relations = {};

  /// Relations de type tableau définies pour ce repository
  final Map<String, ArrayRelation<dynamic>> _arrayRelations = {};

  /// Constructeur avec injection optionnelle
  FirestoreRepository({
    required this.collectionName,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance {
    // Initialiser les relations lors de la création du repository
    initializeRelations();
  }

  /// Méthode pour initialiser les relations, à surcharger dans les sous-classes
  void initializeRelations() {}

  /// Ajouter une relation
  void addRelation<R>(
    String relationName,
    String targetCollection,
    String foreignKey,
    R Function(FirestoreDocument document) fromDocument, {
    bool autoLoad = false,
  }) {
    _relations[relationName] = EntityRelation<R>(
      targetCollection: targetCollection,
      foreignKey: foreignKey,
      fromDocument: fromDocument,
      autoLoad: autoLoad,
    );
  }

  /// Ajouter une relation de type tableau
  void addArrayRelation<R>(
    String relationName,
    String targetCollection,
    String arrayField,
    R Function(FirestoreDocument document) fromDocument, {
    bool autoLoad = false,
  }) {
    _arrayRelations[relationName] = ArrayRelation<R>(
      targetCollection: targetCollection,
      arrayField: arrayField,
      fromDocument: fromDocument,
      autoLoad: autoLoad,
    );
  }

  /// Ajouter une relation de référence (où cette entité stocke l'ID d'une autre)
  void addReferenceRelation<R>(
    String relationName,
    String targetCollection,
    String localKeyField,
    R Function(FirestoreDocument document) fromDocument, {
    bool autoLoad = false,
  }) {
    // Utiliser une structure spéciale pour identifier ce type de relation
    _relations[relationName] = _ReferenceRelation<R>(
      targetCollection: targetCollection,
      localKeyField: localKeyField,
      fromDocument: fromDocument,
      autoLoad: autoLoad,
    );
  }

  /// Référence à la collection
  CollectionReference<Map<String, dynamic>> get collection =>
      firestore.collection(collectionName);

  /// Créer une entité à partir d'un document
  T fromDocument(FirestoreDocument document);

  /// Méthode interne pour convertir un snapshot en document
  FirestoreDocument _documentFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return _FirestoreDocumentImpl(snapshot);
  }

  /// Convertir une entité en Map pour stockage
  Map<String, dynamic> toMap(T entity);

  /// Assigner un ID à une entité
  T assignId(T entity, String id);

  /// Récupérer l'ID d'une entité
  String? getId(T entity);

  /// Récupérer une entité par son ID
  Future<T?> findById(String id, {bool loadRelations = false}) async {
    try {
      final snapshot = await collection.doc(id).get();
      if (snapshot.exists) {
        final entity = fromDocument(_documentFromSnapshot(snapshot));

        if (loadRelations) {
          return await _loadEntityRelations(entity);
        }

        return entity;
      }
      return null;
    } catch (e) {
      error('Error in findById: $e');
      return null;
    }
  }

  /// Trouver toutes les entités
  Future<List<T>> findAll({bool loadRelations = false}) async {
    try {
      final querySnapshot = await collection.get();
      final entities =
          querySnapshot.docs
              .map((doc) => fromDocument(_documentFromSnapshot(doc)))
              .toList();

      if (loadRelations) {
        return await _loadEntitiesRelations(entities);
      }

      return entities;
    } catch (e) {
      error('Error in findAll: $e');
      return [];
    }
  }

  /// Charger les relations pour une entité
  Future<T> _loadEntityRelations(T entity) async {
    final id = getId(entity);
    if (id == null) return entity;

    // Clone de l'entité pour modification
    var updatedEntity = entity;

    // Relations standard et références
    for (final entry in _relations.entries) {
      final relationName = entry.key;
      final relation = entry.value;

      if (relation.autoLoad) {
        if (relation is _ReferenceRelation) {
          // Charger une relation de référence
          final relatedEntities = await _findReferencedEntities(
            entity,
            relation,
          );
          updatedEntity = await updateEntityWithRelation(
            updatedEntity,
            relationName,
            relatedEntities,
          );
        } else {
          // Relations traditionnelles (many-to-one)
          final relatedEntities = await _findRelatedEntities(id, relation);
          updatedEntity = await updateEntityWithRelation(
            updatedEntity,
            relationName,
            relatedEntities,
          );
        }
      }
    }

    // Relations par tableau d'IDs (code existant inchangé)
    for (final entry in _arrayRelations.entries) {
      final relationName = entry.key;
      final relation = entry.value;

      if (relation.autoLoad || true) {
        final relatedEntities = await _findArrayRelatedEntities(
          entity,
          relation,
        );
        updatedEntity = await updateEntityWithRelation(
          updatedEntity,
          relationName,
          relatedEntities,
        );
      }
    }

    return updatedEntity;
  }

  /// Charger les relations pour une liste d'entités
  Future<List<T>> _loadEntitiesRelations(List<T> entities) async {
    // Optimisation: traiter toutes les entités en parallèle
    return await Future.wait(
      entities.map((entity) => _loadEntityRelations(entity)),
    );
  }

  /// Trouver les entités liées selon une relation
  Future<List<dynamic>> _findRelatedEntities<R>(
    String entityId,
    EntityRelation<R> relation,
  ) async {
    final querySnapshot =
        await firestore
            .collection(relation.targetCollection)
            .where(relation.foreignKey, isEqualTo: entityId)
            .get();

    return querySnapshot.docs
        .map((doc) => relation.fromDocument(_documentFromSnapshot(doc)))
        .toList();
  }

  /// Trouver les entités référencées par une entité
  Future<List<dynamic>> _findReferencedEntities<R>(
    T entity,
    _ReferenceRelation<R> relation,
  ) async {
    try {
      // Extraire l'ID référencé depuis l'entité
      final entityMap = toMap(entity);
      final referencedId = entityMap[relation.localKeyField];

      if (referencedId == null || referencedId.toString().isEmpty) {
        warn('Warning: No valid ID found in field ${relation.localKeyField}');
        return [];
      }

      // Récupérer directement l'entité référencée
      final docSnapshot =
          await firestore
              .collection(relation.targetCollection)
              .doc(referencedId.toString())
              .get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        warn(
          'Warning: Referenced document $referencedId not found in ${relation.targetCollection}',
        );
        return [];
      }

      // Créer l'entité référencée
      final referencedEntity = relation.fromDocument(
        _documentFromSnapshot(docSnapshot),
      );
      return [referencedEntity];
    } catch (e) {
      error('Error in _findReferencedEntities: $e');
      return [];
    }
  }

  /// Nouvelle méthode pour trouver les entités liées par tableau d'IDs
  Future<List<dynamic>> _findArrayRelatedEntities<R>(
    T entity,
    ArrayRelation<R> relation,
  ) async {
    try {
      // Solution alternative: extraire directement les IDs depuis le document Firestore
      final entityId = getId(entity);
      if (entityId == null) return [];

      // Récupérer le document directement pour obtenir les données brutes
      final docSnapshot =
          await firestore.collection(collectionName).doc(entityId).get();
      if (!docSnapshot.exists) return [];

      final data = docSnapshot.data();
      if (data == null) return [];

      // Extraire le tableau d'IDs
      final fieldValue = data[relation.arrayField];
      if (fieldValue == null) return [];

      List<String> idsArray = [];

      if (fieldValue is List) {
        idsArray = fieldValue.map((e) => e.toString()).toList();
      }

      // Continuer comme avant avec le code existant
      if (idsArray.isEmpty) return [];

      const int maxBatchSize = 10;
      final List<dynamic> allResults = [];

      for (int i = 0; i < idsArray.length; i += maxBatchSize) {
        final int end =
            (i + maxBatchSize < idsArray.length)
                ? i + maxBatchSize
                : idsArray.length;
        final currentBatch = idsArray.sublist(i, end);

        final querySnapshot =
            await firestore
                .collection(relation.targetCollection)
                .where(FieldPath.documentId, whereIn: currentBatch)
                .get();

        final batchResults =
            querySnapshot.docs
                .map((doc) => relation.fromDocument(_documentFromSnapshot(doc)))
                .toList();

        allResults.addAll(batchResults);
      }

      return allResults;
    } catch (e) {
      error('Error in _findArrayRelatedEntities: $e');
      return [];
    }
  }

  /// Mettre à jour une entité avec ses relations chargées
  /// Cette méthode doit être surchargée dans les sous-classes
  Future<T> updateEntityWithRelation(
    T entity,
    String relationName,
    List<dynamic> relatedEntities,
  ) async {
    // Par défaut, cette méthode ne fait rien
    // Elle doit être surchargée dans les sous-classes pour chaque type d'entité
    return entity;
  }

  /// Sauvegarder une entité (créer ou mettre à jour)
  Future<T> save(T entity) async {
    try {
      final id = getId(entity);
      final data = toMap(entity);

      if (id == null || id.isEmpty) {
        // Création
        final docRef = await collection.add(data);
        return assignId(entity, docRef.id);
      } else {
        // Mise à jour
        await collection.doc(id).set(data, SetOptions(merge: true));
        return entity;
      }
    } catch (e) {
      error('Error in save: $e');
      rethrow;
    }
  }

  /// Sauvegarder une entité avec ses relations
  Future<T> saveWithRelations(
    T entity,
    Map<String, List<dynamic>> relations,
  ) async {
    try {
      // Sauvegarder d'abord l'entité principale
      final savedEntity = await save(entity);
      final entityId = getId(savedEntity);

      if (entityId == null) {
        throw Exception("Entity ID is null after save");
      }

      // Pour chaque relation à sauvegarder
      for (final entry in relations.entries) {
        final relationName = entry.key;
        final relatedEntities = entry.value;

        // Vérifier si la relation est définie
        if (!_relations.containsKey(relationName)) {
          warn("Warning: Relation '$relationName' is not defined");
          continue;
        }

        final relation = _relations[relationName]!;

        // Sauvegarder les entités liées en batch
        await runBatch((batch) {
          for (final relatedEntity in relatedEntities) {
            // Récupérer l'ID et les données de l'entité liée
            // Nous devons adapter cette partie pour être générique
            final Map<String, dynamic> relatedData = _getRelatedEntityData(
              relatedEntity,
              entityId,
              relation.foreignKey,
            );

            final String? relatedId = _getRelatedEntityId(relatedEntity);

            if (relatedId == null || relatedId.isEmpty) {
              // Nouvelle entité liée
              final relatedDocRef =
                  firestore.collection(relation.targetCollection).doc();
              batch.set(relatedDocRef, relatedData);
            } else {
              // Mise à jour d'une entité liée existante
              batch.set(
                firestore.collection(relation.targetCollection).doc(relatedId),
                relatedData,
                SetOptions(merge: true),
              );
            }
          }
        });
      }

      // Recharger l'entité avec ses relations
      return await findById(entityId, loadRelations: true) ?? savedEntity;
    } catch (e) {
      error('Error in saveWithRelations: $e');
      rethrow;
    }
  }

  /// Récupérer les données d'une entité liée pour la sauvegarde
  /// Cette méthode doit être surchargée dans les sous-classes
  Map<String, dynamic> _getRelatedEntityData(
    dynamic relatedEntity,
    String parentId,
    String foreignKey,
  ) {
    // Cette méthode doit être implémentée dans les sous-classes
    // pour chaque type d'entité liée
    throw UnimplementedError();
  }

  /// Récupérer l'ID d'une entité liée
  /// Cette méthode doit être surchargée dans les sous-classes
  String? _getRelatedEntityId(dynamic relatedEntity) {
    // Cette méthode doit être implémentée dans les sous-classes
    // pour chaque type d'entité liée
    throw UnimplementedError();
  }

  /// Supprimer une entité
  Future<bool> delete(T entity) async {
    try {
      final id = getId(entity);
      if (id == null || id.isEmpty) return false;

      await collection.doc(id).delete();
      return true;
    } catch (e) {
      error('Error in delete: $e');
      return false;
    }
  }

  /// Supprimer par ID
  Future<bool> deleteById(String id) async {
    try {
      await collection.doc(id).delete();
      return true;
    } catch (e) {
      error('Error in deleteById: $e');
      return false;
    }
  }

  /// Écouter un document
  Stream<T?> listenDocument(String id) {
    return collection.doc(id).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return fromDocument(_documentFromSnapshot(snapshot));
      }
      return null;
    });
  }

  /// Requête avec filtres
  Future<List<T>> query({
    Map<String, dynamic>? equals,
    List<FirestoreQueryCondition>? conditions,
    String? orderBy,
    bool descending = false,
    int? limit,
    bool loadRelations = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection;

      // Appliquer les filtres d'égalité
      if (equals != null) {
        equals.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }

      // Appliquer les conditions avancées
      if (conditions != null) {
        for (final condition in conditions) {
          query = _applyCondition(query, condition);
        }
      }

      // Appliquer le tri
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Appliquer la limite
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      final entities =
          querySnapshot.docs
              .map((doc) => fromDocument(_documentFromSnapshot(doc)))
              .toList();

      if (loadRelations) {
        return await _loadEntitiesRelations(
          entities,
        ); // Charger les relations si demandé
      }

      return entities;
    } catch (e) {
      error('Error in query: $e');
      return [];
    }
  }

  /// Applique une condition à une requête
  Query<Map<String, dynamic>> _applyCondition(
    Query<Map<String, dynamic>> query,
    FirestoreQueryCondition condition,
  ) {
    switch (condition.operator) {
      case FirestoreOperator.equalTo:
        return query.where(condition.field, isEqualTo: condition.value);
      case FirestoreOperator.notEqualTo:
        return query.where(condition.field, isNotEqualTo: condition.value);
      case FirestoreOperator.lessThan:
        return query.where(condition.field, isLessThan: condition.value);
      case FirestoreOperator.lessThanOrEqualTo:
        return query.where(
          condition.field,
          isLessThanOrEqualTo: condition.value,
        );
      case FirestoreOperator.greaterThan:
        return query.where(condition.field, isGreaterThan: condition.value);
      case FirestoreOperator.greaterThanOrEqualTo:
        return query.where(
          condition.field,
          isGreaterThanOrEqualTo: condition.value,
        );
      case FirestoreOperator.arrayContains:
        return query.where(condition.field, arrayContains: condition.value);
      case FirestoreOperator.arrayContainsAny:
        return query.where(condition.field, arrayContainsAny: condition.value);
      case FirestoreOperator.whereIn:
        return query.where(condition.field, whereIn: condition.value);
      case FirestoreOperator.whereNotIn:
        return query.where(condition.field, whereNotIn: condition.value);
    }
  }

  /// Écouter une requête
  Stream<List<T>> listenQuery({
    Map<String, dynamic>? equals,
    List<FirestoreQueryCondition>? conditions,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = collection;

    // Appliquer les filtres d'égalité
    if (equals != null) {
      equals.forEach((field, value) {
        query = query.where(field, isEqualTo: value);
      });
    }

    // Appliquer les conditions avancées
    if (conditions != null) {
      for (final condition in conditions) {
        query = _applyCondition(query, condition);
      }
    }

    // Appliquer le tri
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Appliquer la limite
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => fromDocument(_documentFromSnapshot(doc)))
              .toList(),
    );
  }

  /// Méthode générique pour rechercher des documents avec un filtre d'égalité
  Future<List<T>> findWhere({
    required String field,
    required dynamic isEqualTo,
    int? limit,
    bool loadRelations = false,
  }) async {
    try {
      var query = collection.where(field, isEqualTo: isEqualTo);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      final entities =
          querySnapshot.docs
              .map((doc) => fromDocument(_documentFromSnapshot(doc)))
              .toList();

      if (loadRelations) {
        return await _loadEntitiesRelations(
          entities,
        ); // Charger les relations si demandé
      }

      return entities;
    } catch (e) {
      error('Error in findWhere: $e');
      return [];
    }
  }

  /// Transaction avec plusieurs opérations
  Future<void> runTransaction(
    Future<void> Function(Transaction) actions,
  ) async {
    await firestore.runTransaction((transaction) async {
      await actions(transaction);
    });
  }

  /// Opérations par lots
  Future<void> runBatch(void Function(WriteBatch batch) actions) async {
    final batch = firestore.batch();
    actions(batch);
    await batch.commit();
  }
}
