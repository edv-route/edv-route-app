// Payment catalogs mirrored from the admin (`payment-method.model.ts`) so the
// app captures and displays payments the same way.

/// Venezuelan banks, as `"code - name"` strings (the 4-digit code is the Pago
/// Móvil standard). Value == label, matching the admin's `VENEZUELAN_BANKS`.
const venezuelanBanks = <String>[
  '0102 - Banco de Venezuela',
  '0104 - Banco Venezolano de Crédito',
  '0105 - Banco Mercantil',
  '0108 - Banco Provincial (BBVA)',
  '0114 - Bancaribe',
  '0115 - Banco Exterior',
  '0128 - Banco Caroní',
  '0134 - Banesco',
  '0137 - Banco Sofitasa',
  '0138 - Banco Plaza',
  '0146 - Bangente',
  '0151 - Banco Fondo Común (BFC)',
  '0156 - 100% Banco',
  '0157 - DelSur',
  '0163 - Banco del Tesoro',
  '0166 - Banco Agrícola de Venezuela',
  '0168 - Bancrecer',
  '0169 - Mi Banco',
  '0171 - Banco Activo',
  '0172 - Bancamiga',
  '0173 - Banco Internacional de Desarrollo',
  '0174 - Banplus',
  '0175 - Banco Bicentenario',
  '0177 - Banfanb',
  '0178 - N58 Banco Digital',
  '0191 - Banco Nacional de Crédito (BNC)',
];

/// A destination field to show (read-only) from a method's `details`.
class DestinationField {
  final String key;
  final String label;
  const DestinationField(this.key, this.label);
}

/// Which `details` keys/labels to display per method type (the destination the
/// driver pays TO). Mirrors `PAYMENT_METHOD_FIELDS`.
const _destinationFields = <String, List<DestinationField>>{
  'bank_transfer': [
    DestinationField('bank', 'Banco'),
    DestinationField('accountNumber', 'Número de cuenta'),
    DestinationField('accountType', 'Tipo de cuenta'),
    DestinationField('accountHolder', 'Titular'),
    DestinationField('idDocument', 'Cédula / RIF del titular'),
  ],
  'pago_movil': [
    DestinationField('bank', 'Banco'),
    DestinationField('phone', 'Teléfono'),
    DestinationField('idDocument', 'Cédula / RIF'),
  ],
  'zelle': [
    DestinationField('email', 'Email o teléfono (EE.UU.)'),
    DestinationField('holder', 'Titular'),
  ],
  'binance': [
    DestinationField('identifier', 'Email, teléfono o Binance ID'),
    DestinationField('holder', 'Titular'),
  ],
};

/// The destination rows (label + value) to render for a method, skipping empty
/// values. `accountType` raw values are prettified.
List<MapEntry<String, String>> destinationRows(String type, Map<String, dynamic> details) {
  final fields = _destinationFields[type] ?? const [];
  final rows = <MapEntry<String, String>>[];
  for (final f in fields) {
    final raw = details[f.key];
    if (raw == null || raw.toString().trim().isEmpty) continue;
    var value = raw.toString();
    if (f.key == 'accountType') {
      value = value == 'ahorro' ? 'Ahorro' : (value == 'corriente' ? 'Corriente' : value);
    }
    rows.add(MapEntry(f.label, value));
  }
  return rows;
}
