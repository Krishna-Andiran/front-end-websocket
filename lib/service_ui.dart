import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
class BackgroundService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late Database _db;
  late StoreRef<String, Map<String, dynamic>> _store;
  bool _notificationShown = false; // Flag to track if the notification has been shown
  bool _isActive = true; // Track if the app is active or inactive

  BackgroundService() {
    _initializeNotifications();
    _initializeDatabase();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Use the default Flutter icon

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = '${directory.path}/app_db.db'; // Path to the database file

    var databaseFactory = databaseFactoryIo; // Use databaseFactoryWeb for web apps
    _db = await databaseFactory.openDatabase(dbPath);
    _store = stringMapStoreFactory.store('app_data');

    _startInactivityTimer(); // Start timer after database is initialized
  }

  void _startInactivityTimer() {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      final lastActiveTime = await _getLastActiveTime();
      if (lastActiveTime != null &&
          DateTime.now().difference(lastActiveTime).inMinutes >= 1 &&
          !_isActive) { // Check if the app is inactive
        if (!_notificationShown) { // Check if notification is already shown
          await _showNotification(); // Show notification
          await _storeLastActiveTime(DateTime.now()); // Update last active time
          _notificationShown = true; // Set the flag to true
        }
      } else if (lastActiveTime == null || // If active time is null, reset notification flag
                 DateTime.now().difference(lastActiveTime).inMinutes < 2) {
        _notificationShown = false; // Reset the notification flag when the user becomes active again
      }
    });
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sync_channel',
      'Sync Notifications',
      channelDescription: 'Notification channel for sync reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Sync Data',
      'It\'s time to sync your data!',
      platformChannelSpecifics,
      payload: 'sync_data',
    );
  }

  Future<void> _storeLastActiveTime(DateTime time) async {
    await _store
        .record('last_active')
        .put(_db, {'time': time.toIso8601String()});
  }

  Future<DateTime?> _getLastActiveTime() async {
    final record = await _store.record('last_active').get(_db);
    if (record != null) {
      return DateTime.parse(record['time'] as String);
    }
    return null;
  }

  void appInactive() {
    _storeLastActiveTime(DateTime.now());
    _isActive = false; // Set the app state to inactive
  }

  void appActive() {
    _isActive = true; // Set the app state to active
  }
}