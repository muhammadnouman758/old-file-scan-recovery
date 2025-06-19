
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:old_file_recovery/pages/database/access_pin.dart';
import 'package:old_file_recovery/pages/privacy/all_file_permission.dart';
import 'package:old_file_recovery/pages/privacy/data_collection.dart';
import 'package:old_file_recovery/pages/privacy/help_support.dart';
import 'package:old_file_recovery/pages/privacy/privacy.dart';
import 'package:old_file_recovery/pages/storage_analyzer/detail_storage.dart';
import 'package:old_file_recovery/setting/ui/setting_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

import 'event/event_setting.dart';
import 'state/state_setting.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  final List<String> _categories = ["General", "Privacy", "Support"];
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

// Animation controllers
  late AnimationController _pageTransitionController;
  late AnimationController _cardAnimationController;
  late final List<AnimationController> _settingGroupControllers = [];

// Animations
  late Animation<double> _pageScaleAnimation;
  late Animation<double> _pageOpacityAnimation;
  late Animation<double> _cardElevationAnimation;

  @override
  void initState() {
    super.initState();

    // Page transition animations
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pageScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageTransitionController,
        curve: Curves.easeOutQuint,
      ),
    );
    _pageOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageTransitionController,
        curve: Curves.easeInOut,
      ),
    );

    // Card animations
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardElevationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutCirc,
      ),
    );

    // Initialize setting group controllers
    // We'll create 3 for each tab's setting groups (typically 2-3 per tab)
    for (int i = 0; i < 9; i++) {
      _settingGroupControllers.add(AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 700 + (i * 100)), // Staggered timing
      ));
    }

    // Start initial animations
    _pageTransitionController.forward();
    _cardAnimationController.forward();

    // Start staggered group animations
    _startGroupAnimations(0); // Start animations for first tab
  }

  void _startGroupAnimations(int tabIndex) {
// Calculate which controllers to animate based on tab
    int startIdx = tabIndex * 3;
    int endIdx = startIdx + 3;

    // Reset all controllers first
    for (var controller in _settingGroupControllers) {
      controller.reset();
    }

    // Start animations with staggered delay
    for (int i = startIdx; i < endIdx && i < _settingGroupControllers.length; i++) {
      Future.delayed(Duration(milliseconds: (i - startIdx) * 100), () {
        if (mounted) {
          _settingGroupControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageTransitionController.dispose();
    _cardAnimationController.dispose();
    for (var controller in _settingGroupControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Reset and restart animations
    _pageTransitionController.reset();
    _pageTransitionController.forward();

    // Start new tab's staggered animations
    _startGroupAnimations(index);
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    // Reset animations before transitioning
    _pageTransitionController.reset();

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuint,
    );

    // Forward animations after page transition
    _pageTransitionController.forward();

    // Start new tab's staggered animations
    _startGroupAnimations(index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc()..add(LoadSettings()),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: CusColor.decentWhite,
        appBar: _buildAppBar(context),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                CusColor.darkBlue3,
                CusColor.decentWhite,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const CustomScrollPhysics(),
              children: [
                _buildAnimatedPage(_buildGeneralSettings, 0),
                _buildAnimatedPage(_buildPrivacySettings, 1),
                _buildAnimatedPage(_buildSupportSettings, 2),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildEnhancedBottomNavigation(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildAnimatedPage(Widget Function() contentBuilder, int index) {
    return AnimatedBuilder(
      animation: _pageTransitionController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pageScaleAnimation.value,
          child: FadeTransition(
            opacity: _pageOpacityAnimation,
            child: contentBuilder(),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: const Text(
        "Settings",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            context.read<SettingsBloc>().add(LoadSettings());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Settings refreshed"),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CusColor.darkBlue3.withOpacity(0.7),
                  CusColor.darkBlue3.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardElevationAnimation.value,
          child: AnimatedRotation(
            turns: _currentIndex * 0.25,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            child: FloatingActionButton(
              onPressed: () {
                switch (_currentIndex) {
                  case 0:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("General settings quick action")),
                    );
                    break;
                  case 1:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Privacy settings quick action")),
                    );
                    break;
                  case 2:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Support settings quick action")),
                    );
                    break;
                }
              },
              backgroundColor: CusColor.darkBlue3,
              elevation: 4,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  _getActionIconForIndex(_currentIndex),
                  key: ValueKey<int>(_currentIndex),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getActionIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.add;
      case 1:
        return Icons.security;
      case 2:
        return Icons.email;
      default:
        return Icons.settings;
    }
  }

  Widget _buildEnhancedBottomNavigation() {
    return Container(
      height: 75.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.r),
          topRight: Radius.circular(25.r),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.r),
          topRight: Radius.circular(25.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            _categories.length,
                (index) => _buildEnhancedNavItem(
              icon: _getIconForIndex(index),
              label: _categories[index],
              selected: _currentIndex == index,
              onTap: () => _onTabTapped(index),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.tune;
      case 1:
        return Icons.privacy_tip;
      case 2:
        return Icons.help_outline;
      default:
        return Icons.settings;
    }
  }

  Widget _buildEnhancedNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: selected ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Container(
                width: 100.w,
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    Colors.transparent,
                    CusColor.darkBlue3.withOpacity(0.1),
                    value,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Color.lerp(
                      Colors.transparent,
                      CusColor.darkBlue3,
                      value,
                    )!,
                    width: 1.5 * value,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Color.lerp(
                        Colors.grey,
                        CusColor.darkBlue3,
                        value,
                      ),
                      size: 20 + (2 * value),
                    ),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Padding(
                          padding: EdgeInsets.only(left: 5.w),
                          child: Opacity(
                            opacity: value,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: CusColor.darkBlue3,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (!selected)
            Padding(
              padding: EdgeInsets.only(top: 5.h),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedSettingsGroup(
                  controller: _settingGroupControllers[0],
                  title: "Scan Preferences",
                  icon: Icons.search,
                  children: [
                    _buildAnimatedToggleSetting(
                      context,
                      "Enable-save recovered files",
                      "save files after successful recovery",
                      Icons.save,
                      state.autoSave,
                      "autoSave",
                    ),
                    _buildDivider(),
                    _buildAnimatedToggleSetting(
                      context,
                      "Skip duplicate files",
                      "Automatically skip duplicate files during recovery",
                      Icons.file_copy,
                      state.deleteDuplicates,
                      "deleteDuplicates",
                    ),
                  ],
                ),

                _buildAnimatedSettingsGroup(
                  controller: _settingGroupControllers[1],
                  title: "Appearance",
                  icon: Icons.color_lens,
                  children: [
                    _buildAnimatedToggleSetting(
                      context,
                      "Dark Mode",
                      "Use dark theme throughout the app",
                      Icons.dark_mode,
                      state.darkMode,
                      "darkMode",
                    ),
                    _buildDivider(),
                    _buildAnimatedToggleSetting(
                      context,
                      "Notifications",
                      "Show recovery status notifications",
                      Icons.notifications,
                      state.notifications,
                      "notifications",
                    ),
                  ],
                ),

                _buildAnimatedSettingsGroup(
                  controller: _settingGroupControllers[2],
                  title: "Storage",
                  icon: Icons.storage,
                  children: [
                    _buildSettingItem(
                      title: "Clear Cache",
                      subtitle: "Free up space used by temporary files",
                      icon: Icons.cleaning_services,
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          _showClearCacheConfirmation(context);
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingItem(
                      title: "Storage Usage",
                      subtitle: "View app storage usage statistics",
                      icon: Icons.pie_chart,
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StorageAnalysisScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 90.h), // Extra space to account for bottom nav
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacySettings() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedSettingsGroup(
                  controller: _settingGroupControllers[3],
                  title: "Security",
                  icon: Icons.security,
                  children: [
                    _buildSettingItem(
                      title: "Set PIN Protection",
                      subtitle: "Protect access to recovered files",
                      icon: Icons.lock,
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SetPinScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildAnimatedToggleSetting(
                      context,
                      "Biometric Authentication",
                      "Use fingerprint or face ID to unlock app",
                      Icons.fingerprint,
                      false, // Replace with actual state
                      "biometricAuth",
                    ),
                  ],
                ),

                _buildAnimatedSettingsGroup(
                  controller: _settingGroupControllers[4],
                  title: "Privacy",
                  icon: Icons.privacy_tip,
                  children: [
                    _buildSettingItem(
                      title: "Privacy Policy",
                      subtitle: "Read our privacy policy",
                      icon: Icons.description,
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingItem(
                      title: "Data Collection",
                      subtitle: "Control what data we collect",
                      icon: Icons.data_usage,
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DataCollectionScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                _buildAnimatedSettingsGroup(
                  controller: _settingGroupControllers[5],
                  title: "Permissions",
                  icon: Icons.perm_device_information,
                  children: [
                    _buildSettingItem(
                      title: "Manage Permissions",
                      subtitle: "Control app access to device features",
                      icon: Icons.admin_panel_settings,
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FilePermissionsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 90.h), // Extra space to account for bottom nav
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportSettings() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(top: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedSettingsGroup(
              controller: _settingGroupControllers[6],
              title: "Help & Support",
              icon: Icons.support_agent,
              children: [
                _buildSettingItem(
                  title: "Help Center",
                  subtitle: "Guides and frequently asked questions",
                  icon: Icons.help_outline,
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  title: "Contact Us",
                  subtitle: "Get in touch with our support team",
                  icon: Icons.mail_outline,
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
// Handle contact action
                    },
                  ),
                ),
              ],
            ),

            _buildAnimatedSettingsGroup(
              controller: _settingGroupControllers[7],
              title: "About",
              icon: Icons.info_outline,
              children: [
                _buildSettingItem(
                  title: "Rate This App",
                  subtitle: "Share your feedback on the Play Store",
                  icon: Icons.star_border,
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: _openPlayStore,
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  title: "App Version",
                  subtitle: "v2.0.4",
                  icon: Icons.android,
                  trailing: null,
                ),
              ],
            ),

            SizedBox(height: 90.h), // Extra space to account for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSettingsGroup({
    required AnimationController controller,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
// Create staggered entrance animation
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: controller,
              curve: Curves.easeOutQuint,
            ),
          );

          final scaleAnimation = Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: controller,
              curve: Curves.easeOutBack,
            ),
          );

          final opacityAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: controller,
              curve: Curves.easeIn,
            ),
          );

          return Opacity(
            opacity: opacityAnimation.value,
            child: Transform.scale(
              scale: scaleAnimation.value,
              child: Transform.translate(
                offset: Offset(slideAnimation.value.dx * 100, 0),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: children,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildAnimatedToggleSetting(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      bool value,
      String key,
      ) {
    return _buildSettingItem(
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: Switch(
        value: value,
        activeColor: CusColor.darkBlue3,
        activeTrackColor: CusColor.darkBlue3.withOpacity(0.3),
        inactiveThumbColor: Colors.grey[400],
        inactiveTrackColor: Colors.grey[300],
        onChanged: (val) {
          context.read<SettingsBloc>().add(UpdateSetting(key: key, value: val));
        },
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 15.w),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: CusColor.darkBlue3.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: CusColor.darkBlue3,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Divider(
        color: Colors.grey[200],
        height: 1,
      ),
    );
  }

  void _showClearCacheConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Clear Cache"),
        content: const Text("Are you sure you want to clear the app cache? This won't affect your recovered files."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cache cleared successfully"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              "Clear",
              style: TextStyle(color: CusColor.darkBlue3, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlayStore() async {
    const url = 'https://play.google.com/store/apps/details?id=com.oldfilerecovery.app';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
// If unable to launch URL, show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open Play Store"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Custom scroll physics to make page transitions smoother
class CustomScrollPhysics extends ScrollPhysics {
  const CustomScrollPhysics({super.parent});

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 80,
    stiffness: 100,
    damping: 1,
  );
}