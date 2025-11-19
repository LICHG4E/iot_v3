# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn io.flutter.embedding.**

# Keep data for R8
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepattributes AnnotationDefault

-keepclassmembers,allowshrinking,allowobfuscation class * {
    @androidx.annotation.Keep <methods>;
}

-keepclassmembers,allowshrinking,allowobfuscation class * {
    @androidx.annotation.Keep <fields>;
}

-keepclassmembers,allowshrinking,allowobfuscation class * {
    @androidx.annotation.Keep <init>(...);
}

-keep,allowshrinking,allowobfuscation @androidx.annotation.Keep class *

-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn kotlin.jvm.functions.**

# A resource is loaded with a relative path so the package of this class must be preserved.
-adaptresourcefilenames okhttp3/internal/publicsuffix/PublicSuffixDatabase.gz

# Animal Sniffer compileOnly dependency to ensure APIs are compatible with older versions of Java.
-dontwarn org.codehaus.mojo.animal_sniffer.*

# Gson specific classes are only used for serialization/deserialization and can be obfuscated.
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepattributes AnnotationDefault
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { <fields>; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.Unsafe
-dontwarn javax.annotation.**
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.examples.android.model.** { <fields>; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep all classes in the Firebase package
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep all classes in the Flutter package
-keep class io.flutter.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.fragment.** { *; }
-keep class androidx.activity.** { *; }
-keep class androidx.core.** { *; }