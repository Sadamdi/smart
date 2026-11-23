# Aturan R8 untuk SMART. Plugin Flutter membawa aturannya sendiri.
-keep class io.flutter.** { *; }
-dontwarn com.google.android.play.core.**

# ML Kit OCR: hanya aksara Latin yang dipasang; pengenal aksara lain bersifat opsional
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
