import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../services/notification_service.dart';
import '../../models/gate_pass_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ApplyPassScreen extends StatefulWidget {
  const ApplyPassScreen({super.key});

  @override
  State<ApplyPassScreen> createState() => _ApplyPassScreenState();
}

class _ApplyPassScreenState extends State<ApplyPassScreen> {
  final _reasonCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _passType = AppConstants.passTypeShort;
  TimeOfDay? _returnTime;
  TimeOfDay? _leavingTime;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  void _submitPass() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passType == AppConstants.passTypeShort && _returnTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an expected return time')));
      return;
    }

    setState(() => _isLoading = true);

    final authUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final fs = Provider.of<FirestoreService>(context, listen: false);

    try {
      if (authUser != null) {
        // 1. Check for active pass
        final activePasses = await fs.getStudentActivePasses(authUser.id);
        if (activePasses.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You already have an active gate pass.')));
            setState(() => _isLoading = false);
          }
          return;
        }

        // 2. Check for daily full day pass limit
        if (_passType == AppConstants.passTypeFullDay) {
          final alreadyHasFullDay = await fs.hasFullDayPassToday(authUser.id);
          if (alreadyHasFullDay) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only apply for one Full Day Pass per day.')));
              setState(() => _isLoading = false);
            }
            return;
          }
        }

        DateTime now = DateTime.now();
        DateTime? expectedReturnDateTime;
        DateTime? leavingDateTime;

        if (_passType == AppConstants.passTypeShort && _returnTime != null) {
          expectedReturnDateTime = DateTime(now.year, now.month, now.day, _returnTime!.hour, _returnTime!.minute);
        } else if (_passType == AppConstants.passTypeFullDay && _leavingTime != null) {
          leavingDateTime = DateTime(now.year, now.month, now.day, _leavingTime!.hour, _leavingTime!.minute);
        }

        final newPass = GatePassModel(
          id: '',
          studentId: authUser.id,
          studentName: authUser.name,
          department: authUser.department ?? '',
          regNo: authUser.regNo,
          semester: authUser.semester,
          division: authUser.division,
          profileImageUrl: authUser.profileImageUrl,
          reason: _reasonCtrl.text.trim(),
          destination: _destinationCtrl.text.trim(),
          parentPhone: authUser.parentPhone,
          status: AppConstants.statusPendingMentor,
          passType: _passType,
          expectedReturnTime: expectedReturnDateTime,
          leavingTime: leavingDateTime,
          appliedAt: now,
        );

        await fs.createGatePass(newPass);

        // Send Parent SMS
        if (authUser.parentPhone != null && authUser.parentPhone!.isNotEmpty) {
          String msg = "CampusOne Alert: Student ${authUser.name} (Reg: ${authUser.regNo}) has applied for a ${_passType == AppConstants.passTypeShort ? 'Short' : 'Full Day'} Gate Pass to ${_destinationCtrl.text.trim()}. Status: Pending Mentor Approval.";
          await SmsService.sendSms(phoneNumber: authUser.parentPhone!, message: msg);
        }

        // Send Push Notifications to Mentors
        if (authUser.department != null) {
          final mentorTokens = await fs.getMentorTokens(authUser.department!);
          for (var token in mentorTokens) {
            await NotificationService.sendNotification(
              fcmToken: token,
              title: "New ${_passType == AppConstants.passTypeShort ? 'Short' : 'Full Day'} Pass Request",
              body: "${authUser.name} has applied for a pass to ${_destinationCtrl.text.trim()}.",
            );
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent to your Mentor for review.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Error applying for pass: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _selectTime(bool isReturn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isReturn) {
          _returnTime = picked;
        } else {
          _leavingTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Provider.of<AuthService>(context).currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Apply Gate Pass'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // 1. Student Identity Card (The "Identity" Header)
                    if (authUser != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark 
                                ? [AppTheme.darkSurface, const Color(0xFF242A2C)]
                                : [Colors.white, const Color(0xFFF1F5F9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryBlue, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: authUser.profileImageUrl != null 
                                    ? NetworkImage(authUser.profileImageUrl!) 
                                    : null,
                                child: authUser.profileImageUrl == null 
                                    ? const Icon(Icons.person, size: 30) 
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authUser.name,
                                    style: TextStyle(
                                      fontSize: 20, 
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${authUser.semester} ${authUser.department}',
                                    style: TextStyle(
                                      fontSize: 14, 
                                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reg No: ${authUser.regNo ?? "N/A"}',
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.verified, color: Colors.blue, size: 24),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),
                    
                    // 2. Heading Section
                    const Text(
                      'Request Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 16),

                    // 3. Selection Grid for Pass Type
                    Row(
                      children: [
                        _buildTypeCard(
                          'Short Pass',
                          AppConstants.passTypeShort,
                          Icons.timer_outlined,
                          "Same-day return",
                        ),
                        const SizedBox(width: 16),
                        _buildTypeCard(
                          'Full Day',
                          AppConstants.passTypeFullDay,
                          Icons.calendar_today_outlined,
                          "Not returning today",
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 4. Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _destinationCtrl,
                            label: 'Destination',
                            hint: 'Where are you going?',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _reasonCtrl,
                            label: 'Reason',
                            hint: 'Why do you need to leave?',
                            icon: Icons.info_outline,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          
                          // Dynamic Time Field
                          InkWell(
                            onTap: () => _selectTime(_passType == AppConstants.passTypeShort),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_outlined, 
                                    color: AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _passType == AppConstants.passTypeShort 
                                              ? 'Expected Return Time' 
                                              : 'Leaving Time',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _passType == AppConstants.passTypeShort
                                              ? (_returnTime != null ? _returnTime!.format(context) : 'Select Time')
                                              : (_leavingTime != null ? _leavingTime!.format(context) : 'Select Time'),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                    
                    // 5. Submit Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _submitPass,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Submit Request',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'This request will be sent to your Mentor for review.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String label, String type, IconData icon, String subtitle) {
    final isSelected = _passType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _passType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryBlue 
                : (isDark ? AppTheme.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white10 : Colors.grey.shade200),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon, 
                color: isSelected ? Colors.white : AppTheme.primaryBlue,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 22),
            filled: true,
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            fillColor: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
          ),
          validator: (v) => v!.isEmpty ? 'Field required' : null,
        ),
      ],
    );
  }
}
