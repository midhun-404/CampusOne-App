# ProGuard rules for CampusOne to prevent stripping of networking and JSON code

# Keep the http package classes
-keep class com.android.okhttp.** { *; }
-keep interface com.android.okhttp.** { *; }
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Keep Dart/Flutter networking classes
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.engine.network.** { *; }

# Keep models/JSON serialization if any are used via reflection or platform channels
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Preserve line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
