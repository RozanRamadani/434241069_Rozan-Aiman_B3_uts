class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    // Stub for notification initialization
  }

  void listenToSupabaseRealtime(String userId) {}
  void stopListening() {}
}
