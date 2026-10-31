@echo off
rem L08 release-shape AAB (UNSIGNED, bundle/native inspection only; R9).
rem Same pilot scope as the APK. ARENA_SUPABASE_URL / ARENA_SUPABASE_ANON_KEY
rem are intentionally not set: the owner's hosted values are still missing, so
rem the upload artifact must not carry local-stack credentials.
set JAVA_HOME=D:\Kiro\.tooling\jdk17
set PUB_CACHE=C:\Users\ADMIN\AppData\Local\Pub\Cache
set GRADLE_USER_HOME=D:\gradle-home
set TEMP=D:\ta-tmp
set TMP=D:\ta-tmp
pushd D:\TrainingArena\app
D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat build appbundle --release -PallowUnsignedRelease=true -ParenaLinkHost=arena.pilot.example --dart-define=ARENA_LINK_HOST=arena.pilot.example --dart-define=ARENA_PUBLIC_URL=https://arena.pilot.example --dart-define=ARENA_AUTH_REDIRECT_URL=trainingarena://challenge/auth --dart-define=ARENA_FEATURE_CAMERA_COUNTING=false --dart-define=ARENA_FEATURE_CHALLENGE_LINKS=true --dart-define=ARENA_FEATURE_RANKED_MATCHMAKING=false --dart-define=ARENA_FEATURE_RESULT_SHARING=true --dart-define=ARENA_FEATURE_PUSH_NOTIFICATIONS=false --dart-define=ARENA_FEATURE_PREVIEW_FIXTURES=false
popd
