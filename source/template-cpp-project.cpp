#include <string>

#include "template-cpp-project/template-cpp-project.hpp"

#include <fmt/core.h>

exported_class::exported_class()
    : m_name {fmt::format("{}", "template-cpp-project")}
{
}

auto exported_class::name() const -> char const*
{
  return m_name.c_str();
}
