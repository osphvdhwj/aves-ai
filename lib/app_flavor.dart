enum AppFlavor { play, izzy, libre }

extension ExtraAppFlavor on AppFlavor {
  // Aves + never reports errors or analytics. Always false.
  bool get canEnableErrorReporting => false;

  bool get hasMapStyleDefault {
    switch (this) {
      case .play:
        return true;
      case .izzy:
      case .libre:
        return false;
    }
  }
}
