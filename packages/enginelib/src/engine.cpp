#include "enginelib/engine.hpp"

#include <spdlog/spdlog.h>

#define STB_PERLIN_IMPLEMENTATION
#include <stb/stb_perlin.h>

namespace enginelib {

Engine::Engine() { spdlog::debug("enginelib::Engine constructed"); }

double Engine::advance(double dt) {
  elapsed_ = mathkit::add(elapsed_, dt);
  spdlog::trace("advanced to {}", elapsed_);
  return elapsed_;
}

double Engine::noise(double x, double y) const {
  return static_cast<double>(stb_perlin_noise3(
      static_cast<float>(x), static_cast<float>(y),
      static_cast<float>(elapsed_), 0, 0, 0));
}

}  // namespace enginelib
