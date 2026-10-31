final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateName(String? value) {
  final name = value?.trim() ?? '';

  if (name.isEmpty) {
    return 'Ingresa tu nombre';
  }

  if (name.length < 3) {
    return 'El nombre debe tener al menos 3 caracteres';
  }

  return null;
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';

  if (email.isEmpty) {
    return 'Ingresa tu correo electrónico';
  }

  if (!_emailRegex.hasMatch(email)) {
    return 'Ingresa un correo electrónico válido';
  }

  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Ingresa tu contraseña';
  }

  if (value.length < 6) {
    return 'La contraseña debe tener al menos 6 caracteres';
  }

  return null;
}

String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Confirma tu contraseña';
  }

  if (value != password) {
    return 'Las contraseñas no coinciden';
  }

  return null;
}
