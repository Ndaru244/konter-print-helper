# ML Kit registers components by reflection. R8 renamed
# com.google.mlkit.common.sdkinternal.* so MlKitInitProvider crashed
# on startup of the release APK.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_**
