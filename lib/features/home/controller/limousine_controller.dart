import 'dart:convert';
import 'package:cabme/core/constant/show_toast_dialog.dart';
import 'package:cabme/core/utils/Preferences.dart';
import 'package:cabme/features/home/model/limousine_vehicle_model.dart';
import 'package:cabme/service/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LimousineController extends GetxController {
  RxList<LimousineVehicle> vehicles = <LimousineVehicle>[].obs;
  Rx<LimousineVehicle?> selectedVehicle = Rx<LimousineVehicle?>(null);

  Rx<LatLng?> pickupLatLng = Rx<LatLng?>(null);
  Rx<DateTime?> startDate = Rx<DateTime?>(null);
  Rx<TimeOfDay?> startTime = Rx<TimeOfDay?>(null);

  final List<int> durationOptions = const [8, 10, 12];
  RxInt selectedDuration = 8.obs;

  RxBool isLoading = false.obs;

  // Booking data returned after submitBooking success
  Rx<Map<String, dynamic>?> pendingBookingData =
      Rx<Map<String, dynamic>?>(null);

  // Future<void> fetchVehicles() async {
  //   try {
  //     isLoading.value = true;
  //     final response = await http.get(
  //       Uri.parse(API.limousineVehicles),
  //       headers: API.header,
  //     );
  //     final body = json.decode(response.body);
  //     if (response.statusCode == 200 && body['success'] == 'Success') {
  //       final model = LimousineVehicleModel.fromJson(body);
  //       vehicles.value = model.data ?? [];
  //     }
  //   } catch (e) {
  //     ShowToastDialog.showToast('failed_to_load_limousine_vehicles'.tr);
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<void> fetchVehicles() async {
    try {
      isLoading.value = true;
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'apikey': API.apiKey,
        'accesstoken': Preferences.getString(Preferences.accesstoken),
      };

      final response = await http.get(
        Uri.parse(API.limousineVehicles),
        headers: headers,
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'Success') {
        final model = LimousineVehicleModel.fromJson(body);
        vehicles.value = model.data ?? [];
      } else {
        ShowToastDialog.showToast('failed_to_load_limousine_vehicles'.tr);
      }
    } catch (e) {
      ShowToastDialog.showToast('failed_to_load_limousine_vehicles'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  double get totalPrice {
    if (selectedVehicle.value == null) return 0;
    return selectedVehicle.value!.priceForDuration(selectedDuration.value);
  }

  String get formattedStartTime {
    if (startTime.value == null) return '';
    final h = startTime.value!.hour.toString().padLeft(2, '0');
    final m = startTime.value!.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  String get formattedStartDate {
    if (startDate.value == null) return '';
    return "${startDate.value!.year}-${startDate.value!.month.toString().padLeft(2, '0')}-${startDate.value!.day.toString().padLeft(2, '0')}";
  }

  Future<Map<String, dynamic>?> submitBooking({
    required String pickupLocationText,
  }) async {
    if (selectedVehicle.value == null) {
      ShowToastDialog.showToast('please_select_vehicle_type'.tr);
      return null;
    }
    if (pickupLatLng.value == null) {
      ShowToastDialog.showToast('please_select_pickup_location'.tr);
      return null;
    }
    if (startDate.value == null) {
      ShowToastDialog.showToast('please_select_start_date'.tr);
      return null;
    }
    if (startTime.value == null) {
      ShowToastDialog.showToast('please_select_start_time'.tr);
      return null;
    }

    try {
      isLoading.value = true;
      final bodyParams = {
        'user_id': Preferences.getInt(Preferences.userId).toString(),
        'id_limousine_vehicle': selectedVehicle.value!.id.toString(),
        'pickup_location': pickupLocationText,
        'pickup_latitude': pickupLatLng.value!.latitude.toString(),
        'pickup_longitude': pickupLatLng.value!.longitude.toString(),
        'start_date': formattedStartDate,
        'end_date': formattedStartDate,
        'start_time': formattedStartTime,
        'duration_hours': selectedDuration.value.toString(),
      };

      final response = await http.post(
        Uri.parse(API.limousineBook),
        headers: API.header,
        body: jsonEncode(bodyParams),
      );
      final body = json.decode(response.body);
      isLoading.value = false;

      if (response.statusCode == 200 && body['success'] == 'Success') {
        pendingBookingData.value = body['data'] as Map<String, dynamic>?;
        return body['data'];
      } else {
        ShowToastDialog.showToast(body['error'] ?? 'Booking failed');
        return null;
      }
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast('${'error_colon'.tr}$e');
      return null;
    }
  }

  /// Called after admin approves — user pays from this
//   Future<bool> payBooking({
//     required int bookingId,
//     required String paymethod,
//     required String paymentStatus,
//     String? transactionId,
//   }) async {
//     try {
//       isLoading.value = true;
//       final bodyParams = {
//         'booking_id': bookingId.toString(),
//         'user_id': Preferences.getInt(Preferences.userId).toString(),
//         'paymethod': paymethod,
//         'payment_status': paymentStatus,
//         'transaction_id': transactionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
//       };

//       final response = await http.post(
//         Uri.parse(API.limousinePayBooking),
//         headers: API.header,
//         body: jsonEncode(bodyParams),
//       );
//       final body = json.decode(response.body);
//       isLoading.value = false;

//       if (response.statusCode == 200 && body['success'] == 'Success') {
//         return true;
//       } else {
//         ShowToastDialog.showToast(body['error'] ?? 'Payment failed');
//         return false;
//       }
//     } catch (e) {
//       isLoading.value = false;
//       ShowToastDialog.showToast('${'error_colon'.tr}$e');
//       return false;
//     }
//   }
// }

  Future<bool> payBooking({
    required int bookingId,
    required String paymethod,
    required String paymentStatus,
    String? transactionId,
  }) async {
    try {
      isLoading.value = true;

      final bodyParams = {
        'booking_id': bookingId.toString(),
        'user_id': Preferences.getInt(Preferences.userId).toString(),
        'paymethod': paymethod,
        'payment_status': paymentStatus,
        'transaction_id':
            transactionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final String token = Preferences.getString(Preferences.accesstoken);
      final Map<String, String> dynamicHeaders = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'apikey': API.apiKey,
        if (token.isNotEmpty) 'accesstoken': token,
      };

      final response = await http.post(
        Uri.parse(API.limousinePayBooking),
        headers: dynamicHeaders,
        body: jsonEncode(bodyParams),
      );

      isLoading.value = false;

      final String contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        debugPrint(
            "Server Error (${response.statusCode}): HTML Returned instead of JSON");
        ShowToastDialog.showToast(
            'رمز الخطأ من السيرفر: ${response.statusCode}');
        return false;
      }

      final body = json.decode(response.body);

      if (response.statusCode == 200 &&
          (body['success'] == 'Success' || body['status'] == true)) {
        return true;
      } else {
        ShowToastDialog.showToast(
            body['error'] ?? body['message'] ?? 'فشلت عملية الدفع');
        return false;
      }
    } catch (e) {
      isLoading.value = false;
      debugPrint("PayBooking Exception: $e");
      ShowToastDialog.showToast('تعذر إكمال العملية: $e');
      return false;
    }
  }
}
