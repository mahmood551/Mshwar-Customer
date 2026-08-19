import 'dart:convert';
import 'package:cabme/common/widget/button.dart';
import 'package:cabme/common/widget/custom_app_bar.dart';
import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/common/widget/light_bordered_card.dart';
import 'package:cabme/core/constant/constant.dart';
import 'package:cabme/core/constant/show_toast_dialog.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/utils/Preferences.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:cabme/features/home/view/limousine_payment_screen.dart';
import 'package:cabme/features/home/view/ride_payment_selection_screen.dart';
import 'package:cabme/service/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class LimousineBookingsScreen extends StatefulWidget {
  final bool showAsTab;
  const LimousineBookingsScreen({super.key, this.showAsTab = false});

  @override
  State<LimousineBookingsScreen> createState() =>
      _LimousineBookingsScreenState();
}

class _LimousineBookingsScreenState extends State<LimousineBookingsScreen> {
  List<dynamic> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      setState(() => isLoading = true);
      final response = await http.get(
        Uri.parse(
            '${API.limousineUserBookings}?user_id=${Preferences.getInt(Preferences.userId)}'),
        headers: API.header,
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'Success') {
        setState(() {
          bookings = body['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();

    return Scaffold(
      backgroundColor:
          isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: widget.showAsTab
          ? null
          : CustomAppBar(
              title: 'limousine_service'.tr,
              showBackButton: true,
              onBackPressed: () => Get.back(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _fetchBookings,
                ),
              ],
            ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined,
                          size: 60,
                          color: isDark
                              ? AppThemeData.grey400Dark
                              : AppThemeData.grey400),
                      const SizedBox(height: 16),
                      CustomText(
                        text: 'no_limousine_bookings'.tr,
                        size: 16,
                        color: isDark
                            ? AppThemeData.grey500Dark
                            : AppThemeData.grey500,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) =>
                        _buildBookingCard(bookings[index], isDark),
                  ),
                ),
    );
  }

  Widget _buildBookingCard(dynamic booking, bool isDark) {
    final status = booking['status']?.toString() ?? 'pending';
    final paymentStatus = booking['payment_status']?.toString();
    final isApproved = status == 'approved';
    final isPaid = paymentStatus == 'paid';
    final totalPrice =
        double.tryParse(booking['total_price']?.toString() ?? '0') ?? 0.0;

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = AppThemeData.info200;
        break;
      case 'completed':
        statusColor = AppThemeData.success300;
        break;
      case 'rejected':
        statusColor = AppThemeData.error200;
        break;
      default:
        statusColor = AppThemeData.warning200;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LightBorderedCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomText(
                      text: booking['vehicle_name']?.toString() ?? '',
                      size: 16,
                      weight: FontWeight.w700,
                      color: isDark
                          ? AppThemeData.grey900Dark
                          : AppThemeData.grey900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      text: status.tr,
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Iconsax.location, 'pick_up_location'.tr,
                  booking['pickup_location']?.toString() ?? '', isDark),
              const SizedBox(height: 8),
              _buildDetailRow(
                  Iconsax.calendar_1,
                  'start_date'.tr,
                  '${booking['start_date'] ?? ''} ${booking['start_time'] ?? ''}',
                  isDark),
              const SizedBox(height: 8),
              _buildDetailRow(Iconsax.clock, 'booking_duration'.tr,
                  '${booking['duration_hours']} ${'hours'.tr}', isDark),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: 'total_label'.tr,
                    size: 14,
                    color: isDark
                        ? AppThemeData.grey500Dark
                        : AppThemeData.grey500,
                  ),
                  CustomText(
                    text: Constant()
                        .amountShow(amount: totalPrice.toStringAsFixed(3)),
                    size: 18,
                    weight: FontWeight.w800,
                    color: AppThemeData.primary200,
                  ),
                ],
              ),

              // Pay Button
              if (isApproved && !isPaid) ...[
                const SizedBox(height: 16),
                CustomButton(
                  btnName:
                      '${'pay_now'.tr} — ${Constant().amountShow(amount: totalPrice.toStringAsFixed(3))}',
                  ontap: () async {

                        await Get.to(() => RidePaymentSelectionScreen(
      isLimousine: true,
      limousineBookingId: int.tryParse(booking['id']?.toString() ?? '0') ?? 0,
      limousineAmount: totalPrice,
      limousineVehicleName: booking['vehicle_name']?.toString() ?? '',
      limousineDurationHours:
          int.tryParse(booking['duration_hours']?.toString() ?? '8') ?? 8,
      limousineStartDate: booking['start_date']?.toString() ?? '',
      limousineStartTime: booking['start_time']?.toString() ?? '',
    ));

                    // await Get.to(() => LimousinePaymentScreen(
                    //       bookingId: int.tryParse(
                    //               booking['id']?.toString() ?? '0') ??
                    //           0,
                    //       totalPrice: totalPrice,
                    //       vehicleName:
                    //           booking['vehicle_name']?.toString() ?? '',
                    //       durationHours: int.tryParse(
                    //               booking['duration_hours']?.toString() ??
                    //                   '8') ??
                    //           8,
                    //       startDate: booking['start_date']?.toString() ?? '',
                    //       startTime: booking['start_time']?.toString() ?? '',
                    //     ));
                    _fetchBookings();
                  },
                ),
              ],

              // Paid badge
              if (isPaid) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppThemeData.success300.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppThemeData.success300.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.tick_circle,
                          size: 18, color: AppThemeData.success300),
                      const SizedBox(width: 8),
                      CustomText(
                        text: 'PAID'.tr,
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppThemeData.success300,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 16,
            color:
                isDark ? AppThemeData.grey400Dark : AppThemeData.grey500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: label,
                size: 11,
                color: isDark
                    ? AppThemeData.grey400Dark
                    : AppThemeData.grey500,
              ),
              CustomText(
                text: value,
                size: 13,
                weight: FontWeight.w500,
                color: isDark
                    ? AppThemeData.grey900Dark
                    : AppThemeData.grey900,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}