import 'package:cabme/core/constant/constant.dart';
import 'package:cabme/core/themes/text_field_them.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/features/home/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeAppBar extends StatelessWidget {
  final HomeController controller;
  final bool isDarkMode;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const HomeAppBar({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return TextFieldWidget(
      textColor: isDarkMode ? AppThemeData.grey800Dark : AppThemeData.grey800,
      fontFamily: AppThemeData.medium,
      width: Constant.homeScreenType == 'OlaHome' ? 0 : 0.8,
      isReadOnly: true,
      prefix: IconButton(
        onPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
        icon: Icon(
          Icons.menu,
          color:
              isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
        ),
      ),
      hintText: 'your_current_location'.tr,
      controller: controller.currentLocationController,
    );
  }
}
