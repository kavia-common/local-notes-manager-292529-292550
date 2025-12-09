Notes Native Client

How to run:
- Ensure Flutter SDK is installed and on PATH inside the container.
- Recommended non-interactive start:
  ./preview.sh
  (This will run flutter pub get, enable linux desktop if supported, and start or build the app.)
- Manual steps (interactive):
  flutter pub get
  flutter run

Notes:
- If linux desktop is not enabled, run: flutter config --enable-linux-desktop
- If no desktop device is available in this environment, the preview will attempt a build instead.

Features:
- Create, list, view, edit, and delete notes
- Local persistence via shared_preferences
- Search/filter by title and body
- Ocean Professional theme
