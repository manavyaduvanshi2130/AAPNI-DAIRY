# TODO List for AAPNI DAIRY App Updates

## Customer Registration Screen
- [x] Fix edit button visibility on mobile devices (ensure IconButtons are properly sized and visible in ListTile trailing)

## Milk Entry Screen
- [x] Add keyboard tab navigation between form fields (implement onFieldSubmitted for Tab key to move focus)

## Home Screen
- [x] Add animation to the home screen (e.g., fade-in or slide-in animation for grid items or cards)

## Firebase Integration
- [x] Integrate Firebase for cloud database storage with email-based authentication
- [x] Enable data backup to Firebase and restore on app reinstall after login
- [x] Migrate from local SQLite to Firestore for persistent data storage
- [x] Create firebase_options.dart with project configuration
- [x] Update FirebaseService to use DefaultFirebaseOptions
- [x] Update main.dart to import firebase_options.dart

## Testing
- [ ] Test all changes on mobile emulator to ensure visibility and functionality
- [ ] Test Firebase authentication flow, data sync on login, data restoration after app reinstall
