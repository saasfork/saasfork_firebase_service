import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:saasfork_firebase_service/cloud_functions/stripe_functions.dart';

// Génération des mocks
@GenerateMocks([FirebaseFunctionsService])
import 'stripe_functions_test.mocks.dart';

void main() {
  late MockFirebaseFunctionsService mockFunctionsService;
  late StripeFunctions stripeFunctions;

  setUp(() {
    mockFunctionsService = MockFirebaseFunctionsService();
    stripeFunctions = StripeFunctions(mockFunctionsService);
  });

  group('createPaymentLink', () {
    final validProductDetails = {
      'product_name': 'Test Product',
      'unit_amount': 1000,
      'currency': 'usd',
      'period': 'month',
      'payment_id': 'test-payment-id',
    };

    test('should throw exception when product details are empty', () async {
      expect(
        () => stripeFunctions.createPaymentLink({}),
        throwsA(
          isA<StripeException>().having(
            (e) => e.message,
            'message',
            'Product details cannot be empty',
          ),
        ),
      );
    });

    test('should throw exception when required field is missing', () async {
      final invalidDetails = {...validProductDetails};
      invalidDetails.remove('product_name');

      expect(
        () => stripeFunctions.createPaymentLink(invalidDetails),
        throwsA(
          isA<StripeException>().having(
            (e) => e.message,
            'message',
            contains('Missing required field'),
          ),
        ),
      );
    });

    test('should throw exception when unit_amount is not positive', () async {
      final invalidDetails = {...validProductDetails, 'unit_amount': 0};

      expect(
        () => stripeFunctions.createPaymentLink(invalidDetails),
        throwsA(
          isA<StripeException>().having(
            (e) => e.message,
            'message',
            'unit_amount must be a positive number',
          ),
        ),
      );
    });

    test(
      'should throw exception when trial_period_days is not positive',
      () async {
        final invalidDetails = {...validProductDetails, 'trial_period_days': 0};

        expect(
          () => stripeFunctions.createPaymentLink(invalidDetails),
          throwsA(
            isA<StripeException>().having(
              (e) => e.message,
              'message',
              'trial_period_days must be a positive number',
            ),
          ),
        );
      },
    );

    test('should return payment link when function call succeeds', () async {
      final expectedPaymentLink = 'https://example.com/pay/123';

      // Créer un mock de HttpsCallableResult
      final mockResult = MockHttpsCallableResult();
      when(mockResult.data).thenReturn({'paymentLink': expectedPaymentLink});

      // Configurer le mock pour retourner le résultat attendu
      when(
        mockFunctionsService.callFunction('createStripePaymentLink', any),
      ).thenAnswer((_) async => mockResult);

      final result = await stripeFunctions.createPaymentLink(
        validProductDetails,
      );

      expect(result, equals(expectedPaymentLink));
      verify(
        mockFunctionsService.callFunction(
          'createStripePaymentLink',
          argThat(
            predicate<Map<String, dynamic>>((map) {
              return map.containsKey('from_url') &&
                  map['product_name'] == validProductDetails['product_name'];
            }),
          ),
        ),
      ).called(1);
    });

    test(
      'should throw exception when response is missing payment link',
      () async {
        // Créer un mock avec une réponse invalide
        final mockResult = MockHttpsCallableResult();
        when(mockResult.data).thenReturn({'otherData': 'value'});

        when(
          mockFunctionsService.callFunction('createStripePaymentLink', any),
        ).thenAnswer((_) async => mockResult);

        expect(
          () => stripeFunctions.createPaymentLink(validProductDetails),
          throwsA(
            isA<StripeException>()
                .having(
                  (e) => e.message,
                  'message',
                  'Failed to create payment link',
                )
                .having(
                  (e) => e.details.toString(),
                  'details',
                  contains('Invalid response from Stripe service'),
                ),
          ),
        );
      },
    );

    test('should throw exception when Firebase function call fails', () async {
      when(
        mockFunctionsService.callFunction('createStripePaymentLink', any),
      ).thenThrow(
        FirebaseFunctionsException(
          message: 'error',
          code: 'code',
          details: 'details',
        ),
      );

      expect(
        () => stripeFunctions.createPaymentLink(validProductDetails),
        throwsA(
          isA<StripeException>().having(
            (e) => e.message,
            'message',
            contains('Firebase function error'),
          ),
        ),
      );
    });
  });

  group('createPortalLink', () {
    test('should throw exception when customer ID is empty', () async {
      expect(
        () => stripeFunctions.createPortalLink(customerId: ''),
        throwsA(
          isA<StripeException>().having(
            (e) => e.message,
            'message',
            'customer_id cannot be empty',
          ),
        ),
      );
    });

    test('should return portal URL when function call succeeds', () async {
      final expectedUrl = 'https://billing.stripe.com/session/123';

      // Créer un mock de HttpsCallableResult
      final mockResult = MockHttpsCallableResult();
      when(mockResult.data).thenReturn({'url': expectedUrl});

      when(
        mockFunctionsService.callFunction('createStripePortalSession', any),
      ).thenAnswer((_) async => mockResult);

      final result = await stripeFunctions.createPortalLink(
        customerId: 'cus_123',
      );

      expect(result, equals(expectedUrl));
      verify(
        mockFunctionsService.callFunction(
          'createStripePortalSession',
          argThat(
            predicate<Map<String, dynamic>>((map) {
              return map.containsKey('from_url') &&
                  map['customer_id'] == 'cus_123';
            }),
          ),
        ),
      ).called(1);
    });

    test('should throw exception when response is missing URL', () async {
      // Créer un mock avec une réponse invalide
      final mockResult = MockHttpsCallableResult();
      when(mockResult.data).thenReturn({'otherData': 'value'});

      when(
        mockFunctionsService.callFunction('createStripePortalSession', any),
      ).thenAnswer((_) async => mockResult);

      expect(
        () => stripeFunctions.createPortalLink(customerId: 'cus_123'),
        throwsA(
          isA<StripeException>()
              .having(
                (e) => e.message,
                'message',
                'Failed to create portal link',
              )
              .having(
                (e) => e.details.toString(),
                'details',
                contains('Invalid response from Stripe portal service'),
              ),
        ),
      );
    });
  });
}

// Mock pour HttpsCallableResult car il n'est pas inclus dans @GenerateMocks
class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {
  @override
  Map<String, dynamic> get data => super.noSuchMethod(
    Invocation.getter(#data),
    returnValue: <String, dynamic>{},
  );
}
