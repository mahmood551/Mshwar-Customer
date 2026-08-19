import 'dart:developer';
import 'package:cabme/common/widget/my_custom_dialog.dart';
import 'package:cabme/common/widget/light_bordered_card.dart';
import 'package:cabme/common/widget/custom_app_bar.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/utils/Preferences.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:cabme/features/authentication/view/login_screen.dart';
import 'package:cabme/features/home/controller/dash_board_controller.dart';
import 'package:cabme/features/settings/localization/view/localization_screen.dart';
import 'package:cabme/features/settings/profile/view/change_password_screen.dart';
import 'package:cabme/features/settings/profile/view/my_profile_screen.dart';
import 'package:cabme/features/settings/privacy_policy/view/privacy_policy_screen.dart';
import 'package:cabme/features/settings/terms_service/view/terms_of_service_screen.dart';
import 'package:cabme/features/settings/contact_us/view/contact_us_screen.dart';
import 'package:cabme/features/ride/ride/view/new_ride_screen.dart';
import 'package:cabme/features/ride/ride/view/scheduled_rides_screen.dart';
import 'package:cabme/features/payment/wallet/view/wallet_screen.dart';
import 'package:cabme/features/settings/notifications/view/notification_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final dashboardController = Get.put(DashBoardController());
  final InAppReview inAppReview = InAppReview.instance;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: CustomAppBar(
        title: 'Settings'.tr,
        showBackButton: true,
        onBackPressed: () => Get.back(),
      ),
      body: GetBuilder<DashBoardController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // User Profile Section
                _buildUserProfile(context, controller, isDarkMode),
                const SizedBox(height: 16),

                // Ride Management Section
                _buildSectionHeader('Ride Management'.tr, isDarkMode),
                const SizedBox(height: 8),
                LightBorderedCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context: context,
                        title: 'All Rides'.tr,
                        icon: Iconsax.driving,
                        isDarkMode: isDarkMode,
                        onTap: () => Get.to(() => const NewRideScreen()),
                      ),
                      _buildDivider(isDarkMode),
                      _buildMenuItem(
                        context: context,
                        title: 'Scheduled Rides'.tr,
                        icon: Iconsax.calendar,
                        isDarkMode: isDarkMode,
                        onTap: () => Get.to(() => const ScheduledRidesScreen()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Account & Payments Section
                _buildSectionHeader('Account & Payments'.tr, isDarkMode),
                const SizedBox(height: 8),
                LightBorderedCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context: context,
                        title: 'Wallet'.tr,
                        icon: Iconsax.wallet_3,
                        isDarkMode: isDarkMode,
                        onTap: () => Get.to(() => WalletScreen()),
                      ),
                      _buildDivider(isDarkMode),
                      _buildMenuItem(
                        context: context,
                        title: 'My Profile'.tr,
                        icon: Iconsax.profile_circle,
                        isDarkMode: isDarkMode,
                        onTap: () => Get.to(() => MyProfileScreen()),
                      ),
                      _buildDivider(isDarkMode),
                      _buildMenuItem(
                        context: context,
                        title: 'Change Password'.tr,
                        icon: Iconsax.lock,
                        isDarkMode: isDarkMode,
                        onTap: () => Get.to(() => ChangePasswordScreen()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // App Settings Section
                _buildSectionHeader('App Settings'.tr, isDarkMode),
                const SizedBox(height: 8),
                LightBorderedCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context: context,
                        title: 'Notifications'.tr,
                        icon: Iconsax.notification,
                        isDarkMode: isDarkMode,
                        onTap: () => Get.to(() => const NotificationScreen()),
                      ),
                      _buildDivider(isDarkMode),
                      _buildMenuItem(
                        context: context,
                        title: 'Change Language'.tr,
                        icon: Iconsax.language_square,
                        isDarkMode: isDarkMode,
                        onTap: () => Get.to(() =>
                            const LocalizationScreens(intentType: "dashBoard")),
                      ),
                      _buildDivider(isDarkMode),
                      _buildDarkModeToggle(context, isDarkMode, themeChange),
                      _buildDivider(isDarkMode),
                      _buildMenuItem(
                        context: context,
                        title: 'Terms & Conditions'.tr,
                        icon: Iconsax.document_text,
                        isDarkMode: isDarkMode,
                        onTap: () => Get.to(() => const TermsOfServiceScreen()),
                      ),
                      _buildDivider(isDarkMode),
                      _buildMenuItem(
                        context: context,
                        title: 'Privacy & Policy'.tr,
                        icon: Iconsax.shield_security,
                        isDarkMode: isDarkMode,
                        onTap: () => Get.to(() => const PrivacyPolicyScreen()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Feedback & Support Section
                _buildSectionHeader('Feedback & Support'.tr, isDarkMode),
                const SizedBox(height: 8),
                LightBorderedCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context: context,
                        title: 'Contact Us'.tr,
                        icon: Iconsax.message,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          Get.to(() => const ContactUsScreen());
                        },
                      ),
                      _buildDivider(isDarkMode),
                      _buildMenuItem(
                        context: context,
                        title: 'Rate the App'.tr,
                        icon: Iconsax.star_1,
                        isDarkMode: isDarkMode,
                        onTap: () async {
                          try {
                            if (await inAppReview.isAvailable()) {
                              inAppReview.requestReview();
                            } else {
                              log(":::::::::InAppReview:::::::::::");
                              inAppReview.openStoreListing();
                            }
                          } catch (e) {
                            log("Error triggering in-app review: $e");
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Logout
                LightBorderedCard(
                  margin: EdgeInsets.zero,
                  child: _buildMenuItem(
                    context: context,
                    title: 'Log Out'.tr,
                    icon: Iconsax.logout_1,
                    isDarkMode: isDarkMode,
                    textColor: AppThemeData.error200,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserProfile(
      BuildContext context, DashBoardController controller, bool isDarkMode) {
    return LightBorderedCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildProfileImage(controller, isDarkMode),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${controller.userModel?.data?.prenom ?? ''} ${controller.userModel?.data?.nom ?? ''}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'pop',
                    color: isDarkMode
                        ? AppThemeData.grey900Dark
                        : AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (controller.userModel?.data?.email != null &&
                          controller.userModel!.data!.email!.isNotEmpty &&
                          controller.userModel!.data!.email != 'null')
                      ? controller.userModel!.data!.email!
                      : (controller.userModel?.data?.phone != null &&
                              controller.userModel!.data!.phone!.isNotEmpty &&
                              controller.userModel!.data!.phone != 'null')
                          ? controller.userModel!.data!.phone!
                          : '',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'pop',
                    color: isDarkMode
                        ? AppThemeData.grey400Dark
                        : AppThemeData.grey500,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Get.to(() => MyProfileScreen()),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppThemeData.primary50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Iconsax.edit_2,
                size: 20,
                color: AppThemeData.primary200,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'pop',
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 56,
      color: isDarkMode ? AppThemeData.grey200Dark : AppThemeData.grey200,
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isDarkMode,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final iconColor = textColor ??
        (isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppThemeData.primary200).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: 'pop',
          color: textColor ??
              (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
        ),
      ),
      trailing: Icon(
        Iconsax.arrow_right_3,
        size: 18,
        color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey400,
      ),
    );
  }

  Widget _buildDarkModeToggle(
      BuildContext context, bool isDarkMode, DarkThemeProvider themeChange) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppThemeData.primary200.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isDarkMode ? Iconsax.moon : Iconsax.sun_1,
          size: 20,
          color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
        ),
      ),
      title: Text(
        'Dark Mode'.tr,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: 'pop',
          color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
        ),
      ),
      trailing: Switch(
        value: isDarkMode,
        activeThumbColor: AppThemeData.primary200,
        onChanged: (value) {
          themeChange.darkTheme = value ? 0 : 1;
        },
      ),
    );
  }

  Widget _buildProfileImage(DashBoardController controller, bool isDarkMode) {
    final photoPath = controller.userModel?.data?.photoPath?.toString() ?? '';

    if (photoPath.isEmpty || photoPath == 'null') {
      return Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: AppThemeData.grey200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Iconsax.user,
          size: 32,
          color: AppThemeData.grey400,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: photoPath,
      height: 64,
      width: 64,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: AppThemeData.grey200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppThemeData.primary200,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: AppThemeData.grey200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Iconsax.user,
          size: 32,
          color: AppThemeData.grey400,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    MyCustomDialog.show(
      context: context,
      title: 'Log Out'.tr,
      message: 'Are you sure you want to log out?'.tr,
      confirmText: 'Log Out'.tr,
      cancelText: 'Cancel'.tr,
      confirmButtonColor: AppThemeData.error200,
      onConfirm: () {
        Preferences.clearKeyData(Preferences.isLogin);
        Preferences.clearKeyData(Preferences.user);
        Preferences.clearKeyData(Preferences.userId);
        Get.offAll(() => const LoginScreen());
      },
    );
  }
}
