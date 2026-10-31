# Training Arena release shrinker rules.
#
# Feature tasks add plugin-specific keeps here when they introduce
# reflection-based native code.

# L02 (2026-09-20), found by the API 36 release-APK smoke:
# ML Kit pulls androidx.work 2.7.0 -> room-runtime 2.2.5. Room instantiates
# the generated WorkDatabase_Impl reflectively and the old consumer rule only
# keeps the class, not its constructor, so release builds crashed at startup
# ("Failed to create an instance of androidx.work.impl.WorkDatabase").
-keep class * extends androidx.room.RoomDatabase { <init>(); }

# ML Kit component registrars (common, vision common, pose) are discovered by
# name and instantiated with a no-arg constructor; without this they are
# stripped and pose detection cannot initialize in release builds.
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
