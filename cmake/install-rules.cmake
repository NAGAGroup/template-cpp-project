if(PROJECT_IS_TOP_LEVEL)
  set(CMAKE_INSTALL_INCLUDEDIR
      "include/template-cpp-project-${PROJECT_VERSION}"
      CACHE STRING ""
  )
  set_property(CACHE CMAKE_INSTALL_INCLUDEDIR PROPERTY TYPE PATH)
endif()

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# find_package(<package>) call for consumers to find this project
set(package template-cpp-project)

install(
  TARGETS template-cpp-project_template-cpp-project
  EXPORT template-cpp-projectTargets
  RUNTIME #
          COMPONENT template-cpp-project_Runtime
  LIBRARY #
          COMPONENT template-cpp-project_Runtime
          NAMELINK_COMPONENT template-cpp-project_Development
  ARCHIVE #
          COMPONENT template-cpp-project_Development
  INCLUDES #
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

write_basic_package_version_file(
  "${package}ConfigVersion.cmake" COMPATIBILITY SameMajorVersion
)

# Allow package maintainers to freely override the path for the configs
set(template-cpp-project_INSTALL_CMAKEDIR
    "${CMAKE_INSTALL_LIBDIR}/cmake/${package}"
    CACHE STRING "CMake package config location relative to the install prefix"
)
set_property(CACHE template-cpp-project_INSTALL_CMAKEDIR PROPERTY TYPE PATH)
mark_as_advanced(template-cpp-project_INSTALL_CMAKEDIR)

install(
  FILES cmake/install-config.cmake
  DESTINATION "${template-cpp-project_INSTALL_CMAKEDIR}"
  RENAME "${package}Config.cmake"
  COMPONENT template-cpp-project_Development
)

install(
  FILES "${PROJECT_BINARY_DIR}/${package}ConfigVersion.cmake"
  DESTINATION "${template-cpp-project_INSTALL_CMAKEDIR}"
  COMPONENT template-cpp-project_Development
)

install(
  EXPORT template-cpp-projectTargets
  NAMESPACE template-cpp-project::
  DESTINATION "${template-cpp-project_INSTALL_CMAKEDIR}"
  COMPONENT template-cpp-project_Development
)

if(PROJECT_IS_TOP_LEVEL)
  include(CPack)
endif()
