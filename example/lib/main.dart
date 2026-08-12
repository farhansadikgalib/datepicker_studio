import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _mode = ThemeMode.light;

  ThemeData _t(Brightness b) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: b,
    ),
    useMaterial3: true,
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'datepicker_studio',
    debugShowCheckedModeBanner: false,
    themeMode: _mode,
    theme: _t(Brightness.light),
    darkTheme: _t(Brightness.dark),
    home: DemoPage(
      isDark: _mode == ThemeMode.dark,
      onToggleTheme: () => setState(
        () =>
            _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
      ),
    ),
  );
}

class DemoPage extends StatefulWidget {
  const DemoPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _ranges = <String, PickedDateRange?>{};
  PickedDates? _multi;
  PickedDateRange? _controlled;
  final _controller = DateRangePickerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
    );

  /// A range-picker tile that opens [open] and remembers the result under [key].
  Widget _tile(
    IconData icon,
    String title,
    String hint,
    String key,
    Future<PickedDateRange?> Function() open,
  ) {
    final v = _ranges[key];
    return _Demo(
      icon,
      title,
      hint,
      v == null ? null : '$v · ${v.days} days',
      () async {
        final r = await open();
        if (r != null) setState(() => _ranges[key] = r);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('datepicker_studio'),
        actions: [
          IconButton(
            tooltip: widget.isDark ? 'Light mode' : 'Dark mode',
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _Section('Presentations', 'One calendar, four surfaces'),
          _tile(
            Icons.calendar_month_rounded,
            'Bottom sheet',
            'Presets & year picker',
            'sheet',
            () => DateRangePickerSheet(context, initialRange: _ranges['sheet']),
          ),
          _tile(
            Icons.calendar_view_month_rounded,
            'Dialog, two months',
            'Side by side',
            'popup',
            () => DateRangePickerPopup(
              context,
              initialRange: _ranges['popup'],
              maxWidth: 720,
              config: const DateRangePickerConfig(visibleMonths: 2),
            ),
          ),
          _tile(
            Icons.phone_iphone_rounded,
            'Cupertino',
            'iOS Cancel/Done modal',
            'ios',
            () => DateRangePickerCupertino(
              context,
              initialRange: _ranges['ios'],
              title: 'Dates',
            ),
          ),

          const _Section('Modes', 'Span, birthday, time or many'),
          _tile(
            Icons.event_rounded,
            'Single date',
            'Auto-applies on first tap',
            'single',
            () => DateRangePickerSheet(
              context,
              initialRange: _ranges['single'],
              config: const DateRangePickerConfig(
                mode: DateRangeMode.single,
                autoApply: true,
                presets: [],
              ),
            ),
          ),
          _tile(
            Icons.cake_rounded,
            'Birthday',
            'Year → month → day, shows age',
            'bday',
            () => DateRangePickerSheet(
              context,
              initialRange: _ranges['bday'],
              config: const DateRangePickerConfig(
                mode: DateRangeMode.birthday,
                presets: [],
              ),
            ),
          ),
          _tile(
            Icons.schedule_rounded,
            'Date + time',
            'A time on each endpoint',
            'dt',
            () => DateRangePickerSheet(
              context,
              initialRange: _ranges['dt'],
              config: const DateRangePickerConfig(
                mode: DateRangeMode.dateTime,
                minuteInterval: 15,
                presets: [],
              ),
            ),
          ),
          _Demo(
            Icons.checklist_rounded,
            'Multiple dates',
            'Toggle any number of days',
            _multi == null || _multi!.isEmpty ? null : '${_multi!.count} days',
            () async {
              final r = await DateRangePickerMultiple(
                context,
                initialDates: _multi,
              );
              if (r != null) setState(() => _multi = r);
            },
          ),

          const _Section(
            'Standalone pickers',
            'Return a time, duration, month or year',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(Icons.access_time_rounded, 'Time', () async {
                final t = await DateRangePickerTime(
                  context,
                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                  minuteInterval: 5,
                );
                if (t != null && context.mounted)
                  _snack('Time · ${t.format(context)}');
              }),
              _Pill(Icons.timelapse_rounded, 'Duration', () async {
                final d = await DateRangePickerDuration(
                  context,
                  initialDuration: const Duration(hours: 1),
                  minuteInterval: 5,
                );
                if (d != null)
                  _snack(
                    'Duration · ${d.inHours}h ${d.inMinutes.remainder(60)}m',
                  );
              }),
              _Pill(Icons.calendar_view_month_rounded, 'Month', () async {
                final m = await DateRangePickerMonth(context);
                if (m != null) _snack('Month · ${m.month}/${m.year}');
              }),
              _Pill(Icons.today_rounded, 'Year', () async {
                final y = await DateRangePickerYear(context);
                if (y != null) _snack('Year · $y');
              }),
            ],
          ),

          const _Section(
            'Form field',
            'Validates inside a Form, fully styleable',
          ),
          Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: DateRangeFormField(
              validator: (r) => r == null ? 'Please pick a period' : null,
              borderRadius: BorderRadius.circular(18),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'Reporting period',
                filled: true,
                prefixIcon: Icon(Icons.date_range_rounded, size: 18),
              ),
            ),
          ),

          const _Section(
            'Inline + controller',
            'Events, week numbers, driven by chips',
          ),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Last 7 days'),
                onPressed: () => _controller.setRange(
                  DateRangePreset.lastDays(7).build(DateTime.now()),
                ),
              ),
              ActionChip(
                label: const Text('Jan 2027'),
                onPressed: () => _controller.goToMonth(DateTime(2027, 1)),
              ),
              ActionChip(
                label: const Text('Today'),
                onPressed: _controller.goToToday,
              ),
              ActionChip(
                label: const Text('Clear'),
                onPressed: _controller.clear,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: DateRangePickerView(
                controller: _controller,
                showActions: false,
                theme: DateRangePickerTheme.rounded(),
                config: DateRangePickerConfig(
                  showWeekNumbers: true,
                  eventLoader: (d) => const {9, 10, 22}.contains(d.day)
                      ? const ['e']
                      : const [],
                  dayHighlightColor: (d) => d.weekday >= DateTime.saturday
                      ? const Color(0x14EF4444)
                      : null,
                ),
                onChanged: (r) => setState(() => _controlled = r),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              _controlled == null
                  ? 'Tap a chip to drive it'
                  : '${_controlled!.days} days selected',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled group header.
class _Section extends StatelessWidget {
  const _Section(this.title, this.subtitle);
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            subtitle,
            style: t.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable demo tile with an icon and its live result.
class _Demo extends StatelessWidget {
  const _Demo(this.icon, this.title, this.hint, this.selected, this.onTap);

  final IconData icon;
  final String title, hint;
  final String? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final on = selected != null;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: c.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: on ? c.primary : c.primaryContainer,
          foregroundColor: on ? c.onPrimary : c.onPrimaryContainer,
          child: Icon(icon, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(selected ?? hint),
        trailing: Icon(
          on ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
          color: on ? c.primary : c.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// A compact outlined button used for the standalone pickers.
class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label),
  );
}
