enum FormSizesType {
  initial(0.34, -60, -120),
  login(0.62, -40, -80),
  signUp(0.85, -30, -60);

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

  FormSizes lerpTo(FormSizes other, double t) => FormSizes(
    primary + (other.primary - primary) * t,
    firstShadow + (other.firstShadow - firstShadow) * t,
    secondShadow + (other.secondShadow - secondShadow) * t,
  );
}
