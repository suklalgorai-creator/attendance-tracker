/// Core failure abstraction for Clean Architecture
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage cache error occurred']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error occurred']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Requested resource not found']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Cloud sync error occurred']);
}
