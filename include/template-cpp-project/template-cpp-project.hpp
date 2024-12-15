#pragma once

#include <string>

class exported_class
{
public:
  /**
   * @brief Initializes the name field to the name of the project
   */
  exported_class();

  /**
   * @brief Returns a non-owning pointer to the string stored in this class
   */
  auto name() const -> char const*;

private:
  std::string m_name;
};
