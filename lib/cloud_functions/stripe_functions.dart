import 'package:cloud_functions/cloud_functions.dart';
import 'package:saasfork_core/saasfork_core.dart';

class StripeException implements Exception {
  final String message;
  final dynamic details;

  StripeException(this.message, [this.details]);

  @override
  String toString() =>
      'StripeException: $message${details != null ? '\nDetails: $details' : ''}';
}

/// Interface pour les fonctions Firebase
abstract class FirebaseFunctionsService {
  Future<HttpsCallableResult> callFunction(
    String functionName,
    Map<String, dynamic> parameters,
  );
}

/// Implémentation concrète utilisant Firebase Functions
class DefaultFirebaseFunctionsService implements FirebaseFunctionsService {
  @override
  Future<HttpsCallableResult> callFunction(
    String functionName,
    Map<String, dynamic> parameters,
  ) async {
    final callable = FirebaseFunctions.instance.httpsCallable(functionName);
    return await callable(parameters);
  }
}

class StripeFunctions {
  final FirebaseFunctionsService _functionsService;

  /// Constructeur avec paramètre optionnel pour l'injection de dépendance
  StripeFunctions([FirebaseFunctionsService? functionsService])
    : _functionsService = functionsService ?? DefaultFirebaseFunctionsService();

  /// Méthode statique pour garder la compatibilité avec le code existant
  static Future<String> createStripePaymentLink(
    Map<String, dynamic> productDetails, {
    String successCallbackUrl = 'confirmation',
    String failureCallbackUrl = 'cancelled',
    String? fromUrl,
  }) async {
    return await StripeFunctions().createPaymentLink(
      productDetails,
      successCallbackUrl: successCallbackUrl,
      failureCallbackUrl: failureCallbackUrl,
      fromUrl: fromUrl,
    );
  }

  /// Méthode d'instance qui peut être testée
  Future<String> createPaymentLink(
    Map<String, dynamic> productDetails, {
    String successCallbackUrl = 'confirmation',
    String failureCallbackUrl = 'cancelled',
    String? fromUrl,
  }) async {
    // Vérifier si productDetails contient les informations nécessaires
    if (productDetails.isEmpty) {
      throw StripeException('Product details cannot be empty');
    }

    // Vérifier les champs requis (ajustez selon vos besoins)
    final requiredFields = [
      'product_name',
      'unit_amount',
      'currency',
      'period',
      'payment_id',
    ];
    for (final field in requiredFields) {
      if (!productDetails.containsKey(field) || productDetails[field] == null) {
        throw StripeException('Missing required field: $field');
      }
    }

    if (productDetails['unit_amount'] <= 0) {
      throw StripeException('unit_amount must be a positive number');
    }

    if (productDetails.containsKey('trial_period_days')) {
      final trialPeriodDays = productDetails['trial_period_days'];
      if (trialPeriodDays != null && trialPeriodDays <= 0) {
        throw StripeException('trial_period_days must be a positive number');
      }
    }

    if (successCallbackUrl.startsWith('/')) {
      successCallbackUrl = successCallbackUrl.substring(1);
    }

    if (failureCallbackUrl.startsWith('/')) {
      failureCallbackUrl = failureCallbackUrl.substring(1);
    }

    if (successCallbackUrl.isEmpty) {
      throw StripeException('successCallbackUrl cannot be empty');
    }

    if (failureCallbackUrl.isEmpty) {
      throw StripeException('failureCallbackUrl cannot be empty');
    }

    try {
      final response = await _functionsService
          .callFunction('createStripePaymentLink', {
            ...productDetails,
            'from_url': fromUrl ?? getLocalhostUrl(),
            'success_callback_url': successCallbackUrl,
            'failure_callback_url': failureCallbackUrl,
          });

      // Vérifier si la réponse contient un lien de paiement
      if (response.data == null ||
          !response.data.containsKey('paymentLink') ||
          response.data['paymentLink'] == null) {
        throw StripeException(
          'Invalid response from Stripe service',
          response.data,
        );
      }

      return response.data['paymentLink'];
    } on FirebaseFunctionsException catch (e) {
      throw StripeException('Firebase function error: ${e.message}', {
        'code': e.code,
        'details': e.details,
      });
    } catch (e) {
      throw StripeException('Failed to create payment link', e);
    }
  }

  /// Méthode statique pour garder la compatibilité avec le code existant
  static Future<String> createStripePortalLink({
    required String customerId,
    String callbackUrl = 'settings',
    String? fromUrl,
  }) async {
    return await StripeFunctions().createPortalLink(
      customerId: customerId,
      callbackUrl: callbackUrl,
      fromUrl: fromUrl,
    );
  }

  /// Méthode d'instance qui peut être testée
  Future<String> createPortalLink({
    required String customerId,
    String callbackUrl = 'settings',
    String? fromUrl,
  }) async {
    // Vérifier que l'ID client n'est pas vide
    if (customerId.isEmpty) {
      throw StripeException('customer_id cannot be empty');
    }

    if (callbackUrl.startsWith('/')) {
      callbackUrl = callbackUrl.substring(1);
    }

    try {
      final response = await _functionsService
          .callFunction('createStripePortalSession', {
            'customer_id': customerId,
            'from_url': fromUrl ?? getLocalhostUrl(),
            'callback_url': callbackUrl,
          });

      // Vérifier si la réponse contient une URL
      if (response.data == null ||
          !response.data.containsKey('url') ||
          response.data['url'] == null) {
        throw StripeException(
          'Failed to create portal link',
          'Invalid response from Stripe portal service: ${response.data}',
        );
      }

      return response.data['url'];
    } on FirebaseFunctionsException catch (e) {
      throw StripeException('Firebase function error: ${e.message}', {
        'code': e.code,
        'details': e.details,
      });
    } catch (e) {
      throw StripeException('Failed to create portal link', e);
    }
  }
}
