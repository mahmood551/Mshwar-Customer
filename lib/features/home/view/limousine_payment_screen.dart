import 'package:cabme/common/widget/button.dart';
import 'package:cabme/common/widget/custom_app_bar.dart';
import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/common/widget/light_bordered_card.dart';
import 'package:cabme/core/constant/constant.dart';
import 'package:cabme/core/constant/show_toast_dialog.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/themes/radio_button.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:cabme/features/home/controller/home_controller.dart';
import 'package:cabme/features/home/controller/limousine_controller.dart';
import 'package:cabme/features/home/view/sucess_screen.dart';
import 'package:cabme/features/payment/payment/controller/payment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class LimousinePaymentScreen extends StatefulWidget {
  final int bookingId;
  final double totalPrice;
  final String vehicleName;
  final int durationHours;
  final String startDate;
  final String startTime;

  const LimousinePaymentScreen({
    super.key,
    required this.bookingId,
    required this.totalPrice,
    required this.vehicleName,
    required this.durationHours,
    this.startDate = '',
    this.startTime = '',
  });

  @override
  State<LimousinePaymentScreen> createState() => _LimousinePaymentScreenState();
}

class _LimousinePaymentScreenState extends State<LimousinePaymentScreen> {
  late final PaymentController paymentCtrl;
  late final HomeController homeController;
  late final LimousineController limousineCtrl;

  bool isProcessing = false;

  @override
  void initState() {
    super.initState();

    paymentCtrl = Get.isRegistered<PaymentController>()
        ? Get.find<PaymentController>()
        : Get.put(PaymentController());

    homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    limousineCtrl = Get.isRegistered<LimousineController>()
        ? Get.find<LimousineController>()
        : Get.put(LimousineController());

    _initialize();
  }

  Future<void> _initialize() async {
    if (homeController.paymentSettingModel.value.cash == null) {
      homeController.paymentSettingModel.value = Constant.getPaymentSetting();
    }
    await paymentCtrl.getAmount();
  }

  void _selectMethod(String method) {
    setState(() {});
    homeController.cash.value = (method == 'cash');
    homeController.wallet.value = (method == 'wallet');
    homeController.uPayments.value = (method == 'upayments');
    homeController.paymentMethodType.value = method;
  }

  Future<void> _handlePay() async {
    final method = homeController.cash.value
        ? 'cash'
        : homeController.wallet.value
            ? 'wallet'
            : homeController.uPayments.value
                ? 'upayments'
                : '';

    if (method.isEmpty) {
      ShowToastDialog.showToast('please_select_payment_method'.tr);
      return;
    }

    if (method == 'wallet') {
      final balance = double.tryParse(paymentCtrl.walletAmount.value) ?? 0;
      if (balance < widget.totalPrice) {
        ShowToastDialog.showToast(
          'not_enough_balance_wallet'
              .tr
              .replaceAll('{amount1}',
                  Constant().amountShow(amount: balance.toStringAsFixed(3)))
              .replaceAll(
                  '{amount2}',
                  Constant().amountShow(
                      amount: widget.totalPrice.toStringAsFixed(3))),
        );
        return;
      }
    }

    setState(() => isProcessing = true);

    final success = await limousineCtrl.payBooking(
      bookingId: widget.bookingId,
      paymethod: method,
      paymentStatus: 'success',
      transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    setState(() => isProcessing = false);

    if (success) {
      Get.off(() => const RideBookingSuccessScreen());
      ShowToastDialog.showToast('limousine_payment_success'.tr);
    }
  }

  Widget _buildPaymentMethods(bool isDarkMode) {
    return Obx(() {
      final setting = homeController.paymentSettingModel.value;

      if (setting.cash == null &&
          setting.myWallet == null &&
          setting.uPayments == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }

      return LightBorderedCard(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            if (setting.cash?.isEnabled == "true")
              RadioButtonCustom(
                image: "assets/icons/cash.png",
                name: 'cash'.tr,
                groupValue: homeController.paymentMethodType.value,
                isEnabled: true,
                isSelected: homeController.cash.value,
                onClick: (_) => _selectMethod('cash'),
              ),

            if (setting.myWallet?.isEnabled == "true") ...[
              Divider(
                  height: 1,
                  thickness: 1,
                  color: isDarkMode
                      ? AppThemeData.grey300Dark.withOpacity(0.3)
                      : AppThemeData.grey300.withOpacity(0.3)),
              RadioButtonCustom(
                subName: Constant().amountShow(
                  amount: paymentCtrl.walletAmount.value.isEmpty
                      ? "0.0"
                      : paymentCtrl.walletAmount.value,
                ),
                image: "assets/icons/walltet_icons.png",
                name: 'wallet'.tr,
                groupValue: homeController.paymentMethodType.value,
                isEnabled: true,
                isSelected: homeController.wallet.value,
                onClick: (_) => _selectMethod('wallet'),
              ),
            ],

            if (setting.uPayments?.isEnabled == "true") ...[
              Divider(
                  height: 1,
                  thickness: 1,
                  color: isDarkMode
                      ? AppThemeData.grey300Dark.withOpacity(0.3)
                      : AppThemeData.grey300.withOpacity(0.3)),
              RadioButtonCustom(
                isEnabled: true,
                name: 'knet_credit_card_others'.tr,
                image: "assets/icons/upayments.jpeg",
                isSelected: homeController.uPayments.value,
                groupValue: homeController.paymentMethodType.value,
                onClick: (_) => _selectMethod('upayments'),
              ),
            ],
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: CustomAppBar(
        title: 'select_payment_method'.tr,
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
                          text: Constant().amountShow(
                              amount: widget.totalPrice.toStringAsFixed(3)),
                          size: 24,
                          weight: FontWeight.w800,
                          color: AppThemeData.primary200,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppThemeData.primary200.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomText(
                            text: widget.vehicleName,
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppThemeData.primary200,
                          ),
                          CustomText(
                            text: "${widget.durationHours} ${'hours'.tr}",
                            size: 12,
                            color: isDarkMode
                                ? AppThemeData.grey500Dark
                                : AppThemeData.grey500,
                          ),
                          if (widget.startDate.isNotEmpty)
                            CustomText(
                              text: widget.startDate,
                              size: 11,
                              color: isDarkMode
                                  ? AppThemeData.grey500Dark
                                  : AppThemeData.grey500,
                            ),
                          if (widget.startTime.isNotEmpty)
                            CustomText(
                              text: widget.startTime,
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
              ),
            ),

            const SizedBox(height: 24),

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
                    _buildPaymentMethods(isDarkMode),
                  ],
                ),
              ),
            ),

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
                child: isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        btnName:
                            "${'confirm_pay'.tr} ${Constant().amountShow(amount: widget.totalPrice.toStringAsFixed(3))}",
                        ontap: _handlePay,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
