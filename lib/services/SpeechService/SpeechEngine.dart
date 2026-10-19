
abstract class SpeechEngine {
  /// Motorun tanımlayıcı adı.
  String get name;

  /// Motorun bu bilgisayarda kullanılabilir olup olmadığını kontrol eder.
  Future<bool> isAvailable();

  /// Verilen metni belirtilen ses tercihiyle konuşur.
  Future<void> speak(
      String text, {
        required String voiceGender,
      });
}
