#ifndef LIB_FLUTTER_EMBEDDER_LOGGER_H
#define LIB_FLUTTER_EMBEDDER_LOGGER_H

#include <unistd.h>
#include <iostream>

namespace logger {
namespace detail {

inline std::string ifatty(const std::string& message) {
  return isatty(STDOUT_FILENO) ? message : "";
}

inline std::string green(const std::string& message) {
  return ifatty("\033[1;32m") + message + ifatty("\033[0m");
}

inline std::string yellow(const std::string& message) {
  return ifatty("\033[1;33m") + message + ifatty("\033[0m");
}

inline std::string red(const std::string& message) {
  return ifatty("\033[1;31m") + message + ifatty("\033[0m");
}

inline std::string thin(const std::string& message) {
  return ifatty("\033[90m") + message + ifatty("\033[0m");
}

class cexit {
 public:
  cexit(std::ostream& stream, int exitcode)
      : stream_(stream), exitcode_(exitcode) {}

  ~cexit() { std::exit(exitcode_); }

  template <class T>
  friend const cexit& operator<<(const cexit& self, const T& message) {
    self.stream_ << message;
    return self;
  }

  typedef std::ostream& (*cmanip)(std::ostream&);
  friend const cexit& operator<<(const cexit& self, cmanip manip) {
    manip(self.stream_);
    return self;
  }

 private:
  std::ostream& stream_;
  int exitcode_;
};

} /* namespace detail */
} /* namespace logger */

/* clang-format off */
#ifdef NDEBUG
#define debuginfo (" ")
#else
#define stringify_impl(x) #x
#define stringify(x) stringify_impl(x)
#define debuginfo (logger::detail::thin(" " __FILE__ ":" stringify(__LINE__) " "))
#endif
/* clang-format on */

#define loginfo (std::cout << logger::detail::green("[info] "))
#define logwarn (std::cout << logger::detail::yellow("[warn]") << debuginfo)
#define logerr (std::cout << logger::detail::red("[error]") << debuginfo)
#define logcrit                        \
  (logger::detail::cexit(std::cout, 1) \
   << logger::detail::red("[crit]") << debuginfo)

#endif /* LIB_FLUTTER_EMBEDDER_LOGGER_H */
