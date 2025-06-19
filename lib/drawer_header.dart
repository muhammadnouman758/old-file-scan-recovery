import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:old_file_recovery/setting/event/event_setting.dart';
import 'package:old_file_recovery/setting/ui/setting_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'setting/state/state_setting.dart';


class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool isRecoveredFilesExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: CusColor.darkBlue3,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            _buildNavItem(Icons.home, "Home", () => _navigateTo(context, "home")),
            _buildNavItem(Icons.storage, "Scan Results", () => _navigateTo(context, "ScanResults")),
            _buildCollapsibleRecoveredFiles(),
            const Divider(color: Colors.white54),
            _buildNavItem(Icons.settings , "App Settings", () => _navigateTo(context, "SettingsPage")),
            BlocBuilder<SettingsBloc, SettingsState>(builder: (context, state) =>_buildNavItem(state.notifications == true ?Icons.notifications_active : Icons.notifications, "Notifications", () => toggleNotificationSetting(context)), ),
            _buildNavItem(Icons.help_outline, "Help & Support", () => _navigateTo(context, "Support")),
            _buildNavItem(Icons.star, "Rate Us", (){
              _openPlayStore();
            } ),
            _buildNavItem(Icons.share, "Share App", () {
              _shareApp();
            }),
            _buildNavItem(Icons.privacy_tip, "Privacy Policy", () => _navigateTo(context, "PrivacyPage")),
          ],
        ),
      ),
    );
  }

  //  Drawer Header with App Logo & Name
  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(color: CusColor.darkBlue3),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Image.asset('assets/icon.png',width: 80.w,),
            ),
            SizedBox(height: 10.h),
            const Text("Old File Recovery v2.0.4",textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  void _shareApp() {
    String shareText = "Check out this amazing file recovery app: "
        "https://play.google.com/store/apps/details?id=com.old.file_recovery_2_recovery";

    Share.share(shareText);
  }
  void _openPlayStore() async {
    final Uri playStoreUri = Uri.parse(
        "https://play.google.com/store/apps/details?id=com.old.file_recovery_2_recovery");

    if (await canLaunchUrl(playStoreUri)) {
      await launchUrl(playStoreUri);
    }
  }

  //  Single Navigation Item
  Widget _buildNavItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  // Collapsible Section for "Recovered Files"
  Widget _buildCollapsibleRecoveredFiles() {
    return ExpansionTile(
      title: const Text("Recovered Files", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      leading: const Icon(Icons.folder_special, color: Colors.white),
      collapsedIconColor: Colors.white,
      iconColor: Colors.white,
      backgroundColor: CusColor.darkBlue3,
      children: [
        _buildNavItem(Icons.image, "Recovered Images", () => _navigateTo(context, "recovered")),
        _buildNavItem(Icons.audiotrack, "Recovered Audio", () => _navigateTo(context, "recovered")),
        _buildNavItem(Icons.video_library, "Recovered Videos", () => _navigateTo(context, "recovered")),
        _buildNavItem(Icons.insert_drive_file, "Recovered Docs", () => _navigateTo(context, "recovered")),
      ],
    );
  }

  //  Navigation Function
  void _navigateTo(BuildContext context, String pageName) {
    Navigator.pushNamed(context, '/$pageName'); // Close drawer
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Navigate to $pageName"))); // Temporary navigation
  }
  void toggleNotificationSetting(BuildContext context) {
    final currentState = context.read<SettingsBloc>().state;
    bool newValue = !currentState.notifications;
    context.read<SettingsBloc>().add(UpdateSetting(key: "notifications", value: newValue));
  }
}
