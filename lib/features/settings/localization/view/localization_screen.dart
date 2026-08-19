import 'package:cabme/core/constant/show_toast_dialog.dart';
import 'package:cabme/features/home/controller/dash_board_controller.dart';
import 'package:cabme/features/settings/localization/controller/localization_controller.dart';
import 'package:cabme/features/authentication/view/login_screen.dart';
import 'package:cabme/features/splash/splash_screen.dart';
import 'package:cabme/service/localization_service.dart';
import 'package:cabme/common/widget/button.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/themes/responsive.dart';
import 'package:cabme/core/utils/Preferences.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:cabme/common/widget/custom_app_bar.dart';
import 'package:cabme/common/widget/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class LocalizationScreens extends StatelessWidget {
  final String intentType;

  const LocalizationScreens({super.key, required this.intentType});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<LocalizationController>(
      init: LocalizationController(),
      builder: (controller) {
        return Scaffold(
          appBar: CustomAppBar(
            title: 'change_language'.tr,
            actions: intentType != "dashBoard"
                ? [
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        final langCode = controller.selectedLanguage.value;
                        LocalizationService().changeLocale(langCode);
                        Preferences.setString(
                            Preferences.languageCodeKey, langCode);
                        if (intentType == "dashBoard") {
                          ShowToastDialog.showToast(
                              "language_change_successfully".tr);
                          Get.forceAppUpdate();
                        } else {
                          Get.offAll(const LoginScreen(),
                              transition: Transition.rightToLeft);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: CustomText(
                          text: 'skip'.tr,
                          size: 16,
                          decoration: TextDecoration.underline,
                          decorationColor: AppThemeData.secondary200,
                          color: AppThemeData.secondary200,
                        ),
                      ),
                    ),
                  ]
                : null,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 6),
                  child: CustomText(
                    text: 'select_language'.tr,
                    size: 22,
                    weight: FontWeight.w600,
                    color: themeChange.getThem()
                        ? AppThemeData.grey900Dark
                        : AppThemeData.grey900,
                  ),
                ),
                CustomText(
                  text: 'choose_language_desc'.tr,
                  size: 16,
                  color: themeChange.getThem()
                      ? AppThemeData.grey900Dark
                      : AppThemeData.grey900,
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) {
                      return Container(
                        height: 0.6,
                        color: themeChange.getThem()
                            ? AppThemeData.grey300Dark
                            : AppThemeData.grey100,
                      );
                    },
                    itemCount: controller.languageList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Obx(
                        () => InkWell(
                          splashColor: Colors.transparent,
                          onTap: () {
                            controller.selectedLanguage.value =
                                controller.languageList[index].code.toString();
                            print(
                                'Selected Language code: ${controller.selectedLanguage.value}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 16,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Image.network(
                                              controller
                                                  .languageList[index].flag
                                                  .toString(),
                                              height: 35,
                                              width: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Align(
                                              alignment: Alignment.bottomRight,
                                              child: CustomText(
                                                text: controller
                                                    .languageList[index]
                                                    .language
                                                    .toString(),
                                                size: 16,
                                                weight: FontWeight.w500,
                                                color: themeChange.getThem()
                                                    ? AppThemeData.grey900Dark
                                                    : AppThemeData.grey900,
                                              ))
                                        ],
                                      ),
                                    ),
                                    controller.languageList[index].code ==
                                            controller.selectedLanguage.value
                                        ? SvgPicture.asset(
                                            "assets/icons/ic_radio_selected.svg",
                                            color: AppThemeData.primary200,
                                            // colorFilter: ColorFilter.mode(
                                            //   themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                            //   BlendMode.srcIn,
                                            // ),
                                          )
                                        : SvgPicture.asset(
                                            "assets/icons/ic_radio_unselected.svg",
                                            color: AppThemeData.primary200,
                                            // colorFilter: ColorFilter.mode(
                                            //   themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                            //   BlendMode.srcIn,
                                            // ),
                                          )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Visibility(
                  visible: intentType != "dashBoard",
                  child: SizedBox(
                    width: Responsive.width(100, context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CustomText(
                        text: 'skip_desc'.tr,
                        align: TextAlign.center,
                        size: 16,
                        weight: FontWeight.w300,
                        color: themeChange.getThem()
                            ? AppThemeData.grey300Dark
                            : AppThemeData.grey400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: CustomButton(
              btnName: intentType == "dashBoard" ? 'save'.tr : 'continue'.tr,
              textColor: Colors.white,
              borderRadius: 12,
              ontap: () async {
                final langCode = controller.selectedLanguage.value;
                await Preferences.setString(
                    Preferences.languageCodeKey, langCode);
                LocalizationService().changeLocale(langCode);
                if (intentType == "dashBoard") {
                  ShowToastDialog.showToast("language_change_successfully".tr);
                  // Refresh drawer items with new language
                  if (Get.isRegistered<DashBoardController>()) {
                    Get.find<DashBoardController>().getDrawerItems();
                  }
                  // Restart app to apply RTL/LTR changes properly
                  Get.offAll(const SplashScreen());
                } else {
                  Get.offAll(const LoginScreen());
                }
              },
            ),
          ),
        );
      },
    );
  }
}
