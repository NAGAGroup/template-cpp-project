set(ENABLE_SYCL_TARGETS
    ""
    CACHE STRING "SYCL targets to enable")

function(add_sycl target)
  get_target_property(target_sources ${target} SOURCES)
  foreach(source ${target_sources})
    get_source_file_property(is_header_only ${source} HEADER_FILE_ONLY)
    if(NOT is_header_only)
      set_source_files_properties(
        ${source} PROPERTIES COMPILE_FLAGS
                             "-fsycl -fsycl-targets='${ENABLE_SYCL_TARGETS}'")
    endif()
  endforeach()
endfunction()
