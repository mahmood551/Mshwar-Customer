import 'dart:convert';
import 'dart:io';
import 'package:cabme/core/constant/constant.dart';
import 'package:cabme/core/constant/show_toast_dialog.dart';
import 'package:cabme/features/home/controller/dash_board_controller.dart';
import 'package:cabme/features/settings/profile/controller/my_profile_controller.dart';
import 'package:cabme/features/authentication/view/login_screen.dart';
import 'package:cabme/common/widget/custom_app_bar.dart';
import 'package:cabme/common/widget/button.dart';
import 'package:cabme/common/widget/my_custom_dialog.dart';
import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/common/widget/text_field.dart';
import 'package:cabme/common/widget/light_bordered_card.dart';
import 'package:cabme/core/themes/button_them.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/themes/responsive.dart';
import 'package:cabme/core/themes/text_field_them.dart';
import 'package:cabme/core/utils/Preferences.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class MyProfileScreen extends StatelessWidget {
  MyProfileScreen({super.key});

  final GlobalKey<FormState> _profileKey = GlobalKey();

  final dashboardController = Get.put(DashBoardController());

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<MyProfileController>(
        init: MyProfileController(),
        builder: (myProfileController) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: CustomAppBar(
              title: 'My Profile'.tr,
              showBackButton: true,
              onBackPressed: () => Get.back(),
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: buildShowDetails(
                  isTrailingShow: false,
                  textIconColor: AppThemeData.error200,
                  isDarkMode: themeChange.getThem(),
                  title: "Delete Account".tr,
                  icon: Iconsax.trash,
                  onPress: () async {
                    await MyCustomDialog.show(
                      context: context,
                      title: 'Delete Account'.tr,
                      message: 'Are you sure you want to delete account?'.tr,
                      confirmText: 'Yes'.tr,
                      cancelText: 'No'.tr,
                      confirmButtonColor: AppThemeData.primary200,
                      cancelButtonColor: Colors.red,
                      onConfirm: () {
                        myProfileController
                            .deleteAccount(
                                Preferences.getInt(Preferences.userId)
                                    .toString())
                            .then((value) {
                          if (value != null) {
                            if (value["success"] == "success") {
                              ShowToastDialog.showToast(value['message']);
                              Get.back();
                              Preferences.clearSharPreference();
                              Get.offAll(const LoginScreen());
                            }
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _profileKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            // Profile Image
                            _buildProfileImage(
                                context, myProfileController, themeChange),
                            const SizedBox(height: 32),
                            // Form Fields
                            LightBorderedCard(
                              margin: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  // Name Fields Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          text: 'Name'.tr,
                                          controller: myProfileController
                                              .fullNameController.value,
                                          keyboardType: TextInputType.text,
                                          maxWords: 22,
                                          validationType: ValidationType.name,
                                          prefixIcon: Icon(
                                            Iconsax.user,
                                            size: 20,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey400Dark
                                                : AppThemeData.grey500,
                                          ),
                                          validator: (String? value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'required'.tr;
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: CustomTextField(
                                          text: 'Last Name'.tr,
                                          controller: myProfileController
                                              .lastNameController.value,
                                          keyboardType: TextInputType.text,
                                          maxWords: 22,
                                          validationType: ValidationType.name,
                                          prefixIcon: Icon(
                                            Iconsax.user,
                                            size: 20,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey400Dark
                                                : AppThemeData.grey500,
                                          ),
                                          validator: (String? value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'required'.tr;
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Phone Number Field
                                  CustomTextField(
                                    text: 'Enter mobile number'.tr,
                                    controller: myProfileController
                                        .phoneController.value,
                                    keyboardType: TextInputType.phone,
                                    validationType: ValidationType.phone,
                                    prefixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Iconsax.mobile,
                                          size: 20,
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey400Dark
                                              : AppThemeData.grey500,
                                        ),
                                        const SizedBox(width: 8),
                                        CustomText(
                                          text: "+965",
                                          size: 16,
                                          weight: FontWeight.w600,
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey900Dark
                                              : AppThemeData.grey900,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                    onChanged: (value) {
                                      myProfileController
                                          .phoneController.value.text = value;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Email Field
                                  CustomTextField(
                                    text: 'email'.tr,
                                    controller: myProfileController
                                        .emailController.value,
                                    keyboardType: TextInputType.emailAddress,
                                    readOnly: true,
                                    validationType: ValidationType.email,
                                    prefixIcon: Icon(
                                      Iconsax.sms,
                                      size: 20,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey400Dark
                                          : AppThemeData.grey500,
                                    ),
                                    validator: (String? value) {
                                      if (value == null || value.isEmpty) {
                                        return 'email not valid'.tr;
                                      }
                                      bool emailValid = RegExp(
                                              r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
                                          .hasMatch(value);
                                      if (!emailValid) {
                                        return 'email not valid'.tr;
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Save Details Button - Fixed at bottom
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomButton(
                      btnName: 'Save Details'.tr,
                      ontap: () async {
                        FocusScope.of(context).unfocus();
                        if (_profileKey.currentState!.validate()) {
                          await myProfileController
                              .updateUser(
                            image:
                                File(myProfileController.imageData.value.path),
                            name: myProfileController
                                .fullNameController.value.text
                                .trim(),
                            lname: myProfileController
                                .lastNameController.value.text
                                .trim(),
                            email: myProfileController
                                .emailController.value.text
                                .trim(),
                            phoneNum: myProfileController
                                .phoneController.value.text
                                .trim(),
                            password: myProfileController
                                .currentPasswordController.value.text
                                .trim(),
                          )
                              .then((value) {
                            if (value != null) {
                              if (value.success == "success") {
                                Preferences.setInt(Preferences.userId,
                                    int.parse(value.data!.id.toString()));
                                Preferences.setString(
                                    Preferences.user, jsonEncode(value));
                                final DashBoardController dashboardController =
                                    Get.find<DashBoardController>();

                                dashboardController.userModel =
                                    Constant.getUserData();
                                dashboardController.userModel!.data!.photoPath =
                                    "${dashboardController.userModel!.data!.photoPath}?refresh=${DateTime.now().microsecondsSinceEpoch}";
                                dashboardController.update();
                                Get.back();
                              } else {
                                ShowToastDialog.showToast(value.error);
                              }
                            }
                          });
                        }
                      },
                      buttonColor: AppThemeData.primary200,
                      textColor: Colors.white,
                      borderRadius: 16,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildProfileImage(BuildContext context,
      MyProfileController controller, DarkThemeProvider themeChange) {
    final isDarkMode = themeChange.getThem();
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode ? AppThemeData.grey200Dark : Colors.white,
                width: 4,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: controller.imageData.value.path.isNotEmpty
                  ? Image.file(
                      File(controller.imageData.value.path),
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    )
                  : (controller.photoPath.isEmpty ||
                          controller.photoPath.toString() == 'null')
                      ? Container(
                          height: 120,
                          width: 120,
                          color: AppThemeData.grey200,
                          child: Icon(
                            Iconsax.user,
                            size: 60,
                            color: AppThemeData.grey400,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: controller.photoPath.toString(),
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => Center(
                            child: CircularProgressIndicator(
                              value: downloadProgress.progress,
                              color: AppThemeData.primary200,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 120,
                            width: 120,
                            color: AppThemeData.grey200,
                            child: Icon(
                              Iconsax.user,
                              size: 60,
                              color: AppThemeData.grey400,
                            ),
                          ),
                        ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: () => buildBottomSheet(context, controller),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                decoration: BoxDecoration(
                  color: AppThemeData.primary200,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isDarkMode ? AppThemeData.surface50Dark : Colors.white,
                    width: 3,
                  ),
                ),
                padding: const EdgeInsets.all(10.0),
                child: const Icon(
                  Iconsax.edit_2,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ListTile buildShowDetails({
    required String title,
    required IconData icon,
    required Function()? onPress,
    required bool isDarkMode,
    Color? textIconColor,
    bool? isTrailingShow = true,
  }) {
    return ListTile(
      splashColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textIconColor ?? AppThemeData.error200).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: textIconColor ??
              (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
        ),
      ),
      title: CustomText(
        text: title,
        size: 16,
        weight: FontWeight.w500,
        color: textIconColor ??
            (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
      ),
      onTap: onPress,
      trailing: isTrailingShow == false
          ? null
          : Icon(
              Iconsax.arrow_right_3,
              size: 20,
              color:
                  isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey400,
            ),
    );
  }

  Future buildAlertChangeData(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required IconData iconData,
    required String? Function(String?) validators,
    required Function() onSubmitBtn,
  }) {
    return Get.defaultDialog(
      titlePadding: const EdgeInsets.only(top: 20),
      radius: 6,
      title: "Change Information".tr,
      titleStyle: const TextStyle(
        fontSize: 20,
      ),
      content: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFieldThem.boxBuildTextField(
                conext: context,
                hintText: title,
                controller: controller,
                validators: validators),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                ButtonThem.buildButton(context,
                    title: "Save".tr,
                    btnColor: AppThemeData.primary200,
                    txtColor: Colors.white,
                    onPress: onSubmitBtn,
                    btnWidthRatio: 0.3),
                const SizedBox(
                  width: 15,
                ),
                ButtonThem.buildButton(context,
                    title: "cancel".tr,
                    btnWidthRatio: 0.3,
                    btnColor: AppThemeData.secondary200,
                    txtColor: Colors.black,
                    onPress: () => Get.back()),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future buildBottomSheet(
      BuildContext context, MyProfileController controller) {
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              height: Responsive.height(22, context),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: CustomText(
                      text: "Please Select".tr,
                      size: 16,
                      weight: FontWeight.w600,
                      color: const Color(0XFF333333).withOpacity(0.8),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => pickFile(controller,
                                    source: ImageSource.camera),
                                icon: const Icon(
                                  Iconsax.camera,
                                  size: 32,
                                  color: Colors.black,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: CustomText(
                                text: "camera".tr,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => pickFile(controller,
                                    source: ImageSource.gallery),
                                icon: const Icon(
                                  Iconsax.gallery,
                                  size: 32,
                                  color: Colors.black,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: CustomText(
                                text: "gallery".tr,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future pickFile(MyProfileController controller,
      {required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();
      controller.imageData.value = image;
      // controller.uploadPhoto(File(image.path)).then((value) {
      //   if (value != null) {
      //     if (value["success"] == "Success") {
      //       UserModel userModel = Constant.getUserData();
      //       userModel.data!.photoPath = value['data']['photo_path'];
      //       Preferences.setString(Preferences.user, jsonEncode(userModel.toJson()));
      //       controller.getUsrData();
      //       dashboardController.getUsrData();
      //       ShowToastDialog.showToast("Upload successfully!".tr);
      //     } else {
      //       ShowToastDialog.showToast(value['error']);
      //     }
      //   }
      // });
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"Failed to Pick :".tr}\n $e");
    }
  }
}
