import 'package:datepicker_studio/datepicker_studio.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'datepicker_studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  PickedDateRange? _sheetRange;
  PickedDateRange? _dialogRange;
  PickedDateRange? _boundedRange;
  PickedDateRange? _singleDate;
  PickedDateRange? _fieldRange;
  PickedDateRange? _inlineRange;
  PickedDateRange? _birthday;
  PickedDateRange? _shift;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Date Range Picker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Demo(
            title: 'Bottom sheet',
            subtitle: 'Defaults: presets, day count, year picker.',
            value: _sheetRange,
            onPressed: () async {
              final range = await showDateRangeSheet(
                context,
                initialRange: _sheetRange,
              );
              if (range != null) setState(() => _sheetRange = range);
            },
          ),
          _Demo(
            title: 'Dialog, two months',
            subtitle: 'Wider surface with side-by-side months.',
            value: _dialogRange,
            onPressed: () async {
              final range = await showDateRangeDialog(
                context,
                initialRange: _dialogRange,
                maxWidth: 720,
                config: const DateRangePickerConfig(visibleMonths: 2),
              );
              if (range != null) setState(() => _dialogRange = range);
            },
          ),
          _Demo(
            title: 'Bounded + weekdays only',
            subtitle: 'Past year, max 14 days, weekends disabled.',
            value: _boundedRange,
            onPressed: () async {
              final now = DateTime.now();
              final range = await showDateRangeSheet(
                context,
                initialRange: _boundedRange,
                config: DateRangePickerConfig(
                  minDate: DateTime(now.year - 1, now.month, now.day),
                  maxDate: now,
                  maxRangeLength: 14,
                  minRangeLength: 2,
                  showClearButton: true,
                  selectableDayPredicate: (day) =>
                      day.weekday != DateTime.saturday &&
                      day.weekday != DateTime.sunday,
                  presets: [
                    DateRangePreset.lastDays(7),
                    DateRangePreset.thisWeek(),
                    DateRangePreset.lastWeek(),
                  ],
                ),
              );
              if (range != null) setState(() => _boundedRange = range);
            },
          ),
          _Demo(
            title: 'Single date, auto-apply',
            subtitle: 'Closes on the first tap.',
            value: _singleDate,
            onPressed: () async {
              final range = await showDateRangeSheet(
                context,
                initialRange: _singleDate,
                config: const DateRangePickerConfig(
                  mode: DateRangeMode.single,
                  autoApply: true,
                  presets: [],
                  showDayCount: false,
                ),
              );
              if (range != null) setState(() => _singleDate = range);
            },
          ),
          _Demo(
            title: 'Birthday',
            subtitle: 'Year → month → day, shows age.',
            value: _birthday,
            onPressed: () async {
              final range = await showDateRangeSheet(context,
                  initialRange: _birthday,
                  config: const DateRangePickerConfig(
                      mode: DateRangeMode.birthday, presets: []));
              if (range != null) setState(() => _birthday = range);
            },
          ),
          _Demo(
            title: 'Date + time',
            subtitle: 'Range with a time on each endpoint.',
            value: _shift,
            onPressed: () async {
              final range = await showDateRangeSheet(context,
                  initialRange: _shift,
                  config: const DateRangePickerConfig(
                      mode: DateRangeMode.dateTime,
                      minuteInterval: 15,
                      presets: []));
              if (range != null) setState(() => _shift = range);
            },
          ),
          const SizedBox(height: 8),
          const _SectionTitle('Form field'),
          DateRangeField(
            value: _fieldRange,
            onChanged: (r) => setState(() => _fieldRange = r),
            decoration: const InputDecoration(
              labelText: 'Reporting period',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.date_range_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Inline, custom theme'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: DateRangePickerView(
              initialRange: _inlineRange,
              showActions: false,
              theme: DateRangePickerTheme.from(primary: const Color(0xFF0D9488)),
              config: const DateRangePickerConfig(
                firstDayOfWeek: DateTime.sunday,
                showClearButton: true,
              ),
              onChanged: (r) => setState(() => _inlineRange = r),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _inlineRange == null
                  ? 'Nothing selected'
                  : 'Selected: ${_inlineRange!.days} days',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _Demo extends StatelessWidget {
  final String title;
  final String subtitle;
  final PickedDateRange? value;
  final VoidCallback onPressed;

  const _Demo({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          value == null ? subtitle : '$value · ${value!.days} days',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onPressed,
      ),
    );
  }
}
