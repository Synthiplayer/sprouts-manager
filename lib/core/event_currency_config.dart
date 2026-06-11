class EventCurrencyConfig {
  static const double eurPerEvc = 0.5;

  static int get centsPerEvc => (eurPerEvc * 100).round();

  static int evcToCents(int evc) => evc * centsPerEvc;

  static double evcToEur(int evc) => evc * eurPerEvc;

  static int eurToCents(double eur) => (eur * 100).round();

  static double centsToEur(int cents) => cents / 100.0;
}
