import 'dart:async';
import 'dart:convert';

import 'package:cabme/core/utils/Preferences.dart';
import 'package:cabme/features/plans/subscription/controller/subscription_controller.dart';
import 'package:cabme/features/plans/subscription/model/subscription_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> quote({
  String distance = '1.60',
  String total = '111.760',
}) => {
  'distance_km': distance,
  'km_price': '0.150',
  'pickup_zone_fare': '1.150',
  'dropoff_zone_fare': '1.150',
  'zone_fare': '2.300',
  'km_fare': '0.240',
  'single_trip_price': '2.540',
  'total_trips': '44',
  'total_days': '32',
  'total_price': total,
  'trip_type': 'two_way',
  'quote_token': 'opaque-server-token',
  'quote_expires_at': DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 15))
      .toIso8601String(),
};
http.Response response(Map<String, dynamic> data) =>
    http.Response(jsonEncode({'success': 'success', 'data': data}), 200);
void fill(SubscriptionController c) {
  c.homeAddress.value = 'Home';
  c.destinationAddress.value = 'Destination';
  c.homeLatitude.value = 29.3394961;
  c.homeLongitude.value = 48.0216966;
  c.destinationLatitude.value = 29.3302455;
  c.destinationLongitude.value = 48.0190068;
  c.startDate.value = DateTime(2026, 9, 23);
  c.endDate.value = DateTime(2026, 10, 24);
  c.selectedWorkingDays.value = [0, 1, 2, 3, 4];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'userId': 77,
      'accesstoken': 'test-token',
    });
    await Preferences.initPref();
  });
  test(
    'preview sends both coordinates and uses server distance and zone price',
    () async {
      late Map<String, dynamic> sent;
      final c = SubscriptionController(
        quoteClient: MockClient((request) async {
          expect(request.url.path, endsWith('/subscription/quote'));
          sent = jsonDecode(request.body);
          return response(quote());
        }),
      );
      addTearDown(c.onClose);
      fill(c);
      c.distanceKm.value = 24.9;
      await c.calculatePrice();
      expect(sent['home_latitude'], 29.3394961);
      expect(sent['home_longitude'], 48.0216966);
      expect(sent['destination_latitude'], 29.3302455);
      expect(sent['destination_longitude'], 48.0190068);
      expect(sent.containsKey('distance_km'), isFalse);
      expect(c.distanceKm.value, 1.6);
      expect(c.priceData.value!.totalPrice, '111.760');
      expect(c.priceData.value!.zoneFare, '2.300');
      expect(c.hasValidQuote, isTrue);
    },
  );
  test(
    'out-of-order responses cannot restore a quote for an old selection',
    () async {
      final requests = <Completer<http.Response>>[];
      final c = SubscriptionController(
        quoteClient: MockClient((_) {
          final pending = Completer<http.Response>();
          requests.add(pending);
          return pending.future;
        }),
      );
      addTearDown(c.onClose);
      fill(c);
      final first = c.calculatePrice();
      await Future<void>.delayed(Duration.zero);
      c.destinationLatitude.value = 29.4;
      final second = c.calculatePrice();
      await Future<void>.delayed(Duration.zero);
      requests[1].complete(response(quote(distance: '2.40', total: '117.040')));
      await second;
      requests[0].complete(response(quote()));
      await first;
      expect(c.distanceKm.value, 2.4);
      expect(c.priceData.value!.totalPrice, '117.040');
      expect(c.hasValidQuote, isTrue);
    },
  );
  test('failed refresh clears the old price and prevents creation', () async {
    var calls = 0;
    final c = SubscriptionController(
      quoteClient: MockClient((_) async {
        return calls++ == 0 ? response(quote()) : http.Response('{}', 422);
      }),
    );
    addTearDown(c.onClose);
    fill(c);
    await c.calculatePrice();
    await c.calculatePrice();
    expect(c.priceData.value, isNull);
    expect(c.distanceKm.value, 0);
    expect(c.hasValidQuote, isFalse);
    expect(c.priceError.value, isNotEmpty);
  });
  test('incomplete form invalidates quote without issuing a request', () async {
    var calls = 0;
    final c = SubscriptionController(
      quoteClient: MockClient((_) async {
        calls++;
        return response(quote());
      }),
    );
    addTearDown(c.onClose);
    fill(c);
    await c.calculatePrice();
    c.selectedWorkingDays.clear();
    await c.calculatePrice();
    expect(calls, 1);
    expect(c.hasValidQuote, isFalse);
    expect(c.priceData.value, isNull);
  });
  test('expired or legacy responses are never usable quotes', () async {
    final expired = quote();
    expired['quote_expires_at'] = '2000-01-01T00:00:00Z';
    final c = SubscriptionController(
      quoteClient: MockClient((_) async => response(expired)),
    );
    addTearDown(c.onClose);
    fill(c);
    await c.calculatePrice();
    expect(c.hasValidQuote, isFalse);
    expect(c.priceData.value, isNull);
  });
  test('reset prevents an in-flight response from restoring a price', () async {
    final pending = Completer<http.Response>();
    final c = SubscriptionController(
      quoteClient: MockClient((_) => pending.future),
    );
    addTearDown(c.onClose);
    fill(c);
    final call = c.calculatePrice();
    await Future<void>.delayed(Duration.zero);
    c.resetForm();
    pending.complete(response(quote()));
    await call;
    expect(c.priceData.value, isNull);
    expect(c.distanceKm.value, 0);
  });
  testWidgets('creation sends the accepted quote and selected coordinates', (tester) async {
    await tester.pumpWidget(MaterialApp(builder: EasyLoading.init(), home: const Scaffold()));
    Map<String, dynamic>? created;
    final c = SubscriptionController(quoteClient: MockClient((request) async {
      if (request.url.path.endsWith('/subscription/quote')) return response(quote());
      expect(request.url.path, endsWith('/subscription/create-quoted'));
      created = jsonDecode(request.body);
      return http.Response(jsonEncode({'error': 'Test rejection'}), 400);
    }));
    addTearDown(c.onClose); fill(c);
    await c.calculatePrice();
    await c.createSubscription();
    expect(created!['quote_token'], 'opaque-server-token');
    expect(created!['home_latitude'], 29.3394961);
    expect(created!['destination_longitude'], 48.0190068);
    expect(created!['distance_km'], 1.6);
    expect(c.isCreating.value, isFalse);
    c.resetForm();
    await EasyLoading.dismiss();
    await tester.pump(const Duration(seconds: 5));
  });
  test('quote fields survive model serialization', () {
    final data = quote();
    expect(SubscriptionPriceData.fromJson(data).toJson(), data);
  });
}
