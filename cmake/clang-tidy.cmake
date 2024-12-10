find_program(RUN_CLANG_TIDY run-clang-tidy REQUIRED)

set(run_command ${RUN_CLANG_TIDY} -p ${CMAKE_BINARY_DIR})
foreach(arg IN LISTS ${template-cpp-project_CLANG_TIDY_ARGS})
  set(run_command ${run_command} ${arg})
endforeach()

if(template-cpp-project_CLANG_TIDY_ARGS)
  add_custom_target(
    run-clang-tidy
    COMMENT "Running clang-tidy checks"
    COMMAND ${run_command}
    VERBATIM USES_TERMINAL
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  )
endif()
