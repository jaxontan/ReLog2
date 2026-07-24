// ponytail: global lock — single Failure type. Enum subtypes if callers need them.
sealed class Failure {
  String get message;
  const Failure();
}

class AuthFailure extends Failure {
  final String message;
  const AuthFailure([this.message = 'Authentication failed']);
}

class AlbumFailure extends Failure {
  final String message;
  const AlbumFailure([this.message = 'Album operation failed']);
}

class CaptureFailure extends Failure {
  final String message;
  const CaptureFailure([this.message = 'Capture failed']);
}

class StorageFailure extends Failure {
  final String message;
  const StorageFailure([this.message = 'Storage operation failed']);
}

class MessageFailure extends Failure {
  final String message;
  const MessageFailure([this.message = 'Message operation failed']);
}

class NotificationFailure extends Failure {
  final String message;
  const NotificationFailure([this.message = 'Notification failed']);
}