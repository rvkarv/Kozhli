import 'package:flutter/material.dart';

import '../services/activation_service.dart';
import 'home_screen.dart';

enum _Step { checking, enterMobile, enterOtp, pendingApproval, blocked, activated }

/// Gate shown on every cold start. Flow:
/// checkActivation() -> activated ? HomeScreen
///                    : not_registered -> ask mobile -> send OTP -> verify
///                    : activation_required -> re-register this device
///                    : pending_admin_approval -> waiting screen
///                    : blocked -> blocked screen
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  _Step _step = _Step.checking;
  final _mobileCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _step = _Step.checking);
    try {
      final status = await ActivationService.checkActivation();
      if (status.activated) {
        setState(() => _step = _Step.activated);
        return;
      }
      switch (status.reason) {
        case 'blocked':
          setState(() => _step = _Step.blocked);
          break;
        case 'pending_admin_approval':
          setState(() => _step = _Step.pendingApproval);
          break;
        default: // not_registered, activation_required, subscription_expired
          final saved = await ActivationService.savedMobile();
          if (saved != null) _mobileCtrl.text = saved;
          setState(() => _step = _Step.enterMobile);
      }
    } catch (e) {
      setState(() {
        _step = _Step.enterMobile;
        _error = 'Could not reach activation server: $e';
      });
    }
  }

  Future<void> _sendOtp() async {
    if (_mobileCtrl.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ActivationService.sendOtp(_mobileCtrl.text.trim());
      setState(() => _step = _Step.enterOtp);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final activated = await ActivationService.verifyOtp(
          _mobileCtrl.text.trim(), _otpCtrl.text.trim());
      setState(() => _step = activated ? _Step.activated : _Step.pendingApproval);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _Step.activated) return const HomeScreen();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _Step.checking:
        return const CircularProgressIndicator();

      case _Step.enterMobile:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('கோழி பட்சி', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Enter your registered mobile number to activate this app.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number (e.g. +919876543210)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _sendOtp,
              child: _busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send OTP'),
            ),
          ],
        );

      case _Step.enterOtp:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the OTP sent to ${_mobileCtrl.text}'),
            const SizedBox(height: 16),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6-digit OTP',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _busy ? null : _verifyOtp,
              child: _busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify & Activate'),
            ),
            TextButton(
              onPressed: () => setState(() => _step = _Step.enterMobile),
              child: const Text('Change number'),
            ),
          ],
        );

      case _Step.pendingApproval:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            const Text(
              'Activation Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This number is already active on another device.\n'
              'An admin approval is needed to move it to this device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _check, child: const Text('Check again')),
          ],
        );

      case _Step.blocked:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.block, size: 48, color: Colors.red),
            SizedBox(height: 12),
            Text('Access Blocked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Please contact support.', textAlign: TextAlign.center),
          ],
        );

      case _Step.activated:
        return const SizedBox.shrink(); // handled in build()
    }
  }
}
