#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_ERROR_OR_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_ERROR_OR_H_

#include <string>
#include <variant>

#include "method_result.h"

namespace flutter {

class EncodableValue;

class FlutterError {
 public:
  explicit FlutterError(const std::string& code) : code_(code) {}
  FlutterError(const std::string& code, const std::string& message)
      : code_(code), message_(message) {}

  const std::string& code() const { return code_; }
  const std::string& message() const { return message_; }

 private:
  std::string code_;
  std::string message_;
};

class NotImplemented {
 public:
  NotImplemented() = default;
};

template <typename T = EncodableValue>
class ErrorOr final {
 public:
  ErrorOr() = default;
  ErrorOr(const FlutterError& rhs) : v_(rhs) {}
  ErrorOr(FlutterError&& rhs) : v_(std::move(rhs)) {}
  ErrorOr(const NotImplemented& rhs) : v_(rhs) {}
  ErrorOr(const T& rhs) : v_(rhs) {}
  ErrorOr(T&& rhs) : v_(std::move(rhs)) {}

  static ErrorOr<T> BadArgumentsError(const std::string& message) {
    return ErrorOr<T>(FlutterError("Bad Arguments", message));
  }

  bool HasError() const { return std::holds_alternative<FlutterError>(v_); }
  bool HasValue() const { return std::holds_alternative<T>(v_); }

  bool IsNotImplemented() const {
    return std::holds_alternative<NotImplemented>(v_);
  }

  const T& GetValue() const { return std::get<T>(v_); };
  const FlutterError& GetError() const { return std::get<FlutterError>(v_); };

  void Apply(MethodResult<T>& result) {
    if (IsNotImplemented()) {
      result.NotImplemented();
    } else if (HasError()) {
      const auto& error = GetError();
      result.Error(error.code(), error.message());
    } else if (HasValue()) {
      result.Success(GetValue());
    } else {
      result.Success();
    }
  }

 private:
  std::variant<std::monostate, NotImplemented, FlutterError, T> v_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_ERROR_OR_H_