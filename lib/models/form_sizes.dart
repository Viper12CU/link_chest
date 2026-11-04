enum FormSizesType {
  initial(0.34, -60, -120),
  login(1.0, -40, -80),
  signUp(1.0, -30, -60);

  const FormSizesType(this.primary, this.firstShadow, this.secondShadow);

  final double primary;
  final double firstShadow;
  final double secondShadow;

  FormSizes get sizes => FormSizes(primary, firstShadow, secondShadow);
}

/// Tamaños de panel interpolables durante una transición.
class FormSizes {
  final double primary;
  final double firstShadow;
  final double secondShadow;

  const FormSizes(this.primary, this.firstShadow, this.secondShadow);

  /// 0 = panel curvo, 1 = panel a pantalla completa (recto).
  double get _fill {
    final double range = 1.0 - FormSizesType.initial.primary;
    if (range <= 0) return 1.0;
    return ((primary - FormSizesType.initial.primary) / range).clamp(0.0, 1.0);
  }

  double get topRadiusX => 411.0 * (1.0 - _fill);
  double get topRadiusY => 211.0 * (1.0 - _fill);

  FormSizes lerpTo(FormSizes other, double t) => FormSizes(
    primary + (other.primary - primary) * t,
    firstShadow + (other.firstShadow - firstShadow) * t,
    secondShadow + (other.secondShadow - secondShadow) * t,
  );
}
