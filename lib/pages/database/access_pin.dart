import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'database_manager.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});
  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _currentPinController = TextEditingController();
  final DatabaseManager _dbManager = DatabaseManager();
  late AnimationController _animationController;
  bool _pinExists = false;
  bool _isLoading = false;
  bool _hideCurrentPin = true;
  bool _hideNewPin = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkIfPinExists();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinController.dispose();
    _currentPinController.dispose();
    super.dispose();
  }

  /// Check if a PIN already exists in the database
  Future<void> _checkIfPinExists() async {
    setState(() {
      _isLoading = true;
    });

    final pin = await _dbManager.getPin();

    setState(() {
      _pinExists = pin != null;
      _isLoading = false;
    });
  }

  /// Save the new PIN after verifying the current PIN (if it exists)
  Future<void> _savePin() async {
    final newPin = _pinController.text.trim();

    if (newPin.length != 4) {
      _showErrorMessage('PIN must be 4 digits!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (_pinExists) {
      final currentPin = await _dbManager.getPin();
      if (_currentPinController.text.trim() != currentPin) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Incorrect current PIN!');
        return;
      }
    }

    await _dbManager.savePin(newPin);
    setState(() {
      _isLoading = false;
    });

    _showSuccessMessage('PIN saved successfully!');

    // Give time for the success message to be seen
    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.pop(context);
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          child: _isLoading && _pinExists == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SizedBox(
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
                child: Column(
                  children: [
                    _buildHeader(),
                    SizedBox(height: 0.h),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30.r),
                            topRight: Radius.circular(30.r),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(25.w, 35.h, 25.w, 25.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormSection(),
                              const Spacer(),
                              _buildSaveButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  _pinExists ? 'Reset PIN' : 'Set PIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 48.w), // For centering the title
            ],
          ),
          SizedBox(height: 5.h),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            )),
            child: FadeTransition(
              opacity: _animationController,
              child: Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _pinExists ? Icons.lock_reset : Icons.lock_outline,
                  size: 40.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 5.h),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            )),
            child: FadeTransition(
              opacity: _animationController,
              child: Text(
                _pinExists
                    ? 'Update Your Security PIN'
                    : 'Set Your Security PIN',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            )),
            child: FadeTransition(
              opacity: _animationController,
              child: Text(
                'Your PIN will be used to access the vault',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security PIN',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: CusColor.darkBlue3,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Please enter a 4-digit PIN to secure your vault',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 30.h),
          if (_pinExists) ...[
            _buildTextField(
              controller: _currentPinController,
              label: 'Current PIN',
              hint: 'Enter your current 4-digit PIN',
              isObscure: _hideCurrentPin,
              toggleVisibility: () {
                setState(() {
                  _hideCurrentPin = !_hideCurrentPin;
                });
              },
            ),
            SizedBox(height: 20.h),
          ],
          _buildTextField(
            controller: _pinController,
            label: 'New PIN',
            hint: 'Enter a new 4-digit PIN',
            isObscure: _hideNewPin,
            toggleVisibility: () {
              setState(() {
                _hideNewPin = !_hideNewPin;
              });
            },
          ),
          SizedBox(height: 16.h),
          _buildPinStrengthIndicator(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isObscure,
    required VoidCallback toggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: CusColor.darkBlue3,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: TextStyle(
              fontSize: 16.sp,
              color: CusColor.darkBlue3,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14.sp,
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
                onPressed: toggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinStrengthIndicator() {
    int pinLength = _pinController.text.length;
    Color strengthColor = Colors.grey;
    String strengthText = 'Enter your PIN';

    if (pinLength > 0) {
      if (pinLength < 4) {
        strengthColor = Colors.red;
        strengthText = 'Weak - PIN must be 4 digits';
      } else {
        strengthColor = Colors.green;
        strengthText = 'Strong PIN';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: index < pinLength ? strengthColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 8.h),
        Text(
          strengthText,
          style: TextStyle(
            fontSize: 12.sp,
            color: strengthColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _savePin,
      style: ElevatedButton.styleFrom(
        backgroundColor: CusColor.darkBlue3,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 56.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? SizedBox(
        width: 24.w,
        height: 24.h,
        child: const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Text(
        _pinExists ? 'Update PIN' : 'Create PIN',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}