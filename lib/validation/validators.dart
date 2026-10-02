String? requiredText(String? value, {String message = 'Поле обязательно'}) {
  return value == null || value.trim().isEmpty ? message : null;
}

String? textLength(String? value, {int min = 1, int max = 120}) {
  final required = requiredText(value);
  if (required != null) return required;
  final length = value!.trim().length;
  return length < min || length > max
      ? 'Длина должна быть от $min до $max символов'
      : null;
}

String? integerInRange(String? value, {required int min, required int max}) {
  final required = requiredText(value);
  if (required != null) return required;
  final number = int.tryParse(value!.trim());
  return number == null || number < min || number > max
      ? 'Введите число от $min до $max'
      : null;
}

String? isbnValidator(String? value) {
  final required = requiredText(value);
  if (required != null) return required;
  final normalized = value!.replaceAll(RegExp(r'[- ]'), '');
  return RegExp(r'^\d{10}(\d{3})?$').hasMatch(normalized)
      ? null
      : 'ISBN должен содержать 10 или 13 цифр';
}

String? positiveQuantity(String? value, {bool allowZero = false}) {
  return integerInRange(
    value,
    min: allowZero ? 0 : 1,
    max: 100000,
  );
}

String? requiredSelection<T>(T? value, {String message = 'Выберите значение'}) {
  return value == null ? message : null;
}

String? nonEmptySelection<T>(Iterable<T>? value,
    {String message = 'Выберите хотя бы один вариант'}) {
  return value == null || value.isEmpty ? message : null;
}
