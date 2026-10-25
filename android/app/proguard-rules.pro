# Flutter embedding references Play Core (deferred components), which the app doesn't use
-dontwarn com.google.android.play.core.**

# flutter_secure_storage -> Tink compile-time annotations
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# flutter_downloader uses WorkManager workers instantiated by reflection
-keep class vn.hunghd.flutterdownloader.** { *; }

# Keep line numbers for readable crash reports; hide original source file names
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
