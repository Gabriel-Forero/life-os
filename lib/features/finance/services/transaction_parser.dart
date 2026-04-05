/// Parses bank SMS messages or clipboard text into structured transaction data.
///
/// Supports common Colombian bank formats:
///   - Bancolombia: "Bancolombia le informa compra por $45.000 en EXITO CALLE 80"
///   - Nequi: "Nequi: Pagaste $25.000 a RAPPI"
///   - Daviplata: "Daviplata: Retiro por $100.000"
///   - Generic: any text containing "$XXX.XXX" or "$XXX,XXX"
class ParsedTransaction {
  const ParsedTransaction({
    required this.amountCents,
    this.merchant,
    this.date,
    required this.rawText,
  });

  final int amountCents;
  final String? merchant;
  final DateTime? date;
  final String rawText;

  @override
  String toString() =>
      'ParsedTransaction(amount=$amountCents, merchant=$merchant)';
}

class TransactionParser {
  TransactionParser._();

  // ---------------------------------------------------------------------------
  // Bank-specific patterns
  // ---------------------------------------------------------------------------

  /// Bancolombia: "compra|pago|retiro por $45.000 en MERCHANT"
  static final _bancolombia = RegExp(
    r'(?:compra|pago|retiro).*?\$\s*([0-9]+(?:[.,][0-9]+)*)(?:.*?\ben\b\s+([A-Z][A-Za-z0-9 &\-]+?))?(?:\s*[,.\n]|$)',
    caseSensitive: false,
  );

  /// Nequi: "Pagaste $25.000 a MERCHANT"
  static final _nequi = RegExp(
    r'[Pp]agaste\s+\$\s*([0-9]+(?:[.,][0-9]+)*)(?:\s+a\s+([A-Z][A-Za-z0-9 &\-]+?))?(?:\s*[,.\n]|$)',
    caseSensitive: false,
  );

  /// Davivienda: "Compra aprobada $45.000 en MERCHANT"
  static final _davivienda = RegExp(
    r'[Cc]ompra\s+aprobada\s+\$\s*([0-9]+(?:[.,][0-9]+)*)(?:\s+en\s+([A-Z][A-Za-z0-9 &\-]+?))?(?:\s*[,.\n]|$)',
    caseSensitive: false,
  );

  /// Generic: first "$XXX.XXX" or "$XXX,XXX" in the text.
  static final _generic = RegExp(
    r'\$\s*([0-9]+(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})?)',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Attempts to parse a bank SMS / clipboard text into a [ParsedTransaction].
  ///
  /// Returns `null` when no recognisable amount is found.
  static ParsedTransaction? parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // Try bank-specific patterns first (ordered by specificity).
    for (final pattern in [_bancolombia, _nequi, _davivienda]) {
      final match = pattern.firstMatch(trimmed);
      if (match == null) continue;

      final amount = _parseAmount(match.group(1));
      if (amount == null || amount <= 0) continue;

      final merchant = match.groupCount >= 2
          ? match.group(2)?.trim().replaceAll(RegExp(r'\s+'), ' ')
          : null;

      return ParsedTransaction(
        amountCents: amount,
        merchant: merchant?.isEmpty == true ? null : merchant,
        rawText: trimmed,
      );
    }

    // Fallback: generic amount extraction.
    final match = _generic.firstMatch(trimmed);
    if (match != null) {
      final amount = _parseAmount(match.group(1));
      if (amount != null && amount > 0) {
        return ParsedTransaction(amountCents: amount, rawText: trimmed);
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Normalises Colombian amount strings ("45.000" → 45000, "45,000" → 45000).
  static int? _parseAmount(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    // Remove all separators (. and ,) except if the last group is < 3 digits
    // (decimal indicator). For Colombian notation dots are thousands separators.
    final cleaned = raw.replaceAll(RegExp(r'[.,]'), '');
    return int.tryParse(cleaned);
  }
}
