class EventCurrencyConfig {
  static const double eurPerEvc = 1.0;

  static double evcToEur(int evc) => evc * eurPerEvc;
}
