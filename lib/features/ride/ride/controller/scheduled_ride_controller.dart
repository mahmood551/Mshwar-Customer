import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cabme/core/constant/logdata.dart';
import 'package:cabme/features/ride/ride/model/ride_model.dart';
import 'package:cabme/service/api.dart';
import 'package:cabme/core/utils/Preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ScheduledRideController extends GetxController {
  var isLoading = true.obs;

  // All scheduled rides in one list
  var allScheduledRideList = <RideData>[].obs;

  // Legacy lists for backward compatibility
  var pendingRideList = <RideData>[].obs;
  var confirmedRideList = <RideData>[].obs;
  var completedRideList = <RideData>[].obs;

  Timer? timer;

  // Filter state
  var selectedFilter = 'all'.obs;

  // Filter options - same as driver app
  static const List<String> filterOptions = [
    'all',
    'pending',
    'new',
    'confirmed',
    'on ride',
    'completed'
  ];

  // Get filtered scheduled rides
  List<RideData> get filteredRideList {
    if (selectedFilter.value == 'all') {
      return allScheduledRideList;
    }
    return allScheduledRideList.where((ride) {
      final status = ride.statut?.toLowerCase() ?? '';
      final filter = selectedFilter.value.toLowerCase();

      if (filter == 'on ride') {
        return status == 'on ride' || status == 'onride';
      }
      return status == filter;
    }).toList();
  }

  // Get count for a specific status
  int getStatusCount(String filter) {
    if (filter == 'all') return allScheduledRideList.length;
    return allScheduledRideList.where((ride) {
      final status = ride.statut?.toLowerCase() ?? '';
      if (filter == 'on ride') {
        return status == 'on ride' || status == 'onride';
      }
      return status == filter.toLowerCase();
    }).length;
  }

  // Set filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
    update();
  }

  @override
  void onInit() {
    getScheduledRides(isinit: true);
    timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      getScheduledRides();
    });
    super.onInit();
  }

  @override
  void onClose() {
    timer?.cancel();
    super.onClose();
  }

  Future<dynamic> getScheduledRides({bool isinit = false}) async {
    try {
      if (isinit) {
        isLoading.value = true;
      }
      final response = await http.get(
        Uri.parse(
            "${API.userScheduledRides}?id_user_app=${Preferences.getInt(Preferences.userId)}"),
        headers: API.header,
      );

      showLog(
          "API :: URL :: ${API.userScheduledRides}?id_user_app=${Preferences.getInt(Preferences.userId)}");
      showLog("API :: Header :: ${API.header.toString()}");
      showLog("API :: responseStatus :: ${response.statusCode}");
      showLog("API :: responseBody :: ${response.body}");

      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        isLoading.value = false;
        RideModel model = RideModel.fromJson(responseBody);

        // Clear all lists
        allScheduledRideList.clear();
        pendingRideList.clear();
        confirmedRideList.clear();
        completedRideList.clear();

        // Store all rides
        allScheduledRideList.addAll(model.data!);

        // Also populate legacy lists for backward compatibility
        for (var ride in model.data!) {
          if (ride.statut == "pending" || ride.statut == "new") {
            pendingRideList.add(ride);
          } else if (ride.statut == "confirmed" || ride.statut == "on ride") {
            confirmedRideList.add(ride);
          } else if (ride.statut == "completed") {
            completedRideList.add(ride);
          }
        }
        update();
      } else {
        allScheduledRideList.clear();
        pendingRideList.clear();
        confirmedRideList.clear();
        completedRideList.clear();
        isLoading.value = false;
        update();
      }
    } on TimeoutException {
      isLoading.value = false;
      update();
    } on SocketException {
      isLoading.value = false;
      update();
    } on Error {
      isLoading.value = false;
      update();
    } catch (e) {
      log('ScheduledRideController.getScheduledRides Parse error $e');
      isLoading.value = false;
      update();
    }
    return null;
  }
}
