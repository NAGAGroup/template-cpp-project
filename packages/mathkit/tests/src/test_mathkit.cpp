#include <catch2/catch_test_macros.hpp>
#include <mathkit/mathkit.hpp>

#include <array>
#include <vector>

TEST_CASE("add works for arithmetic types", "[add]") {
  STATIC_REQUIRE(mathkit::add(2, 3) == 5);
  STATIC_REQUIRE(mathkit::add(2.5, 0.5) == 3.0);
}

TEST_CASE("sum accumulates ranges", "[sum]") {
  const std::vector values{1, 2, 3, 4};
  REQUIRE(mathkit::sum(values) == 10);

  constexpr std::array doubles{0.5, 1.5};
  REQUIRE(mathkit::sum(doubles) == 2.0);
}
