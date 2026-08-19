// import 'package:cabme/common/widget/button.dart';
// import 'package:cabme/common/widget/custom_app_bar.dart';
// import 'package:cabme/common/widget/custom_text.dart';
// import 'package:cabme/common/widget/light_bordered_card.dart';
// import 'package:cabme/core/constant/constant.dart';
// import 'package:cabme/core/themes/constant_colors.dart';
// import 'package:cabme/core/themes/radio_button.dart';
// import 'package:cabme/core/utils/dark_theme_provider.dart';
// import 'package:cabme/features/home/controller/home_controller.dart';
// import 'package:cabme/features/home/model/driver_model.dart';
// import 'package:cabme/features/home/model/vehicle_category_model.dart';
// import 'package:cabme/features/payment/payment/controller/payment_controller.dart';
// import 'package:cabme/common/widget/modern_datetime_picker.dart';
// import 'package:cabme/core/constant/show_toast_dialog.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:provider/provider.dart';

// class RidePaymentSelectionScreen extends StatefulWidget {
//   final VehicleCategoryModel vehicleCategoryModel;
//   final double tripPrice;
//   final double originalTripPrice;
//   final DriverData driverData;
//   final bool isSchedule;
//   final DateTime? scheduleDateTime;
//   final String? discountCode;
//   final double? discountAmount;
//   final HomeController homeController;

//   const RidePaymentSelectionScreen({
//     super.key,
//     required this.vehicleCategoryModel,
//     required this.tripPrice,
//     required this.originalTripPrice,
//     required this.driverData,
//     required this.isSchedule,
//     this.scheduleDateTime,
//     this.discountCode,
//     this.discountAmount,
//     required this.homeController, required double limousineAmount, required String limousineVehicleName, required int limousineDurationHours, required int limousineBookingId, required bool isLimousine, required String limousineStartDate, required String limousineStartTime,
//   });

//   @override
//   State<RidePaymentSelectionScreen> createState() =>
//       _RidePaymentSelectionScreenState();
// }

// class _RidePaymentSelectionScreenState
//     extends State<RidePaymentSelectionScreen> {
//   final PaymentController paymentCtrl = Get.find<PaymentController>();
//   final HomeController controller = Get.find<HomeController>();

//   @override
//   void initState() {
//     super.initState();
//     _initializeWalletAmount();
//   }

//   Future<void> _initializeWalletAmount() async {
//     try {
//       if (paymentCtrl.walletAmount.value == "0.0" ||
//           paymentCtrl.walletAmount.value == "0" ||
//           paymentCtrl.walletAmount.value.isEmpty) {
//         await paymentCtrl.getAmount();
//       }
//     } catch (e) {
//       await paymentCtrl.getAmount();
//     }
//   }

//   void _handlePaymentMethodSelection({
//     required String value,
//     required String method,
//     required String paymentId,
//   }) {
//     // Update HomeController boolean flags FIRST for instant UI update
//     controller.cash.value = (method == 'cash');
//     controller.wallet.value = (method == 'wallet');
//     controller.uPayments.value = (method == 'upayments');

//     // Use controller method to select payment method
//     final result = paymentCtrl.selectPaymentMethod(
//       method: method,
//       paymentId: paymentId,
//     );

//     // Update HomeController payment method type and ID
//     controller.paymentMethodType.value = result['paymentMethodType'] ?? value;
//     controller.paymentMethodId.value = result['paymentMethodId'] ?? paymentId;
//   }

//   Future<void> _handleBookRide() async {
//     // Check if package is selected
//     final isPackageSelected = controller.usePackage.value &&
//         controller.selectedUserPackage.value != null;

//     // If package is selected and tripPrice is 0, no payment needed
//     // If package is selected and tripPrice > 0, payment method is required for extra amount
//     // If no package, payment method is always required
//     if (!isPackageSelected || widget.tripPrice > 0) {
//       // Validate payment method is selected
//       // For UPayments, paymentMethodId might be empty but paymentMethodType should be set
//       if (controller.paymentMethodType.value == 'select_method' ||
//           (controller.paymentMethodId.value.isEmpty &&
//               controller.paymentMethodType.value !=
//                   'knet_credit_card_others')) {
//         ShowToastDialog.showToast('please_select_payment_method'.tr);
//         return;
//       }
//     }

//     DateTime? finalScheduleDateTime = widget.scheduleDateTime;

//     // If scheduling but no date/time selected, prompt user
//     if (widget.isSchedule && finalScheduleDateTime == null) {
//       finalScheduleDateTime = await ModernDateTimePicker.show(context);
//       if (finalScheduleDateTime == null) {
//         ShowToastDialog.showToast('please_select_date_time'.tr);
//         return;
//       }
//     }

//     // Use controller method to process booking
//     await controller.processRideBooking(
//       driverData: widget.driverData,
//       tripPrice: widget.tripPrice,
//       isSchedule: widget.isSchedule,
//       scheduleDateTime: finalScheduleDateTime,
//       discountCode: widget.discountCode,
//       discountAmount: widget.discountAmount,
//       context: context,
//     );
//   }

//   Widget _buildPaymentMethodSection(bool isDarkMode) {
//     // Wrap in Obx to make it reactive - updates instantly when payment method changes
//     return Obx(() => LightBorderedCard(
//           margin: EdgeInsets.zero,
//           child: Column(
//             children: [
//               // Cash - Only show if enabled by admin
//               if (controller.paymentSettingModel.value.cash != null &&
//                   controller.paymentSettingModel.value.cash?.isEnabled ==
//                       "true")
//                 RadioButtonCustom(
//                   image: "assets/icons/cash.png",
//                   name: 'cash'.tr,
//                   groupValue: controller.paymentMethodType.value,
//                   isEnabled: true,
//                   isSelected: controller.cash.value,
//                   onClick: (String? value) {
//                     _handlePaymentMethodSelection(
//                       value: value!,
//                       method: 'cash',
//                       paymentId: controller
//                               .paymentSettingModel.value.cash?.idPaymentMethod
//                               .toString() ??
//                           '',
//                     );
//                   },
//                 ),
//               // Wallet - Only show if enabled by admin
//               if (controller.paymentSettingModel.value.myWallet != null &&
//                   controller.paymentSettingModel.value.myWallet?.isEnabled ==
//                       "true") ...[
//                 Divider(
//                   height: 1,
//                   thickness: 1,
//                   color: isDarkMode
//                       ? AppThemeData.grey300Dark.withOpacity(0.3)
//                       : AppThemeData.grey300.withOpacity(0.3),
//                 ),
//                 RadioButtonCustom(
//                   subName: Constant().amountShow(
//                     amount: (paymentCtrl.walletAmount.value.isEmpty ||
//                             paymentCtrl.walletAmount.value == "0" ||
//                             paymentCtrl.walletAmount.value == "0.0")
//                         ? "0.0"
//                         : paymentCtrl.walletAmount.value,
//                   ),
//                   image: "assets/icons/walltet_icons.png",
//                   name: 'wallet'.tr,
//                   groupValue: controller.paymentMethodType.value,
//                   isEnabled: true,
//                   isSelected: controller.wallet.value,
//                   onClick: (String? value) {
//                     _handlePaymentMethodSelection(
//                       value: value!,
//                       method: 'wallet',
//                       paymentId: controller.paymentSettingModel.value.myWallet
//                               ?.idPaymentMethod
//                               .toString() ??
//                           '',
//                     );
//                   },
//                 ),
//               ],
//               // KNET (UPayments) - Only show if enabled by admin
//               if (controller.paymentSettingModel.value.uPayments != null &&
//                   controller.paymentSettingModel.value.uPayments?.isEnabled ==
//                       "true") ...[
//                 Divider(
//                   height: 1,
//                   thickness: 1,
//                   color: isDarkMode
//                       ? AppThemeData.grey300Dark.withOpacity(0.3)
//                       : AppThemeData.grey300.withOpacity(0.3),
//                 ),
//                 RadioButtonCustom(
//                   isEnabled: true,
//                   name: 'knet_credit_card_others'.tr,
//                   image: "assets/icons/upayments.jpeg",
//                   isSelected: controller.uPayments.value,
//                   groupValue: controller.paymentMethodType.value,
//                   onClick: (String? value) {
//                     _handlePaymentMethodSelection(
//                       value: value!,
//                       method: 'upayments',
//                       paymentId: controller.paymentSettingModel.value.uPayments
//                               ?.idPaymentMethod
//                               .toString() ??
//                           '8', // Default UPayments ID if not set in payment settings
//                     );
//                   },
//                 ),
//               ],
//             ],
//           ),
//         ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     final isDarkMode = themeChange.getThem();

//     return Scaffold(
//       backgroundColor:
//           isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
//       appBar: CustomAppBar(
//         title: 'select_payment_method'.tr,
//         showBackButton: true,
//         onBackPressed: () {
//           Get.back();
//         },
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Price Summary at top
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//               child: LightBorderedCard(
//                 margin: EdgeInsets.zero,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         CustomText(
//                           text: 'total_amount'.tr,
//                           size: 13,
//                           weight: FontWeight.w500,
//                           color: isDarkMode
//                               ? AppThemeData.grey500Dark
//                               : AppThemeData.grey500,
//                         ),
//                         const SizedBox(height: 6),
//                         CustomText(
//                           text: Constant().amountShow(
//                               amount: widget.tripPrice.toStringAsFixed(2)),
//                           size: 24,
//                           weight: FontWeight.w800,
//                           color: AppThemeData.primary200,
//                         ),
//                       ],
//                     ),
//                     if (widget.discountAmount != null &&
//                         widget.discountAmount! > 0)
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppThemeData.success300.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(
//                             color: AppThemeData.success300.withOpacity(0.3),
//                             width: 1,
//                           ),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   Iconsax.ticket_discount,
//                                   size: 14,
//                                   color: AppThemeData.success300,
//                                 ),
//                                 const SizedBox(width: 4),
//                                 CustomText(
//                                   text: 'discount'.tr,
//                                   size: 11,
//                                   weight: FontWeight.w500,
//                                   color: AppThemeData.success300,
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 2),
//                             CustomText(
//                               text: Constant().amountShow(
//                                   amount: widget.discountAmount!
//                                       .toStringAsFixed(2)),
//                               size: 14,
//                               weight: FontWeight.w700,
//                               color: AppThemeData.success300,
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             // Payment Methods
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CustomText(
//                       text: 'choose_payment_method'.tr,
//                       size: 18,
//                       weight: FontWeight.w600,
//                       color: isDarkMode
//                           ? AppThemeData.grey900Dark
//                           : AppThemeData.grey900,
//                     ),
//                     const SizedBox(height: 16),
//                     _buildPaymentMethodSection(isDarkMode),
//                   ],
//                 ),
//               ),
//             ),
//             // Bottom Button
//             Container(
//               padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
//               decoration: BoxDecoration(
//                 color: isDarkMode
//                     ? AppThemeData.surface50Dark
//                     : AppThemeData.surface50,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 20,
//                     offset: const Offset(0, -4),
//                   ),
//                 ],
//               ),
//               child: SafeArea(
//                 top: false,
//                 child: GetBuilder<PaymentController>(
//                   builder: (paymentController) =>
//                       paymentController.paymentLoader != true
//                           ? CustomButton(
//                               btnName: widget.isSchedule
//                                   ? "${'schedule_ride'.tr} ${Constant().amountShow(amount: widget.tripPrice.toStringAsFixed(2))}"
//                                   : "${'confirm_pay'.tr} ${Constant().amountShow(amount: widget.tripPrice.toStringAsFixed(2))}",
//                               ontap: () => _handleBookRide(),
//                             )
//                           : const Center(
//                               child: CircularProgressIndicator(),
//                             ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'dart:convert';
import 'package:cabme/common/widget/button.dart';
import 'package:cabme/common/widget/custom_app_bar.dart';
import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/common/widget/light_bordered_card.dart';
import 'package:cabme/core/constant/constant.dart';
import 'package:cabme/core/constant/show_toast_dialog.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/themes/radio_button.dart';
import 'package:cabme/core/utils/Preferences.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:cabme/features/home/controller/home_controller.dart';
import 'package:cabme/features/home/model/driver_model.dart';
import 'package:cabme/features/home/model/vehicle_category_model.dart';
import 'package:cabme/features/home/view/sucess_screen.dart';
import 'package:cabme/features/payment/payment/controller/payment_controller.dart';
import 'package:cabme/features/payment/payment/view/payment_webview.dart';
import 'package:cabme/common/widget/modern_datetime_picker.dart';
import 'package:cabme/service/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class RidePaymentSelectionScreen extends StatefulWidget {
  // ===== Original (Classic/Family) fields — now optional =====
  final VehicleCategoryModel? vehicleCategoryModel;
  final double? tripPrice;
  final double? originalTripPrice;
  final DriverData? driverData;
  final bool isSchedule;
  final DateTime? scheduleDateTime;
  final String? discountCode;
  final double? discountAmount;
  final HomeController? homeController;

  // ===== Limousine fields =====
  final bool isLimousine;
  final int? limousineBookingId;
  final double? limousineAmount;
  final String? limousineVehicleName;
  final int? limousineDurationHours;
  final String? limousineStartDate;
  final String? limousineStartTime;

  const RidePaymentSelectionScreen({
    super.key,
    this.vehicleCategoryModel,
    this.tripPrice,
    this.originalTripPrice,
    this.driverData,
    this.isSchedule = false,
    this.scheduleDateTime,
    this.discountCode,
    this.discountAmount,
    this.homeController,
    this.isLimousine = false,
    this.limousineBookingId,
    this.limousineAmount,
    this.limousineVehicleName,
    this.limousineDurationHours,
    this.limousineStartDate,
    this.limousineStartTime,
  });

  @override
  State<RidePaymentSelectionScreen> createState() =>
      _RidePaymentSelectionScreenState();
}

class _RidePaymentSelectionScreenState
    extends State<RidePaymentSelectionScreen> {
  final PaymentController paymentCtrl = Get.find<PaymentController>();
  HomeController? controller;

  // Limousine-only local state (لأننا مش هنلمس HomeController في وضع الليموزين)
  String limousineSelectedMethod = '';
  bool limousineLoading = false;

  double get displayPrice =>
      widget.isLimousine ? (widget.limousineAmount ?? 0) : (widget.tripPrice ?? 0);

  @override
  void initState() {
    super.initState();
    if (!widget.isLimousine) {
      controller = widget.homeController ?? Get.find<HomeController>();
    }
    _initializeWalletAmount();
  }

  Future<void> _initializeWalletAmount() async {
    try {
      if (paymentCtrl.walletAmount.value == "0.0" ||
          paymentCtrl.walletAmount.value == "0" ||
          paymentCtrl.walletAmount.value.isEmpty) {
        await paymentCtrl.getAmount();
      }
    } catch (e) {
      await paymentCtrl.getAmount();
    }
  }

  // ========================================================
  // ============ ORIGINAL CLASSIC/FAMILY LOGIC ============
  // ========================================================
  void _handlePaymentMethodSelection({
    required String value,
    required String method,
    required String paymentId,
  }) {
    controller!.cash.value = (method == 'cash');
    controller!.wallet.value = (method == 'wallet');
    controller!.uPayments.value = (method == 'upayments');

    final result = paymentCtrl.selectPaymentMethod(
      method: method,
      paymentId: paymentId,
    );

    controller!.paymentMethodType.value = result['paymentMethodType'] ?? value;
    controller!.paymentMethodId.value = result['paymentMethodId'] ?? paymentId;
  }

  Future<void> _handleBookRide() async {
    final isPackageSelected = controller!.usePackage.value &&
        controller!.selectedUserPackage.value != null;

    if (!isPackageSelected || (widget.tripPrice ?? 0) > 0) {
      if (controller!.paymentMethodType.value == 'select_method' ||
          (controller!.paymentMethodId.value.isEmpty &&
              controller!.paymentMethodType.value != 'knet_credit_card_others')) {
        ShowToastDialog.showToast('please_select_payment_method'.tr);
        return;
      }
    }

    DateTime? finalScheduleDateTime = widget.scheduleDateTime;

    if (widget.isSchedule && finalScheduleDateTime == null) {
      finalScheduleDateTime = await ModernDateTimePicker.show(context);
      if (finalScheduleDateTime == null) {
        ShowToastDialog.showToast('please_select_date_time'.tr);
        return;
      }
    }

    await controller!.processRideBooking(
      driverData: widget.driverData!,
      tripPrice: widget.tripPrice ?? 0,
      isSchedule: widget.isSchedule,
      scheduleDateTime: finalScheduleDateTime,
      discountCode: widget.discountCode,
      discountAmount: widget.discountAmount,
      context: context,
    );
  }

  Widget _buildPaymentMethodSection(bool isDarkMode) {
    return Obx(() => LightBorderedCard(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              if (controller!.paymentSettingModel.value.cash != null &&
                  controller!.paymentSettingModel.value.cash?.isEnabled == "true")
                RadioButtonCustom(
                  image: "assets/icons/cash.png",
                  name: 'cash'.tr,
                  groupValue: controller!.paymentMethodType.value,
                  isEnabled: true,
                  isSelected: controller!.cash.value,
                  onClick: (String? value) {
                    _handlePaymentMethodSelection(
                      value: value!,
                      method: 'cash',
                      paymentId: controller!.paymentSettingModel.value.cash
                              ?.idPaymentMethod.toString() ?? '',
                    );
                  },
                ),
              if (controller!.paymentSettingModel.value.myWallet != null &&
                  controller!.paymentSettingModel.value.myWallet?.isEnabled ==
                      "true") ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDarkMode
                      ? AppThemeData.grey300Dark.withOpacity(0.3)
                      : AppThemeData.grey300.withOpacity(0.3),
                ),
                RadioButtonCustom(
                  subName: Constant().amountShow(
                    amount: (paymentCtrl.walletAmount.value.isEmpty ||
                            paymentCtrl.walletAmount.value == "0" ||
                            paymentCtrl.walletAmount.value == "0.0")
                        ? "0.0"
                        : paymentCtrl.walletAmount.value,
                  ),
                  image: "assets/icons/walltet_icons.png",
                  name: 'wallet'.tr,
                  groupValue: controller!.paymentMethodType.value,
                  isEnabled: true,
                  isSelected: controller!.wallet.value,
                  onClick: (String? value) {
                    _handlePaymentMethodSelection(
                      value: value!,
                      method: 'wallet',
                      paymentId: controller!.paymentSettingModel.value.myWallet
                              ?.idPaymentMethod.toString() ?? '',
                    );
                  },
                ),
              ],
              if (controller!.paymentSettingModel.value.uPayments != null &&
                  controller!.paymentSettingModel.value.uPayments?.isEnabled ==
                      "true") ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDarkMode
                      ? AppThemeData.grey300Dark.withOpacity(0.3)
                      : AppThemeData.grey300.withOpacity(0.3),
                ),
                RadioButtonCustom(
                  isEnabled: true,
                  name: 'knet_credit_card_others'.tr,
                  image: "assets/icons/upayments.jpeg",
                  isSelected: controller!.uPayments.value,
                  groupValue: controller!.paymentMethodType.value,
                  onClick: (String? value) {
                    _handlePaymentMethodSelection(
                      value: value!,
                      method: 'upayments',
                      paymentId: controller!.paymentSettingModel.value.uPayments
                              ?.idPaymentMethod.toString() ?? '8',
                    );
                  },
                ),
              ],
            ],
          ),
        ));
  }

  // ========================================================
  // ================= LIMOUSINE LOGIC ======================
  // ========================================================
  Widget _buildLimousinePaymentMethodSection(bool isDarkMode) {
    final paymentSetting = Constant.getPaymentSetting();
    return LightBorderedCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // Wallet
          if (paymentSetting.myWallet?.isEnabled == "true")
            RadioButtonCustom(
              subName: Constant().amountShow(
                amount: paymentCtrl.walletAmount.value.isEmpty
                    ? "0.0"
                    : paymentCtrl.walletAmount.value,
              ),
              image: "assets/icons/walltet_icons.png",
              name: 'wallet'.tr,
              groupValue: limousineSelectedMethod,
              isEnabled: true,
              isSelected: limousineSelectedMethod == 'wallet',
              onClick: (String? value) {
                setState(() => limousineSelectedMethod = 'wallet');
              },
            ),
          // UPayments
          if (paymentSetting.uPayments?.isEnabled == "true") ...[
            if (paymentSetting.myWallet?.isEnabled == "true")
              Divider(
                height: 1,
                thickness: 1,
                color: isDarkMode
                    ? AppThemeData.grey300Dark.withOpacity(0.3)
                    : AppThemeData.grey300.withOpacity(0.3),
              ),
            RadioButtonCustom(
              isEnabled: true,
              name: 'knet_credit_card_others'.tr,
              image: "assets/icons/upayments.jpeg",
              isSelected: limousineSelectedMethod == 'upayments',
              groupValue: limousineSelectedMethod,
              onClick: (String? value) {
                setState(() => limousineSelectedMethod = 'upayments');
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _payLimousine() async {
    if (limousineSelectedMethod.isEmpty) {
      ShowToastDialog.showToast('please_select_payment_method'.tr);
      return;
    }

    setState(() => limousineLoading = true);

    try {
      String paymethod = '';
      String transactionId =
          '${widget.limousineBookingId}_${DateTime.now().millisecondsSinceEpoch}';

      if (limousineSelectedMethod == 'wallet') {
        paymethod = 'Wallet';
        final walletBalance =
            double.tryParse(paymentCtrl.walletAmount.value) ?? 0;
        if (walletBalance < (widget.limousineAmount ?? 0)) {
          setState(() => limousineLoading = false);
          ShowToastDialog.showToast('insufficient_wallet_balance'.tr);
          return;
        }
      } else if (limousineSelectedMethod == 'upayments') {
        paymethod = 'UPayments';

        final paymentUrl = await paymentCtrl.processUPaymentsPaymentGeneric(
          amount: widget.limousineAmount ?? 0,
          productName: 'Limousine - ${widget.limousineVehicleName}',
          productDescription:
              'Limousine #${widget.limousineBookingId} | ${widget.limousineDurationHours}h',
          customerExtraData:
              'limousine_booking_id:${widget.limousineBookingId}',
        );

        if (paymentUrl == null) {
          setState(() => limousineLoading = false);
          ShowToastDialog.showToast('payment_initialization_failed'.tr);
          return;
        }

        final result = await Get.to(
          () => PaymentWebViewScreen(url: paymentUrl, title: 'payment'.tr),
        );

        if (result == null || result == false || result == 'false') {
          setState(() => limousineLoading = false);
          ShowToastDialog.showToast('payment_was_cancelled_declined'.tr);
          return;
        }

        if (result is String && result.contains('https')) {
          final uri = Uri.parse(result);
          final params = uri.queryParameters;
          final status = params['result'] ?? '';
          if (status != 'SUCCESS' && status != 'CAPTURED') {
            setState(() => limousineLoading = false);
            ShowToastDialog.showToast('payment_declined'.tr);
            return;
          }
          if ((params['transaction_id'] ?? '').isNotEmpty) {
            transactionId = params['transaction_id']!;
          }
        }
      }

      final response = await http.post(
        Uri.parse(API.limousinePayBooking),
        headers: API.header,
        body: jsonEncode({
          'booking_id': widget.limousineBookingId.toString(),
          'user_id': Preferences.getInt(Preferences.userId).toString(),
          'paymethod': paymethod,
          'payment_status': 'success',
          'transaction_id': transactionId,
        }),
      );

      setState(() => limousineLoading = false);
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['success'] == 'Success') {
        Get.offAll(() => const RideBookingSuccessScreen());
      } else {
        ShowToastDialog.showToast(body['error'] ?? 'payment_failed'.tr);
      }
    } catch (e) {
      setState(() => limousineLoading = false);
      ShowToastDialog.showToast('${'error_colon'.tr}$e');
    }
  }

  Widget _buildLimousineSummaryCard(bool isDarkMode) {
    return LightBorderedCard(
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
                text: Constant().amountShow(
                    amount: (widget.limousineAmount ?? 0).toStringAsFixed(3)),
                size: 24,
                weight: FontWeight.w800,
                color: AppThemeData.primary200,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppThemeData.primary200.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  text: widget.limousineVehicleName ?? '',
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppThemeData.primary200,
                ),
                CustomText(
                  text: "${widget.limousineDurationHours} ${'hours'.tr}",
                  size: 12,
                  color: isDarkMode
                      ? AppThemeData.grey500Dark
                      : AppThemeData.grey500,
                ),
                if ((widget.limousineStartDate ?? '').isNotEmpty)
                  CustomText(
                    text: widget.limousineStartDate!,
                    size: 11,
                    color: isDarkMode
                        ? AppThemeData.grey500Dark
                        : AppThemeData.grey500,
                  ),
                if ((widget.limousineStartTime ?? '').isNotEmpty)
                  CustomText(
                    text: widget.limousineStartTime!,
                    size: 11,
                    color: isDarkMode
                        ? AppThemeData.grey500Dark
                        : AppThemeData.grey500,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // ========================= BUILD ========================
  // ========================================================
  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: CustomAppBar(
        title: 'select_payment_method'.tr,
        showBackButton: true,
        onBackPressed: () {
          Get.back();
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Price Summary at top
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: widget.isLimousine
                  ? _buildLimousineSummaryCard(isDarkMode)
                  : LightBorderedCard(
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
                                text: Constant().amountShow(
                                    amount: (widget.tripPrice ?? 0)
                                        .toStringAsFixed(2)),
                                size: 24,
                                weight: FontWeight.w800,
                                color: AppThemeData.primary200,
                              ),
                            ],
                          ),
                          if (widget.discountAmount != null &&
                              widget.discountAmount! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppThemeData.success300.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppThemeData.success300
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.ticket_discount,
                                        size: 14,
                                        color: AppThemeData.success300,
                                      ),
                                      const SizedBox(width: 4),
                                      CustomText(
                                        text: 'discount'.tr,
                                        size: 11,
                                        weight: FontWeight.w500,
                                        color: AppThemeData.success300,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  CustomText(
                                    text: Constant().amountShow(
                                        amount: widget.discountAmount!
                                            .toStringAsFixed(2)),
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: AppThemeData.success300,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            // Payment Methods
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'choose_payment_method'.tr,
                      size: 18,
                      weight: FontWeight.w600,
                      color: isDarkMode
                          ? AppThemeData.grey900Dark
                          : AppThemeData.grey900,
                    ),
                    const SizedBox(height: 16),
                    widget.isLimousine
                        ? _buildLimousinePaymentMethodSection(isDarkMode)
                        : _buildPaymentMethodSection(isDarkMode),
                  ],
                ),
              ),
            ),
            // Bottom Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppThemeData.surface50Dark
                    : AppThemeData.surface50,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: widget.isLimousine
                    ? (limousineLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            btnName:
                                "${'confirm_pay'.tr} ${Constant().amountShow(amount: (widget.limousineAmount ?? 0).toStringAsFixed(3))}",
                            ontap: () => _payLimousine(),
                          ))
                    : GetBuilder<PaymentController>(
                        builder: (paymentController) =>
                            paymentController.paymentLoader != true
                                ? CustomButton(
                                    btnName: widget.isSchedule
                                        ? "${'schedule_ride'.tr} ${Constant().amountShow(amount: (widget.tripPrice ?? 0).toStringAsFixed(2))}"
                                        : "${'confirm_pay'.tr} ${Constant().amountShow(amount: (widget.tripPrice ?? 0).toStringAsFixed(2))}",
                                    ontap: () => _handleBookRide(),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}