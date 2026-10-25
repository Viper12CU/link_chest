enum FormSizesType { initial, login, signUp }

class FormSizes {
  FormSizesType type;
  double primary;
  double firstShadow;
  double secondShadow;

  FormSizes({
    required this.type,
    required this.primary,
    required this.firstShadow,
    required this.secondShadow,
  });

  FormSizes copyWith({
    FormSizesType? type,
    double? primary,
    double? firstShadow,
    double? secondShadow,
  }) {
    return FormSizes(
      type: type ?? this.type,
      primary: primary ?? this.primary,
      firstShadow: firstShadow ?? this.firstShadow,
      secondShadow: secondShadow ?? this.secondShadow,
    );
  }
}
