class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status: $statusCode)';
    }
    return 'ApiException: $message';
  }
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message, {super.statusCode});
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message, {super.statusCode});
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message, {super.statusCode});
}

class NotFoundException extends ApiException {
  NotFoundException(super.message, {super.statusCode});
}

class InternalServerErrorException extends ApiException {
  InternalServerErrorException(super.message, {super.statusCode});
}

class TimeoutException extends ApiException {
  TimeoutException(super.message);
}

class UnknownApiException extends ApiException {
  UnknownApiException(super.message);
}
