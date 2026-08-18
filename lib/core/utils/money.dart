/// Amounts as the driver reads them. Every screen used to write the dollar sign
/// by hand as an escaped `\$` right before an interpolation, and getting that
/// escape wrong prints the formula instead of the number — which is exactly what
/// reached a real phone on 2026-08-18. One function, one place to get it right.
library;

/// `12.5` → `$12.50`. Always two decimals: money is never shown truncated.
String formatUsd(double amount) => '\$${amount.toStringAsFixed(2)}';
