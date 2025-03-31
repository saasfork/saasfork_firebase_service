import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

// Créer un provider pour FirebaseStorage
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// Mettre à jour le provider du service pour utiliser le provider de FirebaseStorage
final storageServiceProvider = Provider<SFStorageService>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return SFStorageService(storage: storage);
});

/// Service pour gérer les uploads de fichiers vers Firebase Storage.
class SFStorageService {
  final FirebaseStorage _storage;
  final String _basePath;

  /// Crée une nouvelle instance du service de stockage.
  ///
  /// [basePath] est le chemin de base dans Firebase Storage où les fichiers
  /// seront stockés. Par défaut: 'uploads'.
  SFStorageService({FirebaseStorage? storage, String basePath = 'uploads'})
    : _storage = storage ?? FirebaseStorage.instance,
      _basePath = basePath;

  /// Télécharge un fichier XFile vers Firebase Storage et retourne son URL.
  ///
  /// [file] est le fichier à télécharger.
  /// [folder] est le sous-dossier optionnel dans lequel placer le fichier.
  /// [userId] est l'ID optionnel de l'utilisateur, pour organiser les fichiers par utilisateur.
  /// [customFileName] est un nom personnalisé pour le fichier. Par défaut, un MD5 est généré.
  /// [metadata] est un ensemble optionnel de métadonnées pour le fichier.
  ///
  /// Retourne l'URL de téléchargement du fichier.
  Future<String> uploadXFile({
    required XFile file,
    String? folder,
    String? userId,
    String? customFileName,
    Map<String, String>? metadata,
  }) async {
    final fileName =
        customFileName ??
        await _generateMd5FileName(file) + path.extension(file.name);
    final storagePath = _buildStoragePath(fileName, folder, userId);
    final fileMetadata = SettableMetadata(
      contentType: file.mimeType,
      customMetadata: metadata,
    );

    UploadTask uploadTask;

    if (kIsWeb) {
      // Upload pour le Web
      final bytes = await file.readAsBytes();
      uploadTask = _storage.ref(storagePath).putData(bytes, fileMetadata);
    } else {
      // Upload pour mobile/desktop
      final filePath = file.path;
      final fileToUpload = File(filePath);
      uploadTask = _storage
          .ref(storagePath)
          .putFile(fileToUpload, fileMetadata);
    }

    // Attendre la fin de l'upload
    final TaskSnapshot snapshot = await uploadTask;

    // Récupérer l'URL de téléchargement
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  /// Génère un nom de fichier basé sur le hash MD5 du contenu du fichier.
  Future<String> _generateMd5FileName(XFile file) async {
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Télécharge des données binaires vers Firebase Storage et retourne l'URL.
  ///
  /// [data] contient les données binaires du fichier.
  /// [fileName] est le nom à donner au fichier, incluant l'extension.
  /// [contentType] est le type MIME du fichier (ex: 'image/jpeg').
  /// [folder] est le sous-dossier optionnel.
  /// [userId] est l'ID optionnel de l'utilisateur.
  /// [metadata] est un ensemble optionnel de métadonnées pour le fichier.
  ///
  /// Retourne l'URL de téléchargement du fichier.
  Future<String> uploadData({
    required Uint8List data,
    required String fileName,
    required String contentType,
    String? folder,
    String? userId,
    Map<String, String>? metadata,
  }) async {
    final storagePath = _buildStoragePath(fileName, folder, userId);
    final fileMetadata = SettableMetadata(
      contentType: contentType,
      customMetadata: metadata,
    );

    // Télécharger les données
    final TaskSnapshot snapshot = await _storage
        .ref(storagePath)
        .putData(data, fileMetadata);

    // Récupérer l'URL de téléchargement
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  /// Supprime un fichier de Firebase Storage.
  ///
  /// [fileUrl] est l'URL du fichier à supprimer.
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Extraire le chemin complet à partir de l'URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // Le dernier segment contient le token, on le supprime
      if (pathSegments.isNotEmpty) {
        // Supprimer le fichier directement à partir de l'URL
        await _storage.refFromURL(fileUrl).delete();
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression du fichier: $e');
      rethrow;
    }
  }

  /// Construit le chemin de stockage pour un fichier.
  String _buildStoragePath(String fileName, String? folder, String? userId) {
    final List<String> pathParts = [_basePath];

    if (userId != null && userId.isNotEmpty) {
      pathParts.add('users');
      pathParts.add(userId);
    }

    if (folder != null && folder.isNotEmpty) {
      pathParts.add(folder);
    }

    pathParts.add(fileName);

    return pathParts.join('/');
  }

  /// Génère une URL de téléchargement signée avec une durée d'expiration.
  ///
  /// [fileUrl] est l'URL du fichier pour lequel générer un lien signé.
  /// [expirationDuration] est la durée de validité du lien signé.
  ///
  /// Retourne l'URL signée.
  Future<String> getSignedUrl(
    String fileUrl, {
    Duration expirationDuration = const Duration(hours: 1),
  }) async {
    final ref = _storage.refFromURL(fileUrl);
    final signedUrl = await ref.getDownloadURL();
    return signedUrl;
  }
}
