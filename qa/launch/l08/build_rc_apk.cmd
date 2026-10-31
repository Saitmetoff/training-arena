@echo off
rem L08 release-equivalent APK (debug-signed smoke; NON-DISTRIBUTABLE, R9).
rem Pilot scope: camera off, ranked off, push off, challenge links on,
rem sharing on, preview fixtures off. ARENA_SUPABASE_URL / ARENA_SUPABASE_ANON_KEY
rem are supplied by the caller for the emulator validation build against the
rem local stack (http://10.0.2.2:54321); without them the app fails closed.
set JAVA_HOME=D:\Kiro\.tooling\jdk17
set PUB_CACHE=C:\Users\ADMIN\AppData\Local\Pub\Cache
set GRADLE_USER_HOME=D:\gradle-home
set TEMP=D:\ta-tmp
set TMP=D:\ta-tmp
pushd D:\TrainingArena\app
D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat build apk --release -PallowDebugSignedRelease=true -ParenaLinkHost=arena.pilot.example --dart-define=ARENA_LINK_HOST=arena.pilot.example --dart-define=ARENA_PUBLIC_URL=https://arena.pilot.example --dart-define=ARENA_SUPABASE_URL=%ARENA_SUPABASE_URL% --dart-define=ARENA_SUPABASE_ANON_KEY=%ARENA_SUPABASE_ANON_KEY% --dart-define=ARENA_AUTH_REDIRECT_URL=trainingarena://challenge/auth --dart-define=ARENA_FEATURE_CAMERA_COUNTING=false --dart-define=ARENA_FEATURE_CHALLENGE_LINKS=true --dart-define=ARENA_FEATURE_RANKED_MATCHMAKING=false --dart-define=ARENA_FEATURE_RESULT_SHARING=true --dart-define=ARENA_FEATURE_PUSH_NOTIFICATIONS=false --dart-define=ARENA_FEATURE_PREVIEW_FIXTURES=false
popd
