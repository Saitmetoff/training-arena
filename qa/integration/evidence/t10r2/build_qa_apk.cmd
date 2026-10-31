@echo off
rem Task 10 QA build: release-equivalent (AOT) APK with camera/links/ranked/share
rem ON and push OFF, pointed at the local stack through the device loopback
rem (adb reverse tcp:54521 -> host proxy 54520 -> supabase kong 54521).
rem Debug-signed by explicit opt-in: NON-DISTRIBUTABLE QA artifact only.
set JAVA_HOME=D:\Kiro\.tooling\jdk17
set PUB_CACHE=C:\Users\ADMIN\AppData\Local\Pub\Cache
set GRADLE_USER_HOME=D:\gradle-home
set TEMP=D:\ta-tmp
set TMP=D:\ta-tmp
pushd D:\TrainingArena\app
D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat build apk --release -PallowDebugSignedRelease=true -ParenaLinkHost=arena.pilot.example --dart-define=ARENA_LINK_HOST=arena.pilot.example --dart-define=ARENA_PUBLIC_URL=https://arena.pilot.example --dart-define=ARENA_SUPABASE_URL=http://127.0.0.1:54521 --dart-define=ARENA_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0 --dart-define=ARENA_AUTH_REDIRECT_URL=trainingarena://challenge/auth --dart-define=ARENA_FEATURE_CAMERA_COUNTING=true --dart-define=ARENA_FEATURE_CHALLENGE_LINKS=true --dart-define=ARENA_FEATURE_RANKED_MATCHMAKING=true --dart-define=ARENA_FEATURE_RESULT_SHARING=true --dart-define=ARENA_FEATURE_PUSH_NOTIFICATIONS=false --dart-define=ARENA_FEATURE_PREVIEW_FIXTURES=false
popd
