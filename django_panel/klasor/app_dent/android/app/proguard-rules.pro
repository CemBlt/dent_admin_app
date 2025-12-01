# Supabase Flutter ProGuard Rules
# Bu dosya, release build'de kod karıştırma (obfuscation) kullanıldığında
# Supabase sınıflarının korunmasını sağlar.

# Supabase Flutter paketini koru
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }

# Supabase client sınıflarını koru
-keep class io.supabase.flutter.** { *; }
-keep class io.supabase.postgrest.** { *; }
-keep class io.supabase.realtime.** { *; }
-keep class io.supabase.storage.** { *; }
-keep class io.supabase.auth.** { *; }

# Retrofit ve OkHttp (Supabase tarafından kullanılan)
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }

# Gson/JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.** {
    volatile <fields>;
}

# Flutter embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (Flutter deferred components için - kullanılmıyorsa ignore et)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

