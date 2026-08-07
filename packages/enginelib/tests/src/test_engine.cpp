#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers_floating_point.hpp>
#include <enginelib/engine.hpp>

TEST_CASE("engine starts at zero", "[engine]") {
  enginelib::Engine engine;
  REQUIRE(engine.elapsed() == 0.0);
}

TEST_CASE("engine accumulates time", "[engine]") {
  enginelib::Engine engine;
  engine.advance(0.5);
  engine.advance(0.25);
  REQUIRE_THAT(engine.elapsed(),
               Catch::Matchers::WithinRel(0.75, 1e-12));
}

TEST_CASE("combine exercises the public mathkit dependency", "[mathkit]") {
  STATIC_REQUIRE(enginelib::combine(2.0, 3.0) == 5.0);
}

TEST_CASE("noise is deterministic for a given state", "[noise]") {
  enginelib::Engine a;
  enginelib::Engine b;
  REQUIRE(a.noise(0.25, 0.75) == b.noise(0.25, 0.75));
}
