import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Talks to the Cloud Functions defined in /panchapakshi_backend/functions.
/// Set [region] to match `setGlobalOptions({ region: ... })` in that file.
class ActivationService {
  static const region = 'asia-south1';
  static const _mobileKey = 'panchapakshi_mobile';

  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: region);

  /// Stable-ish per-install device identifier + a human label for the
  /// admin panel. Not a hardware serial (those are locked down on
  /// modern Android/iOS) — combined with OTP-gated registration this is
  /// sufficient to block casual copying to another phone.
  static Future<(String id, String label)> deviceIdentity() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return (a.id, '${a.manufacturer} ${a.model}');
    } else if (Platform.isIOS) {
      final i = await info.iosInfo;
      return (i.identifierForVendor ?? 'unknown-ios-device', '${i.name} ${i.model}');
    }
    return ('unknown-device', 'unknown platform');
  }

  static Future<void> saveMobile(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mobileKey, mobile);
  }

  static Future<String?> savedMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileKey);
  }

  static Future<void> sendOtp(String mobile) async {
    final callable = _functions.httpsCallable('sendOtp');
    await callable.call({'mobile': mobile});
  }

  /// Returns true if this device is now activated; false if a
  /// different device is already bound and admin approval is pending.
  static Future<bool> verifyOtp(String mobile, String otp) async {
    final (deviceId, deviceLabel) = await deviceIdentity();
    final callable = _functions.httpsCallable('verifyOtpAndRegisterDevice');
    final result = await callable.call({
      'mobile': mobile,
      'otp': otp,
      'deviceId': deviceId,
      'deviceLabel': deviceLabel,
    });
    await saveMobile(mobile);
    return result.data['activated'] == true;
  }

  /// Call on every app launch before showing the dashboard.
  static Future<ActivationStatus> checkActivation() async {
    final mobile = await savedMobile();
    if (mobile == null) return ActivationStatus(activated: false, reason: 'not_registered');
    final (deviceId, _) = await deviceIdentity();
    final callable = _functions.httpsCallable('checkActivation');
    final result = await callable.call({'mobile': mobile, 'deviceId': deviceId});
    return ActivationStatus(
      activated: result.data['activated'] == true,
      reason: result.data['reason'] as String?,
    );
  }
}

class ActivationStatus {
  final bool activated;
  final String? reason; // 'not_registered' | 'blocked' | 'activation_required' | ...
  ActivationStatus({required this.activated, this.reason});
}
