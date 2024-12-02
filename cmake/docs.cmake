# ---- Dependencies ----

set(DOX_AWESOME_PATH "${CMAKE_CURRENT_BINARY_DIR}/dox-awesome")
add_custom_command(
  OUTPUT "${DOX_AWESOME_PATH}"
  COMMAND git clone https://github.com/jothepro/doxygen-awesome-css.git
          "${DOX_AWESOME_PATH}")

find_program(DOXYGEN_EXE doxygen REQUIRED)

# ---- Declare documentation target ----

set(DOXYGEN_OUTPUT_DIRECTORY
    "${PROJECT_BINARY_DIR}/docs"
    CACHE PATH "Path for the generated Doxygen documentation")

set(working_dir "${CMAKE_CURRENT_BINARY_DIR}/docs")

foreach(file IN ITEMS Doxyfile)
  configure_file("docs/${file}.in" "${working_dir}/${file}" @ONLY)
endforeach()

add_custom_target(
  docs
  DEPENDS "${DOX_AWESOME_PATH}"
  COMMAND "${CMAKE_COMMAND}" -E remove_directory
          "${DOXYGEN_OUTPUT_DIRECTORY}/html"
  COMMAND "${DOXYGEN_EXE}" "${working_dir}/Doxyfile"
  COMMENT "Building documentation using Doxygen"
  WORKING_DIRECTORY "${working_dir}"
  VERBATIM)
