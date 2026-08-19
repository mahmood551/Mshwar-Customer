import 'package:cabme/common/widget/button.dart';
import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/common/widget/my_custom_dialog.dart';
import 'package:cabme/core/constant/constant.dart';
import 'package:cabme/core/constant/show_toast_dialog.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:cabme/features/home/controller/limousine_controller.dart';
import 'package:cabme/features/home/view/location_picker_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class LimousineBookingScreen extends StatefulWidget {
  const LimousineBookingScreen({super.key});

  @override
  State<LimousineBookingScreen> createState() =>
      _LimousineBookingScreenState();
}

class _LimousineBookingScreenState extends State<LimousineBookingScreen> {
  final LimousineController controller = Get.put(LimousineController());
  final TextEditingController pickupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.fetchVehicles();
  }

  DateTime get minAllowedDate {
    final now = DateTime.now();
    final min = now.add(const Duration(hours: 48));
    return DateTime(min.year, min.month, min.day);
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: minAllowedDate,
      firstDate: minAllowedDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.startDate.value = picked;
    }
  }

  Future<void> pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: controller.startTime.value ?? TimeOfDay.now(),
    );
    if (picked != null) {
      controller.startTime.value = picked;
    }
  }

  String formatDate(DateTime? d) {
    if (d == null) return 'select_date'.tr;
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  String formatTime(TimeOfDay? t) {
    if (t == null) return 'select_time'.tr;
    return t.format(context);
  }

  void _openPickupPicker() {
    MyCustomDialog.showWithActions(
      context: context,
      title: "select_pickup_location".tr,
      message: "choose_how_to_select_pickup_location".tr,
      actions: [
        CustomButton(
          btnName: "search".tr,
          icon: const Icon(Iconsax.search_normal, size: 18, color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          fontSize: 13,
          ontap: () async {
            Get.back();
            final value =
                await Constant().placeSelectAPI(context, pickupController);
            if (value != null) {
              controller.pickupLatLng.value = LatLng(
                value.result.geometry!.location.lat,
                value.result.geometry!.location.lng,
              );
              setState(() {});
            }
          },
        ),
        CustomButton(
          btnName: "on_map".tr,
          isOutlined: true,
          icon:
              Icon(Iconsax.location, size: 18, color: AppThemeData.primary200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          fontSize: 13,
          ontap: () async {
            Get.back();
            final result = await Get.to<LocationPickerResult>(
              () => LocationPickerMapScreen(
                initialPosition: controller.pickupLatLng.value,
              ),
            );
            if (result != null) {
              pickupController.text = result.address;
              controller.pickupLatLng.value = result.latLng;
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: AppBar(
        title: CustomText(
          text: 'limousine_service'.tr,
          size: 18,
          weight: FontWeight.w700,
        ),
        backgroundColor:
            isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
        elevation: 0,
      ),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pickup location
              CustomText(
                  text: 'pick_up_location'.tr,
                  size: 14,
                  weight: FontWeight.w600),
              const SizedBox(height: 8),
              InkWell(
                onTap: _openPickupPicker,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppThemeData.grey300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pickupController.text.isNotEmpty
                              ? pickupController.text
                              : 'tap_to_select_location'.tr,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Trip date
              CustomText(
                  text: 'trip_date'.tr, size: 14, weight: FontWeight.w600),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: pickStartDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppThemeData.grey300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined),
                      const SizedBox(width: 8),
                      Text(formatDate(controller.startDate.value)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Start time
              CustomText(
                  text: 'trip_start_time'.tr,
                  size: 14,
                  weight: FontWeight.w600),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: pickStartTime,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppThemeData.grey300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 8),
                      Text(formatTime(controller.startTime.value)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Duration
              CustomText(
                  text: 'booking_duration'.tr,
                  size: 14,
                  weight: FontWeight.w600),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppThemeData.grey300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: controller.selectedDuration.value,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: controller.durationOptions.map((hours) {
                      return DropdownMenuItem<int>(
                        value: hours,
                        child: Text("$hours ${'hours'.tr}"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedDuration.value = value;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Vehicle Type
              CustomText(
                  text: 'vehicle_type'.tr, size: 14, weight: FontWeight.w600),
              const SizedBox(height: 8),
              controller.isLoading.value && controller.vehicles.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: controller.vehicles.map((v) {
                        final isSelected =
                            controller.selectedVehicle.value?.id == v.id;
                        final priceForSelectedDuration = v.priceForDuration(
                            controller.selectedDuration.value);

                        return GestureDetector(
                          onTap: () => controller.selectedVehicle.value = v,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? AppThemeData.primary200
                                    : AppThemeData.grey300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    v.image ?? '',
                                    width: 70,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        width: 70,
                                        height: 50,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.directions_car,
                                            size: 30, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.name ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${'seats'.tr} ${v.seats ?? 0}",
                                        style: TextStyle(
                                          color: AppThemeData.grey500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${priceForSelectedDuration.toStringAsFixed(3)} ${'KWD'.tr}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 20),

              // Total summary
              if (controller.selectedVehicle.value != null &&
                  controller.startDate.value != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "${controller.selectedDuration.value} ${'hours'.tr}"),
                      Text(
                        "${'total_label'.tr}: ${controller.selectedVehicle.value!.priceForDuration(controller.selectedDuration.value).toStringAsFixed(3)} ${'KWD'.tr}",
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Send Request Button
              CustomButton(
                btnName: controller.isLoading.value
                    ? 'please_wait_dots'.tr
                    : 'send_request'.tr,
                ontap: controller.isLoading.value
                    ? null
                    : () async {
                        final result = await controller.submitBooking(
                          pickupLocationText: pickupController.text,
                        );
                        if (result != null) {
                          Get.dialog(
                            AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: CustomText(
                                text: 'limousine_booking_sent_title'.tr,
                                size: 18,
                                weight: FontWeight.w700,
                              ),
                              content: CustomText(
                                text: 'limousine_booking_sent_message'.tr,
                                size: 14,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    Get.back();
                                  },
                                  child: CustomText(
                                    text: 'ok'.tr,
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: AppThemeData.primary200,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

