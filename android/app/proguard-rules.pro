# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# sms_autofill
-keep class com.jaumard.smsautofill.** { *; }

# Google Play Core (missing classes workaround)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep model classes
-keep class **.model.** { *; }
-keep class **.models.** { *; }

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep generic signatures
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
