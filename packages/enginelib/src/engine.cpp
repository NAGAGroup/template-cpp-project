#include "enginelib/engine.hpp"

#include <spdlog/spdlog.h>

namespace enginelib {

Engine::Engine() { spdlog::debug("enginelib::Engine constructed"); }

double Engine::advance(double dt) {
  elapsed_ = mathkit::add(elapsed_, dt);
  spdlog::trace("advanced to {}", elapsed_);
  return elapsed_;
}

}  // namespace enginelib
