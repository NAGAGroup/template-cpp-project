#include <enginelib/engine.hpp>
#include <print>

int main() {
  enginelib::Engine engine;
  for (int i = 0; i < 5; ++i) {
    engine.advance(0.25);
  }
  std::println("demo-app: elapsed = {} (combine test: {})", engine.elapsed(),
               enginelib::combine(1.5, 2.5));
  return 0;
}
