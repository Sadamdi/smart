# Aturan R8 untuk SMART. Plugin Flutter membawa aturannya sendiri.
-keep class io.flutter.** { *; }
-dontwarn com.google.android.play.core.**

# ML Kit OCR: hanya aksara Latin yang dipasang; pengenal aksara lain bersifat opsional
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit OCR di rilis: R8 memangkas kelas yang dibutuhkan saat berjalan (NullPointerException di TextRecognition.getClient)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class com.google.android.odml.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
