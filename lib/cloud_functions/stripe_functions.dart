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

// TODO: Rendre plus testable cette classe
class StripeFunctions {
  static Future<String> createStripePaymentLink(
    Map<String, dynamic> productDetails,
  ) async {
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

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createStripePaymentLink',
      );

      final response = await callable({
        ...productDetails,
        'from_url': getLocalhostUrl(),
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
}
