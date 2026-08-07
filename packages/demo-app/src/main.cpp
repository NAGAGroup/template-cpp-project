#include <fmt/format.h>
#include <enginelib/engine.hpp>

int main() {
  enginelib::Engine engine;
  for (int i = 0; i < 5; ++i) {
    engine.advance(0.25);
  }
  fmt::print("demo-app: elapsed = {:.2f} (combine: {}, noise: {:+.3f})\n",
             engine.elapsed(), enginelib::combine(1.5, 2.5),
             engine.noise(0.5, 0.5));
  return 0;
}
