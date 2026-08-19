import 'dart:async';
import 'dart:io';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/utils/Preferences.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:cabme/features/authentication/view/login_screen.dart';
import 'package:cabme/common/screens/botton_nav_bar.dart';
import 'package:cabme/features/settings/localization/view/localization_screen.dart';
import 'package:cabme/features/home/controller/home_controller.dart';
import 'package:cabme/features/splash/server_down_screen.dart';
import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/service/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _waveController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _waveAnimation;

  bool _imageLoaded = false;
  bool _homeDataReady = false;
  bool _minTimeElapsed = false;
  bool _hasNavigated = false; // Prevent double navigation

  @override
  void initState() {
    super.initState();
    // Dismiss any existing toasts/loaders on splash screen
    EasyLoading.dismiss();
    _initAnimations();
    // Wait for widget to be fully built before checking server
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Keep dismissing toasts periodically to prevent them from showing
      _periodicToastDismiss();
      _checkServerFirst(); // Check server after first frame
    });
    _startMinTimer();
    _startFailsafeTimer(); // Last resort - never get stuck
  }

  /// Periodically dismiss toasts to prevent them from showing during splash
  void _periodicToastDismiss() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _hasNavigated) {
        timer.cancel();
        return;
      }
      EasyLoading.dismiss();
    });
  }

  /// Check server connectivity first - navigate immediately if down
  Future<void> _checkServerFirst() async {
    // Check server connectivity immediately
    bool serverAvailable = await _checkServerConnection();

    debugPrint('🔍 Server check result: $serverAvailable');

    if (!serverAvailable) {
      // Server is down - navigate immediately to server down screen
      debugPrint('❌ Server is DOWN - Navigating to ServerDownScreen');
      if (mounted) {
        _hasNavigated = true;
        Get.offAll(
          () => const ServerDownScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500),
        );
      }
      return;
    }

    debugPrint('✅ Server is UP - Proceeding with app initialization');
    // Server is available, proceed with data preloading
    _preloadHomeData();
  }

  /// Absolute failsafe - if splash is still showing after 15s, force navigate
  void _startFailsafeTimer() {
    Timer(const Duration(seconds: 15), () {
      if (mounted && !_hasNavigated) {
        debugPrint(
          '⚠️ Failsafe timer triggered - forcing navigation after 15s',
        );
        _hasNavigated = true;
        _navigateToNextScreen();
      }
    });
  }

  /// Preload all home screen data during splash
  Future<void> _preloadHomeData() async {
    final isLoggedIn = Preferences.getBoolean(Preferences.isLogin);

    if (isLoggedIn) {
      // User is logged in - load data and navigate immediately when done (no minimum wait)
      try {
        // Dismiss any toasts before starting data preload
        EasyLoading.dismiss();

        // Initialize HomeController early to preload data (permanent so it survives navigation)
        final homeController = Get.put(HomeController(), permanent: true);

        // Wait for initialization to complete with a MAXIMUM timeout
        // This prevents splash from getting stuck if API/Firebase is slow
        await homeController.setInitData().timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            debugPrint(
              '⚠️ setInitData timed out after 12s, continuing anyway...',
            );
            // Mark as initialized even on timeout so it won't retry
            homeController.isHomePageLoading.value = false;
          },
        );

        // Dismiss any toasts that might have been shown during initialization
        EasyLoading.dismiss();

        if (mounted) {
          setState(() {
            _homeDataReady = true;
            _minTimeElapsed = true; // Skip minimum timer for logged in users
          });
          // Verify server before navigating
          await _verifyServerBeforeNavigate();
        }
      } catch (e) {
        debugPrint('Error preloading home data: $e');
        // Dismiss any toasts that might have been shown
        EasyLoading.dismiss();
        // Silently catch errors - don't show toast during splash
        if (mounted) {
          setState(() {
            _homeDataReady = true;
            _minTimeElapsed = true;
          });
          // Verify server before navigating
          await _verifyServerBeforeNavigate();
        }
      }
    } else {
      // User not logged in - just mark data ready, wait for minimum timer
      if (mounted) {
        setState(() {
          _homeDataReady = true;
        });
        // Server check will happen in _startMinTimer
      }
    }
  }

  /// Minimum splash time for branding (only applies to non-logged-in users)
  void _startMinTimer() {
    // Only use timer for non-logged-in users (shorter time for login screen)
    final duration = Preferences.getBoolean(Preferences.isLogin)
        ? const Duration(milliseconds: 0) // No extra wait for logged in users
        : const Duration(milliseconds: 1500); // Brief branding for login screen

    Timer(duration, () async {
      if (mounted) {
        setState(() {
          _minTimeElapsed = true;
        });

        // Check server before navigating
        await _verifyServerBeforeNavigate();
      }
    });
  }

  /// Check if server is available before navigation
  Future<void> _verifyServerBeforeNavigate() async {
    // Only navigate if both conditions are met
    if (!_homeDataReady || !_minTimeElapsed || _hasNavigated) {
      return;
    }

    bool serverAvailable = await _checkServerConnection();

    if (!serverAvailable) {
      if (mounted) {
        _hasNavigated = true;
        Get.offAll(
          () => const ServerDownScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500),
        );
      }
      return;
    }

    // Server is available, proceed with normal navigation
    if (mounted) {
      _hasNavigated = true;
      _navigateToNextScreen();
    }
  }

  Future<bool> _checkServerConnection() async {
    try {
      debugPrint('🌐 Checking server at: ${API.baseUrl}settings');
      final response = await http
          .get(
            Uri.parse('${API.baseUrl}settings'),
            headers: API.authheader,
          )
          .timeout(const Duration(seconds: 5));

      debugPrint('📡 Server response: ${response.statusCode}');
      // Server is reachable if we get any response (even 401/500 means server is up)
      final isUp = response.statusCode >= 200 && response.statusCode < 600;
      debugPrint('✅ Server status: ${isUp ? "UP" : "DOWN"}');
      return isUp;
    } on SocketException catch (e) {
      // No internet or server unreachable
      debugPrint('❌ SocketException: $e');
      return false;
    } on TimeoutException catch (e) {
      // Server timeout
      debugPrint('❌ TimeoutException: $e');
      return false;
    } catch (e) {
      // Any other error means server is down
      debugPrint('❌ Exception: $e');
      return false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache the logo image so it appears instantly
    if (!_imageLoaded) {
      precacheImage(const AssetImage('assets/icons/appLogo.png'), context).then(
        (_) {
          if (mounted) {
            setState(() {
              _imageLoaded = true;
            });
          }
        },
      );
    }
  }

  void _initAnimations() {
    // Logo scale and rotation animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));

    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fadeController.forward();
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    // ✅ FIX: Use WidgetsBinding to ensure navigation happens after frame is rendered
    // This prevents the '_history.isNotEmpty' assertion error
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        if (Preferences.getString(Preferences.languageCodeKey).isEmpty) {
          Get.offAll(
            () => const LocalizationScreens(intentType: "main"),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 500),
          );
        } else if (Preferences.getBoolean(Preferences.isLogin)) {
          Get.offAll(
            () => BottomNavBar(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 500),
          );
        } else {
          Get.offAll(
            () => const LoginScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 500),
          );
        }
      } catch (e) {
        // Fallback: If Get.offAll fails, use standard Navigator
        debugPrint('Navigation error: $e');
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => Preferences.getBoolean(Preferences.isLogin)
                  ? BottomNavBar()
                  : const LoginScreen(),
            ),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _waveController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    bool isDarkMode = themeChange.getThem();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    AppThemeData.primary200,
                    AppThemeData.primary200.withOpacity(0.7),
                    const Color(0xFF001F1F),
                  ]
                : [
                    AppThemeData.primary200,
                    AppThemeData.primary200.withOpacity(0.8),
                    const Color(0xFF005555),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Animated wave circles
            ...List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return Positioned(
                    top:
                        MediaQuery.of(context).size.height * 0.3 + (index * 20),
                    left: MediaQuery.of(context).size.width * 0.5 -
                        (150 + (_waveAnimation.value * 100) + (index * 50)),
                    child: Container(
                      width: 300 + (_waveAnimation.value * 200) + (index * 100),
                      height:
                          300 + (_waveAnimation.value * 200) + (index * 100),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            0.1 - (_waveAnimation.value * 0.1),
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Floating particles
            ...List.generate(15, (index) {
              return AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  final offset = (index * 0.2) % 1.0;
                  final animValue = (_waveAnimation.value + offset) % 1.0;
                  return Positioned(
                    top: MediaQuery.of(context).size.height *
                        (0.2 + (index * 0.05)),
                    left: MediaQuery.of(context).size.width *
                        ((index * 0.1) % 1.0),
                    child: Opacity(
                      opacity: 0.3 - (animValue * 0.3),
                      child: Container(
                        width: 4 + (index % 3) * 2,
                        height: 4 + (index % 3) * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo - shows immediately (no animation delay)
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/icons/appLogo.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      gaplessPlayback: true, // Prevents flicker
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return child; // Show immediately without fade
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Tagline
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomText(
                      text: 'your_journey_our_priority'.tr,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loading indicator with SpinKit
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SpinKitThreeBounce(
                      color: Colors.white.withOpacity(0.9),
                      size: 30.0,
                    ),
                  ),
                ],
              ),
            ),

            // Version info at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    CustomText(
                      text: '${'version'.tr} 2.1.0',
                      size: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      text: 'powered_by_mshwar'.tr,
                      size: 11,
                      color: Colors.white.withOpacity(0.6),
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
