import 'package:cabme/common/widget/custom_app_bar.dart';
import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/core/constant/constant.dart';
import 'package:cabme/features/ride/ride/controller/scheduled_ride_controller.dart';
import 'package:cabme/features/ride/ride/controller/new_ride_controller.dart';
import 'package:cabme/features/ride/ride/model/ride_model.dart';
import 'package:cabme/features/ride/ride/view/new_ride_screen.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ScheduledRidesScreen extends StatelessWidget {
  const ScheduledRidesScreen({super.key});

  // Helper function to get localized filter display name
  String _getFilterDisplayName(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return 'all'.tr;
      case 'new':
        return 'new'.tr;
      case 'confirmed':
        return 'confirmed'.tr;
      case 'on ride':
      case 'onride':
        return 'on_ride'.tr;
      case 'completed':
        return 'completed'.tr;
      case 'rejected':
        return 'rejected'.tr;
      case 'cancelled':
        return 'cancelled'.tr;
      case 'pending':
        return 'pending'.tr;
      case 'scheduled':
        return 'scheduled'.tr;
      default:
        return filter.capitalizeFirst ?? filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder<ScheduledRideController>(
      init: ScheduledRideController(),
      builder: (controller) {
        return WillPopScope(
          onWillPop: () async {
            Get.back();
            return false;
          },
          child: Scaffold(
            appBar: CustomAppBar(
              title: 'Scheduled Rides'.tr,
              showBackButton: true,
              onBackPressed: () => Get.back(),
            ),
            body: RefreshIndicator(
              onRefresh: () => controller.getScheduledRides(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    // Filter Tabs - same as driver app
                    _buildFilterTabs(controller, themeChange.getThem()),
                    const SizedBox(height: 12),
                    Expanded(
                      child: controller.isLoading.value
                          ? const Center(child: CircularProgressIndicator())
                          : controller.filteredRideList.isEmpty
                              ? SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.6,
                                    child: Constant.emptyView(
                                        context,
                                        controller.selectedFilter.value == 'all'
                                            ? "You don't have any scheduled rides."
                                                .tr
                                            : "${'No'.tr} ${_getFilterDisplayName(controller.selectedFilter.value)} ${'rides found.'.tr}",
                                        controller.selectedFilter.value ==
                                            'all'),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: controller.filteredRideList.length,
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: scheduledRideWidget(
                                          controller,
                                          context,
                                          controller.filteredRideList[index]),
                                    );
                                  }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterTabs(ScheduledRideController controller, bool isDarkMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ScheduledRideController.filterOptions.map((filter) {
          final isSelected = controller.selectedFilter.value == filter;
          final displayName = _getFilterDisplayName(filter);

          final count = controller.getStatusCount(filter);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => controller.setFilter(filter),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppThemeData.primary200
                      : isDarkMode
                          ? AppThemeData.grey800
                          : AppThemeData.grey100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppThemeData.primary200
                        : isDarkMode
                            ? AppThemeData.grey300Dark
                            : AppThemeData.grey300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: displayName,
                      size: 13,
                      color: isSelected
                          ? Colors.white
                          : isDarkMode
                              ? AppThemeData.grey300Dark
                              : AppThemeData.grey800,
                      weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : isDarkMode
                                  ? AppThemeData.grey300Dark
                                  : AppThemeData.grey200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomText(
                          text: count.toString(),
                          size: 11,
                          color: isSelected
                              ? Colors.white
                              : isDarkMode
                                  ? AppThemeData.grey400Dark
                                  : AppThemeData.grey400,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget scheduledRideWidget(
    ScheduledRideController controller,
    BuildContext context,
    RideData data,
  ) {
    final newRideController = Get.put(NewRideController());

    // Parse scheduled date and time
    String scheduledDate = '';
    String scheduledTime = '';
    if (data.rideDate != null && data.rideTime != null) {
      try {
        DateTime scheduledDateObj = DateTime.parse(data.rideDate.toString());
        List<String> timeParts = data.rideTime.toString().split(':');
        if (timeParts.length >= 2) {
          scheduledDate = DateFormat('MMM dd, yyyy').format(scheduledDateObj);
          scheduledTime = DateFormat('hh:mm a')
              .format(DateFormat('HH:mm:ss').parse(data.rideTime.toString()));
        }
      } catch (e) {
        scheduledDate = data.rideDate?.toString() ?? 'n_a'.tr;
        scheduledTime = data.rideTime?.toString() ?? 'n_a'.tr;
      }
    }

    // Use the same widget from NewRideScreen but wrap it with schedule info
    return Column(
      children: [
        // Schedule Badge Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppThemeData.primary200.withOpacity(0.15),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border(
              bottom: BorderSide(
                color: AppThemeData.primary200.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.calendar_1,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    CustomText(
                      text: 'SCHEDULED'.tr,
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (scheduledDate.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Iconsax.calendar_1,
                            size: 14,
                            color: AppThemeData.primary200,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: CustomText(
                              text: scheduledDate,
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppThemeData.primary200,
                            ),
                          ),
                        ],
                      ),
                    if (scheduledTime.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.clock,
                              size: 14,
                              color: AppThemeData.primary200,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: CustomText(
                                text: scheduledTime,
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppThemeData.primary200,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Use the same ride widget from NewRideScreen
        NewRideScreen.newRideWidgets(newRideController, context, data),
      ],
    );
  }
}
