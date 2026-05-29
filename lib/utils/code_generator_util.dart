import 'dart:convert';
import 'package:crypto/crypto.dart';

class CodeGeneratorUtil {
  // Funktion zur Generierung eines verschlüsselten alphanumerischen Codes
  static String generateEncryptedCode(String userId, String eventId) {
    final input = '$userId-$eventId'; // Kombiniere User ID und Event ID
    final bytes = utf8.encode(input); // Konvertiere in Bytes
    final digest = sha1.convert(bytes); // Erstelle den SHA1-Hash
    return digest
        .toString()
        .substring(0, 10)
        .toUpperCase(); // Kürze den Hash und wandle ihn in Großbuchstaben um
  }
}
