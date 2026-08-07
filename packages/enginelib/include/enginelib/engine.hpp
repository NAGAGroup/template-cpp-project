#pragma once

#include <mathkit/mathkit.hpp>

#include "enginelib/export.hpp"

namespace enginelib {

/// Toy simulation engine demonstrating a compiled library with a PUBLIC
/// header-only dependency (mathkit) and a PRIVATE binary dependency
/// (spdlog, used only in the implementation).
class ENGINELIB_EXPORT Engine {
 public:
  Engine();

  /// Advance the simulation by `dt` seconds; returns the new elapsed time.
  double advance(double dt);

  [[nodiscard]] double elapsed() const noexcept { return elapsed_; }

 private:
  double elapsed_{0.0};
};

/// Public inline API exercising the public mathkit dependency: consumers
/// compile mathkit code through OUR header, which is why mathkit must
/// reach their environment (run-exports do that for us).
[[nodiscard]] constexpr double combine(double a, double b) noexcept {
  return mathkit::add(a, b);
}

}  // namespace enginelib
