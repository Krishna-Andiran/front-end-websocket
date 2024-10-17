import 'dart:async';
import 'package:isolate/service/db_service.dart';
import 'package:isolate/service/local_notification_service.dart';

class BackgroundService {
  late final DatabaseService _databaseService;
  late final NotificationService _notificationService;
  Timer? _timer; // Store the timer to manage it
  bool _notificationShown = false; // Flag to track if the notification has been shown
  bool _isActive = true; // Track if the app is active or inactive

  BackgroundService() {
    _databaseService = DatabaseService();
    _notificationService = NotificationService();
    _startInactivityTimer(); // Start timer after services are initialized
  }

  void _startInactivityTimer() {
    // Only start the timer if the app is not active
    if (!_isActive) {
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        final lastActiveTime = await _databaseService.getLastActiveTime();
        
        // Check for inactivity only when the app is in the background
        if (lastActiveTime != null &&
            DateTime.now().difference(lastActiveTime).inMinutes >= 1 &&
            !_isActive) { // Check if the app is inactive
          if (!_notificationShown) { // Check if notification is already shown
            await _notificationService.showNotification(); // Show notification
            await _databaseService.storeLastActiveTime(DateTime.now()); // Update last active time
            _notificationShown = true; // Set the flag to true
          }
        } else if (lastActiveTime == null || // If active time is null, reset notification flag
                   DateTime.now().difference(lastActiveTime).inMinutes < 2) {
          _notificationShown = false; // Reset the notification flag when the user becomes active again
        }
      });
    }
  }

  void appInactive() {
    _databaseService.storeLastActiveTime(DateTime.now());
    _isActive = false; // Set the app state to inactive
    _startInactivityTimer(); // Restart the timer when the app goes inactive
  }

  void appActive() {
    _isActive = true; // Set the app state to active
    _notificationShown = false; // Reset the notification flag when the app is active
    
    _timer?.cancel(); // Cancel the timer when the app is active
    _timer = null; // Clear the timer reference
  }
}
