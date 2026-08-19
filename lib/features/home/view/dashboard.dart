import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/common/widget/my_custom_dialog.dart';
import 'package:cabme/features/authentication/view/login_screen.dart';
import 'package:cabme/features/home/controller/dash_board_controller.dart';
import 'package:cabme/features/home/view/home_screen.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/themes/responsive.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:cabme/core/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class DashBoard extends StatelessWidget {
  DashBoard({super.key});

  DateTime backPress = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashBoardController>(
      init: DashBoardController(),
      builder: (controller) {
        controller.getDrawerItems();
        return WillPopScope(
          onWillPop: () async {
            final timeGap = DateTime.now().difference(backPress);
            final cantExit = timeGap >= const Duration(seconds: 2);
            backPress = DateTime.now();
            if (cantExit) {
              var snack = SnackBar(
                content: Text(
                  'press_back_again_to_exit'.tr,
                  style: TextStyle(color: Colors.white),
                ),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.black,
              );
              ScaffoldMessenger.of(context).showSnackBar(snack);
              return false; // false will do nothing when back press
            } else {
              return true; // true will exit the app
            }
          },
          child: Scaffold(
            body: const HomeScreen(),
          ),
        );
      },
    );
  }
}

IconData _getIconData(String iconName) {
  switch (iconName) {
    case 'ic_home':
      return Iconsax.home;
    case 'ic_parcel':
      return Iconsax.car;
    case 'ic_rent':
      return Iconsax.heart;
    case 'ic_wallet':
      return Iconsax.wallet_2;
    case 'ic_car':
      return Iconsax.box_1;
    case 'ic_subscription':
      return Iconsax.calendar_tick;
    case 'ic_package':
      return Iconsax.box;
    case 'ic_calendar':
      return Iconsax.calendar_1;
    case 'ic_profile':
      return Iconsax.user;
    case 'ic_lock':
      return Iconsax.lock;
    case 'ic_refer':
      return Iconsax.people;
    case 'ic_language':
      return Iconsax.language_square;
    case 'ic_terms':
      return Iconsax.document_text;
    case 'ic_privacy':
      return Iconsax.shield_tick;
    case 'ic_dark':
      return Iconsax.moon;
    case 'ic_star':
    case 'ic_star_line':
      return Iconsax.star;
    case 'ic_logout':
      return Iconsax.logout;
    default:
      return Iconsax.home; // default
  }
}

Drawer buildAppDrawer(BuildContext context, DashBoardController controller) {
  final themeChange = Provider.of<DarkThemeProvider>(context);
  final isDarkMode = themeChange.getThem();

  var drawerOptions = <Widget>[];
  bool isFirstItem = true;

  for (var i = 0; i < controller.drawerItems.length; i++) {
    var d = controller.drawerItems[i];

    final bool isFirstItemInSection = d.section != null &&
        (i == 0 || controller.drawerItems[i - 1].section != d.section);

    // Add section header if this is the first item with this section
    if (isFirstItemInSection) {
      drawerOptions.add(
        Padding(
          padding: EdgeInsets.only(
            top: isFirstItem ? 16 : 28,
            bottom: 8,
            left: 20,
            right: 20,
          ),
          child: CustomText(
            text: d.section ?? '',
            isPrimary: true,
            size: 12,
            weight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      );
      isFirstItem = false;
    } else if (i == 0 && d.section == null) {
      // First item without section (Home)
      isFirstItem = false;
    }

    final bool isSelected = controller.selectedDrawerIndex.value == i;
    final bool isLogout = controller.drawerItems[i].title ==
        controller.drawerItems[controller.drawerItems.length - 1].title;

    // Add menu item with modern card design
    drawerOptions.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Show confirmation dialog for logout
              if (isLogout) {
                _showLogoutDialog(context);
              } else {
                controller.onSelectItem(i);
              }
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: AppThemeData.primary200.withOpacity(0.1),
            highlightColor: AppThemeData.primary200.withOpacity(0.05),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected
                    ? AppThemeData.primary200.withOpacity(0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppThemeData.primary200.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLogout
                          ? AppThemeData.error200.withOpacity(0.1)
                          : isSelected
                              ? AppThemeData.primary200.withOpacity(0.15)
                              : (isDarkMode
                                  ? AppThemeData.grey800Dark.withOpacity(0.5)
                                  : AppThemeData.grey100.withOpacity(0.8)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconData(d.icon),
                      size: 22,
                      color: isLogout
                          ? AppThemeData.error200
                          : isSelected
                              ? AppThemeData.primary200
                              : (isDarkMode
                                  ? AppThemeData.grey400Dark
                                  : AppThemeData.grey800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomText(
                      text: d.title,
                      isError: isLogout,
                      isPrimary: isSelected && !isLogout,
                      size: 15,
                      weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  d.isSwitch == null
                      ? Icon(
                          Iconsax.arrow_right_3,
                          size: 18,
                          color: isSelected
                              ? AppThemeData.primary200
                              : (isDarkMode
                                  ? AppThemeData.grey500Dark
                                  : AppThemeData.grey400),
                        )
                      : Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            trackOutlineColor:
                                WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                              return Colors.transparent;
                            }),
                            inactiveTrackColor: isDarkMode
                                ? AppThemeData.grey800
                                : AppThemeData.grey200,
                            activeTrackColor: AppThemeData.primary200,
                            thumbColor: WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                              return Colors.white;
                            }),
                            value: isDarkMode,
                            onChanged: (value) =>
                                (themeChange.darkTheme = value == true ? 0 : 1),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  return Drawer(
    width: Responsive.width(85, context),
    backgroundColor:
        isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
    child: Column(
      children: [
        // Modern Header with Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemeData.primary200,
                AppThemeData.primary200.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  // Logo with modern container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "assets/icons/appLogo.png",
                      height: 60,
                      width: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // User Name
                  CustomText(
                    text:
                        "${controller.userModel?.data?.prenom ?? ''} ${controller.userModel?.data?.nom ?? ''}",
                    color: Colors.white,
                    size: 20,
                    weight: FontWeight.bold,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  // User Email with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.sms,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: CustomText(
                          text: controller.userModel?.data?.email ?? '',
                          color: Colors.white.withOpacity(0.9),
                          size: 13,
                          align: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            children: drawerOptions,
          ),
        ),
      ],
    ),
  );
}

/// Show logout confirmation dialog
void _showLogoutDialog(BuildContext context) {
  Get.back(); // Close the drawer first
  MyCustomDialog.show(
    context: context,
    title: 'log_out'.tr,
    message: 'are_you_sure_logout'.tr,
    confirmText: 'log_out'.tr,
    cancelText: 'cancel'.tr,
    confirmButtonColor: AppThemeData.error200,
    onConfirm: () {
      Preferences.clearKeyData(Preferences.isLogin);
      Preferences.clearKeyData(Preferences.user);
      Preferences.clearKeyData(Preferences.userId);
      Get.offAll(() => const LoginScreen());
    },
  );
}

class DrawerItem {
  String? title;
  String? icon;
  String? section;
  bool? isSwitch;

  DrawerItem(this.title, this.icon, {this.section, this.isSwitch});
}
