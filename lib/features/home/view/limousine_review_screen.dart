import 'package:cabme/common/widget/button.dart';
import 'package:cabme/common/widget/custom_app_bar.dart';
import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/common/widget/light_bordered_card.dart';
import 'package:cabme/core/constant/constant.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:cabme/features/home/view/limousine_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class LimousineReviewScreen extends StatelessWidget {
  final int bookingId;
  final String vehicleName;
  final int durationHours;
  final double totalPrice;
  final String pickupLocation;
  final String startDate;
  final String startTime;

  const LimousineReviewScreen({
    super.key,
    required this.bookingId,
    required this.vehicleName,
    required this.durationHours,
    required this.totalPrice,
    required this.pickupLocation,
    required this.startDate,
    required this.startTime,
  });

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: label,
                size: 11,
                color: isDarkMode
                    ? AppThemeData.grey500Dark
                    : AppThemeData.grey500,
              ),
              const SizedBox(height: 2),
              CustomText(
                text: value,
                size: 13,
                weight: FontWeight.w600,
                color: isDarkMode
                    ? AppThemeData.grey900Dark
                    : AppThemeData.grey900,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
      appBar: CustomAppBar(
        title: 'review_your_ride'.tr,
        showBackButton: true,
        onBackPressed: () => Get.back(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: LightBorderedCard(
                margin: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: 'total_amount'.tr,
                          size: 13,
                          weight: FontWeight.w500,
                          color: isDarkMode
                              ? AppThemeData.grey500Dark
                              : AppThemeData.grey500,
                        ),
                        const SizedBox(height: 6),
                        CustomText(
                          text: Constant()
                              .amountShow(amount: totalPrice.toStringAsFixed(2)),
                          size: 24,
                          weight: FontWeight.w800,
                          color: AppThemeData.primary200,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LightBorderedCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Iconsax.route_square,
                                  size: 20, color: AppThemeData.primary200),
                              const SizedBox(width: 8),
                              CustomText(
                                text: 'ride_details'.tr,
                                size: 16,
                                weight: FontWeight.w700,
                                color: isDarkMode
                                    ? AppThemeData.grey900Dark
                                    : AppThemeData.grey900,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      AppThemeData.success300.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(Iconsax.location,
                                      size: 20, color: AppThemeData.success300),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: 'pick_up_location'.tr,
                                      size: 12,
                                      color: isDarkMode
                                          ? AppThemeData.grey500Dark
                                          : AppThemeData.grey500,
                                    ),
                                    const SizedBox(height: 4),
                                    CustomText(
                                      text: pickupLocation.isNotEmpty
                                          ? pickupLocation
                                          : 'not_set'.tr,
                                      size: 14,
                                      weight: FontWeight.w500,
                                      color: isDarkMode
                                          ? AppThemeData.grey900Dark
                                          : AppThemeData.grey900,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: isDarkMode
                                ? AppThemeData.grey300Dark.withOpacity(0.3)
                                : AppThemeData.grey300.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Iconsax.calendar,
                                  label: 'trip_date'.tr,
                                  value: startDate.isNotEmpty
                                      ? startDate
                                      : 'n_a'.tr,
                                  iconColor: AppThemeData.warning200,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Iconsax.clock,
                                  label: 'trip_start_time'.tr,
                                  value: startTime.isNotEmpty
                                      ? startTime
                                      : 'n_a'.tr,
                                  iconColor: AppThemeData.info200,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Iconsax.timer_1,
                                  label: 'booking_duration'.tr,
                                  value: "$durationHours ${'hours'.tr}",
                                  iconColor: AppThemeData.secondary200,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Iconsax.car,
                                  label: 'vehicle_type'.tr,
                                  value: vehicleName,
                                  iconColor: AppThemeData.primary200,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      btnName:
                          "${'continue_to_payment'.tr} ${Constant().amountShow(amount: totalPrice.toStringAsFixed(2))}",
                      ontap: () {
                        Get.to(() => LimousinePaymentScreen(
                              bookingId: bookingId,
                              totalPrice: totalPrice,
                              vehicleName: vehicleName,
                              durationHours: durationHours,
                              startDate: startDate,
                              startTime: startTime,
                            ));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}