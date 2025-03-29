import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle générique pour les entités stockées dans Firestore
/// T représente le type concret de l'entité
abstract class FirestoreModel<T extends FirestoreModel<T>> {
  String? id;

  /// Instance Firestore injectée
  final FirebaseFirestore firestore;

  /// Constructeur avec paramètre d'injection
  FirestoreModel({this.id, FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection associée au modèle (à override dans les sous-classes)
  String get collectionName;

  /// Convertir en Map (à override)
  Map<String, dynamic> toMap();

  /// Champs à exclure lors de la sauvegarde
  Set<String> get excludeFromSave => {};

  /// Hydrater à partir d'un Map (à override)
  T fromMap(Map<String, dynamic> data, {String? id});

  /// Crée une instance similaire avec la même instance Firestore (pour usage interne)
  T createEmptyInstance();

  /// Méthode finale pour assurer l'implémentation correcte
  T fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return fromMap(data, id: doc.id);
  }

  /// Obtenir une copie filtrée de la map pour la sauvegarde
  Map<String, dynamic> _getFilteredMap() {
    // Créer une copie de la map pour ne pas modifier l'original
    final map = Map<String, dynamic>.from(toMap());

    // Supprimer les champs à exclure
    for (final field in excludeFromSave) {
      map.remove(field);
    }

    // Important: Ajouter des logs pour le débogage
    print('Saving to collection: $collectionName');
    print('Excluded fields: $excludeFromSave');
    print('Filtered data to save: $map');

    return map;
  }

  /// Sauvegarder ou mettre à jour
  Future<void> save() async {
    // Utiliser la map filtrée au lieu de toMap() directement
    final filteredMap = _getFilteredMap();
    final collection = firestore.collection(collectionName);

    if (id == null) {
      final docRef = await collection.add(filteredMap);
      id = docRef.id;
      print('Saved new document with ID: $id');
    } else {
      await collection.doc(id).set(filteredMap);
      print('Updated document with ID: $id');
    }
  }

  /// Sauvegarder avec des exclusions supplémentaires
  Future<void> saveWithExclusion(Set<String> additionalExcludeFields) async {
    // Créer une copie de la map pour ne pas modifier l'original
    final map = Map<String, dynamic>.from(toMap());

    // Supprimer les champs à exclure par défaut
    for (final field in excludeFromSave) {
      map.remove(field);
    }

    // Supprimer les champs à exclure spécifiques à cet appel
    for (final field in additionalExcludeFields) {
      map.remove(field);
    }

    // Logs pour le débogage
    print('Saving to collection: $collectionName with additional exclusions');
    print('Default excluded fields: $excludeFromSave');
    print('Additional excluded fields: $additionalExcludeFields');
    print('Filtered data to save: $map');

    final collection = firestore.collection(collectionName);

    if (id == null) {
      final docRef = await collection.add(map);
      id = docRef.id;
      print('Saved new document with ID: $id');
    } else {
      await collection.doc(id).set(map);
      print('Updated document with ID: $id');
    }
  }

  /// Supprimer
  Future<void> delete() async {
    if (id != null) {
      await firestore.collection(collectionName).doc(id).delete();
    }
  }

  /// Trouver un document par ID
  Future<T?> findById(String documentId) async {
    final doc =
        await firestore.collection(collectionName).doc(documentId).get();
    if (doc.exists) {
      return fromDocumentSnapshot(doc);
    }
    return null;
  }

  /// Récupérer tous les documents
  Future<List<T>> findAll() async {
    final snapshot = await firestore.collection(collectionName).get();
    return snapshot.docs.map((doc) => fromDocumentSnapshot(doc)).toList();
  }

  /// Trouver des documents par une requête
  Future<List<T>> findWhere({
    required String field,
    required dynamic isEqualTo,
    int? limit,
  }) async {
    var query = firestore
        .collection(collectionName)
        .where(field, isEqualTo: isEqualTo);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => fromDocumentSnapshot(doc)).toList();
  }

  /// Vérifier si un document existe avec une valeur spécifique
  Future<bool> exists({required String field, required dynamic value}) async {
    final snapshot =
        await firestore
            .collection(collectionName)
            .where(field, isEqualTo: value)
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }
}

/// Factory pour la création d'instances de FirestoreModel avec une instance Firestore spécifique
/// Utile pour l'injection de dépendances et les tests
class FirestoreModelFactory {
  final FirebaseFirestore firestore;

  FirestoreModelFactory({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  /// Méthode pour créer un modèle avec une instance Firestore injectée
  T create<T extends FirestoreModel<T>>(T model) {
    // Utiliser la réflexion ou un autre mécanisme pour injecter l'instance Firestore
    // Cette implémentation dépend de la manière dont vous souhaitez gérer l'injection
    // Pour cet exemple, nous supposons que le modèle a une méthode withFirestore
    return model;
  }
}
