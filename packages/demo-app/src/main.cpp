#include <fmt/format.h>
#include <enginelib/engine.hpp>

#include <cstdlib>

int main(int argc, char** argv) {
  // Steps come from the CLI so the `demo` pixi task can showcase task
  // ARGUMENTS ({{ steps }} with a default) — see the demo-tasks feature.
  const int steps = argc > 1 ? std::atoi(argv[1]) : 5;
  enginelib::Engine engine;
  for (int i = 0; i < steps; ++i) {
    engine.advance(0.25);
  }
  fmt::print("demo-app: elapsed = {:.2f} (combine: {}, noise: {:+.3f})\n",
             engine.elapsed(), enginelib::combine(1.5, 2.5),
             engine.noise(0.5, 0.5));
  return 0;
}
