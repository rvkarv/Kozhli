import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

/// Current / Future / Past date-time picker per Dashboard_Details.docx
/// item 3. Shows live status when in "current" mode, or the frozen
/// picked date/time when in future/past mode.
class PredictionBar extends StatefulWidget {
  const PredictionBar({super.key});

  @override
  State<PredictionBar> createState() => _PredictionBarState();
}

class _PredictionBarState extends State<PredictionBar> {
  DateTime _pickedDate = DateTime.now();
  TimeOfDay _pickedTime = TimeOfDay.now();

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _pickedDate = picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: _pickedTime);
    if (picked != null) setState(() => _pickedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dateFmt = DateFormat('d MMM yyyy');

    return Card(
      color: app.isLive ? null : Colors.amber.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(app.isLive ? Icons.wifi_tethering : Icons.history_toggle_off,
                    size: 18, color: app.isLive ? Colors.green : Colors.amber),
                const SizedBox(width: 8),
                Text(
                  app.isLive ? 'நேரலை (Live)' : 'தேர்ந்தெடுக்கப்பட்ட நேரம்',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (!app.isLive)
                  TextButton(
                    onPressed: () => app.setOverrideDateTime(null),
                    child: const Text('நேரலைக்கு திரும்பு'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(dateFmt.format(_pickedDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(context),
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(_pickedTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final combined = DateTime(
                    _pickedDate.year,
                    _pickedDate.month,
                    _pickedDate.day,
                    _pickedTime.hour,
                    _pickedTime.minute,
                  );
                  app.setOverrideDateTime(combined);
                },
                child: const Text('கணக்கிடு (Calculate)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
