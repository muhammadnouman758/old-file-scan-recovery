import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:old_file_recovery/pages/database/pin.dart';
import 'access_pin.dart';
import 'database_manager.dart';

class VaultAccessScreen extends StatefulWidget {
  const VaultAccessScreen({super.key});

  @override
  State<VaultAccessScreen> createState() => _VaultAccessScreenState();
}

class _VaultAccessScreenState extends State<VaultAccessScreen> with SingleTickerProviderStateMixin {
  final List<String> _pin = List.filled(4, '');
  final DatabaseManager _dbManager = DatabaseManager();
  final VaultSecurityManager _securityManager = VaultSecurityManager();
  late AnimationController _animationController;
  bool _isAuthenticating = false;

  Future<void> _checkIfPinExists() async {
    final pin = await _dbManager.getPin();
    if (pin == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SetPinScreen()),
      );
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool canAuthenticate = await auth.canCheckBiometrics;
    if (!canAuthenticate) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to access the vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _accessVault();
      } else {
        _showErrorMessage('Biometric authentication failed');
      }
    } catch (e) {
      _showErrorMessage('Authentication error');
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _onKeyTap(String value) {
    HapticFeedback.lightImpact();

    for (int i = 0; i < _pin.length; i++) {
      if (_pin[i].isEmpty) {
        setState(() {
          _pin[i] = value;
        });

        if (i == _pin.length - 1) {
          Future.delayed(const Duration(milliseconds: 300), _verifyPin);
        }
        break;
      }
    }
  }

  void _onDelete() {
    HapticFeedback.mediumImpact();

    for (int i = _pin.length - 1; i >= 0; i--) {
      if (_pin[i].isNotEmpty) {
        setState(() {
          _pin[i] = '';
        });
        break;
      }
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isAuthenticating = true;
    });

    final enteredPin = _pin.join();
    final savedPin = await _dbManager.getPin();
    _clearPin();

    if (savedPin != null && await _securityManager.verifyPin(enteredPin, savedPin)) {
      _accessVault();
    } else {
      _showErrorAnimation();
    }

    setState(() {
      _isAuthenticating = false;
    });
  }

  void _showErrorAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    _showErrorMessage('Incorrect PIN');
  }

  void _clearPin() {
    setState(() {
      for (int i = 0; i < _pin.length; i++) {
        _pin[i] = '';
      }
    });
  }

  void _accessVault() {
    _showSuccessMessage('Access granted!');
    Navigator.pushNamed(context, '/vault');
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(bottom: 20.h, left: 20.w, right: 20.w),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(bottom: 20.h, left: 20.w, right: 20.w),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _checkIfPinExists();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CusColor.darkBlue3,
              const Color(0xFF1A365D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Spacer(flex: 1),
              _buildPinDisplay(),
              const Spacer(flex: 1),
              _buildKeypad(),
              SizedBox(height: 24.h),
              _buildFooterActions(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 20.h, left: 16.w, right: 16.w),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Text(
                      'Secured',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            'Vault Access',
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter your 4-digit PIN code',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinDisplay() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animationController.value * 10.w, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final bool isFilled = _pin[index].isNotEmpty;
          return Container(
            height: 16.h,
            width: 16.w,
            margin: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              border: Border.all(
                color: isFilled
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((value) => _buildKeypadButton(value)).toList(),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKeypadButton('', isVisible: false),
                _buildKeypadButton('0'),
                _buildBackspaceButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String value, {bool isVisible = true}) {
    return Visibility(
      visible: isVisible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isVisible ? () => _onKeyTap(value) : null,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 65.h,
            width: 65.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onDelete,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          height: 65.h,
          width: 65.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isAuthenticating ? null : _authenticateWithBiometrics,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: _isAuthenticating
                ? SizedBox(
              width: 24.w,
              height: 24.h,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Icon(
              Icons.fingerprint,
              color: Colors.white,
              size: 30.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SetPinScreen()),
          ),
          child: Text(
            'Forgot PIN?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }
}