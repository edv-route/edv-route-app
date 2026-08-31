/// Date formatting shared by the whole app. It lived copy-pasted in four
/// screens: two identical `_formatDate` for the API and two hand-written
/// `dd/MM/yyyy` for the UI. The app has no `intl` dependency on purpose (it
/// would drag localisation machinery for two formats), so these two live here.
library;

/// `yyyy-MM-dd` — the shape the backend accepts for a date field.
String formatApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// `dd/MM/yyyy` — the shape a driver reads.
String formatDisplayDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

const List<String> _monthNames = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// `agosto 2026` — for "member since" style lines.
String formatMonthYear(DateTime date) => '${_monthNames[date.month - 1]} ${date.year}';
