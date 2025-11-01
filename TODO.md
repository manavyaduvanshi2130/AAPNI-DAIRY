# TODO: Fix Home Screen Not Updating Dairy Details After Settings Edit

## Information Gathered
- HomeScreen is a StatelessWidget that directly uses Constants.dairyName, Constants.ownerName, Constants.mobileNumber.
- SettingsScreen saves to SharedPreferences and updates Constants, but HomeScreen doesn't rebuild because it's stateless and not notified of changes.
- main.dart loads dairy details in main() but doesn't manage them as state for the app.
- Need to make dairy details dynamic by passing them as parameters to HomeScreen and reloading when settings are saved.

## Plan
### File: lib/main.dart
- Add state variables in _MyAppState: _dairyName, _ownerName, _mobileNumber.
- Add _loadDairyDetails() method to load from SharedPreferences and setState.
- Call _loadDairyDetails() in initState after _checkLoginStatus.
- Modify home widget to pass dairy details to HomeScreen.
- Modify '/settings' route to pass onSaved callback to SettingsScreen.

### File: lib/screens/home_screen.dart
- Change HomeScreen from StatelessWidget to StatefulWidget.
- Add required parameters: dairyName, ownerName, mobileNumber.
- Use these parameters in the build method instead of Constants.

### File: lib/screens/settings_screen.dart
- Add optional onSaved callback parameter to constructor.
- Call onSaved() after successfully saving settings.

## Dependent Files to be Edited
- lib/main.dart
- lib/screens/home_screen.dart
- lib/screens/settings_screen.dart

## Followup Steps
- Test the app: Change settings, go back to home screen, verify updates.
- If issues, check console for errors.
- Ensure no breaking changes to other screens.
