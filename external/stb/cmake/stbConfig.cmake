# Hand-written CMake config for stb (upstream ships no build system).
# Installed by the rattler-build recipe next to this file.
if(TARGET stb::stb)
  return()
endif()
get_filename_component(_stb_prefix "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)
add_library(stb::stb INTERFACE IMPORTED)
set_target_properties(stb::stb PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${_stb_prefix}/include")
unset(_stb_prefix)
