/// Typed domain/infrastructure exceptions raised by local caches and remote sync.
///
/// Ownership: Core Errors
// ==========================================
// CORE ERRORS - Cache, Validation & Server Exceptions
// ==========================================
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local cache operation failed']);

  @override
  String toString() => 'CacheException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException([this.message = 'Invalid data encountered']);

  @override
  String toString() => 'ValidationException: $message';
}

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server communication failed']);

  @override
  String toString() => 'ServerException: $message';
}
