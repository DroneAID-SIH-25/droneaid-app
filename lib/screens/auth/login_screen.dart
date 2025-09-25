import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_strings.dart';
import '../../routes/app_router.dart';
import 'help_seeker_auth_screen.dart';
import 'gcs_operator_auth_screen.dart';

class LoginScreen extends ConsumerWidget {
  final String? userType;

  const LoginScreen({super.key, this.userType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Route to specific auth screen based on user type
    if (userType == 'helpSeeker') {
      return const HelpSeekerAuthScreen();
    } else if (userType == 'gcsOperator') {
      return const GCSOperatorAuthScreen();
    }

    // Fallback to user type selection if no user type provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.goToUserTypeSelection();
    });

    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
