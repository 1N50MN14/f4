/// @nodoc
abstract class CustomError extends Error
{
  String message;

  dynamic error;

  StackTrace stackTrace;

  CustomError([this.message = '', this.error, this.stackTrace]);

  String toString() =>
  '${this.runtimeType}: ${message ?? ''} ${stackTrace ?? ''}';
}

/// Custom Abort error.
class AbortError extends CustomError
{
  AbortError({String message, dynamic error, StackTrace stackTrace })
    : super(message, error, stackTrace);
}

/// Custom rejection error.
class RejectionError extends CustomError
{
  RejectionError({String message, dynamic error, StackTrace stackTrace })
    : super(message ?? 'REJECTED', error, stackTrace);
}
