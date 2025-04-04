import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saasfork_core/saasfork_core.dart';

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
    log('Saving to collection: $collectionName');
    log('Excluded fields: $excludeFromSave');
    log('Filtered data to save: $map');

    return map;
  }

  /// Sauvegarder ou mettre à jour
  ///
  /// Exemple:
  /// ```dart
  /// // Création d'un nouvel utilisateur
  /// final user = UserModel(
  ///   name: 'Jean Dupont',
  ///   email: 'jean@example.com',
  ///   isActive: true,
  /// );
  /// await user.save();
  /// print('Utilisateur sauvegardé avec ID: ${user.id}');
  ///
  /// // Mise à jour d'un utilisateur existant
  /// user.name = 'Jean Martin';
  /// await user.save();
  /// print('Utilisateur mis à jour');
  /// ```
  Future<void> save() async {
    // Utiliser la map filtrée au lieu de toMap() directement
    final filteredMap = _getFilteredMap();
    final collection = firestore.collection(collectionName);

    if (id == null) {
      final docRef = await collection.add(filteredMap);
      id = docRef.id;
      log('Saved new document with ID: $id');
    } else {
      await collection.doc(id).set(filteredMap);
      log('Updated document with ID: $id');
    }
  }

  /// Sauvegarder avec des exclusions supplémentaires
  ///
  /// Exemple:
  /// ```dart
  /// // Sauvegarder un utilisateur sans le champ temporaire 'lastLoginTime'
  /// final user = UserModel(
  ///   name: 'Marie Durand',
  ///   email: 'marie@example.com',
  ///   lastLoginTime: DateTime.now(), // Champ temporaire qui ne doit pas être persisté
  /// );
  /// await user.saveWithExclusion({'lastLoginTime'});
  ///
  /// // Sauvegarder un produit sans les champs calculés
  /// final product = ProductModel(
  ///   name: 'Smartphone XYZ',
  ///   price: 499.99,
  ///   calculatedProfit: 150.00,
  ///   tempDiscount: 50.00,
  /// );
  /// await product.saveWithExclusion({'calculatedProfit', 'tempDiscount'});
  /// ```
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
    log('Saving to collection: $collectionName with additional exclusions');
    log('Default excluded fields: $excludeFromSave');
    log('Additional excluded fields: $additionalExcludeFields');
    log('Filtered data to save: $map');

    final collection = firestore.collection(collectionName);

    if (id == null) {
      final docRef = await collection.add(map);
      id = docRef.id;
      log('Saved new document with ID: $id');
    } else {
      await collection.doc(id).set(map);
      log('Updated document with ID: $id');
    }
  }

  /// Supprimer
  ///
  /// Exemple:
  /// ```dart
  /// // Supprimer un utilisateur
  /// final user = await userModel.findById('user123');
  /// if (user != null) {
  ///   await user.delete();
  ///   print('Utilisateur supprimé');
  /// }
  ///
  /// // Récupérer et supprimer tous les utilisateurs inactifs
  /// final inactiveUsers = await userModel.findWhere(
  ///   field: 'isActive',
  ///   isEqualTo: false,
  /// );
  /// for (final user in inactiveUsers) {
  ///   await user.delete();
  /// }
  /// print('${inactiveUsers.length} utilisateurs inactifs supprimés');
  /// ```
  Future<void> delete() async {
    if (id != null) {
      await firestore.collection(collectionName).doc(id).delete();
    }
  }

  /// Trouver un document par ID
  ///
  /// Exemple:
  /// ```dart
  /// // Récupérer un utilisateur par son ID
  /// final userModel = UserModel();
  /// final user = await userModel.findById('user123');
  /// if (user != null) {
  ///   print('Utilisateur trouvé: ${user.name}');
  /// }
  /// ```
  Future<T?> findById(String documentId) async {
    final doc =
        await firestore.collection(collectionName).doc(documentId).get();
    if (doc.exists) {
      return fromDocumentSnapshot(doc);
    }
    return null;
  }

  /// Récupérer tous les documents
  ///
  /// Exemple:
  /// ```dart
  /// // Récupérer tous les utilisateurs
  /// final userModel = UserModel();
  /// final users = await userModel.findAll();
  /// print('Nombre d\'utilisateurs: ${users.length}');
  /// for (final user in users) {
  ///   print('- ${user.name} (${user.email})');
  /// }
  /// ```
  Future<List<T>> findAll() async {
    final snapshot = await firestore.collection(collectionName).get();
    return snapshot.docs.map((doc) => fromDocumentSnapshot(doc)).toList();
  }

  /// Trouver des documents par une requête
  ///
  /// Exemple:
  /// ```dart
  /// // Récupérer les utilisateurs actifs (maximum 10)
  /// final userModel = UserModel();
  /// final activeUsers = await userModel.findWhere(
  ///   field: 'isActive',
  ///   isEqualTo: true,
  ///   limit: 10,
  /// );
  /// print('Utilisateurs actifs: ${activeUsers.length}');
  ///
  /// // Trouver tous les utilisateurs d'un certain type
  /// final premiumUsers = await userModel.findWhere(
  ///   field: 'accountType',
  ///   isEqualTo: 'premium',
  /// );
  /// ```
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
  ///
  /// Exemple:
  /// ```dart
  /// // Vérifier si un email est déjà utilisé
  /// final userModel = UserModel();
  /// final emailExists = await userModel.exists(
  ///   field: 'email',
  ///   value: 'utilisateur@example.com',
  /// );
  ///
  /// if (emailExists) {
  ///   print('Cet email est déjà utilisé!');
  /// } else {
  ///   print('Cet email est disponible.');
  /// }
  /// ```
  Future<bool> exists({required String field, required dynamic value}) async {
    final snapshot =
        await firestore
            .collection(collectionName)
            .where(field, isEqualTo: value)
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Écouter les modifications d'un document
  ///
  /// Retourne un Stream qui émet une nouvelle instance du modèle
  /// à chaque fois que le document est modifié dans Firestore.
  ///
  /// Exemple:
  /// ```dart
  /// // Créer une instance du modèle PaymentModel
  /// final paymentModel = PaymentModel();
  ///
  /// // Écouter les modifications d'un paiement spécifique
  /// final paymentStream = paymentModel.listenDocument('payment123');
  ///
  /// // S'abonner au stream pour recevoir les mises à jour
  /// final subscription = paymentStream.listen((updatedPayment) {
  ///   if (updatedPayment != null) {
  ///     print('Statut de paiement mis à jour: ${updatedPayment.status}');
  ///
  ///     // Vérifier si le paiement est complètement traité
  ///     if (updatedPayment.checkoutComplete &&
  ///         updatedPayment.subscriptionCreated &&
  ///         updatedPayment.paymentConfirmed) {
  ///       print('Le paiement est entièrement terminé !');
  ///
  ///       // Déclencher une action spécifique
  ///       _unlockPremiumFeatures(updatedPayment.userId);
  ///     }
  ///   } else {
  ///     print('Le document a été supprimé');
  ///   }
  /// });
  ///
  /// // N'oubliez pas d'annuler l'abonnement lorsque vous n'en avez plus besoin
  /// @override
  /// void dispose() {
  ///   subscription.cancel();
  ///   super.dispose();
  /// }
  /// ```
  Stream<T?> listenDocument(String documentId) {
    return firestore.collection(collectionName).doc(documentId).snapshots().map(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          return fromDocumentSnapshot(snapshot);
        } else {
          // Retourne null si le document n'existe pas ou a été supprimé
          return null;
        }
      },
    );
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
