#include <string>

#include "template-cpp-project/template-cpp-project.hpp"

#include <catch2/catch_test_macros.hpp>

TEST_CASE("Name is template-cpp-project", "[library]")
{
  auto const exported = exported_class {};
  REQUIRE(std::string("template-cpp-project") == exported.name());
}
