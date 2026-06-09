cmake_minimum_required(VERSION 4.3.2)
project(tyghbn
  VERSION 1.0.0
  DESCRIPTION "A C++ utility library providing simple template functions"
  LANGUAGES CXX
)

# Option for building with modules (C++20 modules support)
option(TYGHBN_USE_MODULES "Use C++20 modules instead of headers" OFF)

if(TYGHBN_USE_MODULES)
  if(NOT CMAKE_GENERATOR STREQUAL "Ninja" AND
    NOT CMAKE_GENERATOR STREQUAL "Ninja Multi-Config" AND
    NOT CMAKE_GENERATOR MATCHES "Visual Studio")
    message(WARNING "${CMAKE_GENERATOR} does not support C++ modules")
    message(WARNING "Configuring for building ${PROJECT_NAME} without C++ modules")
    set(TYGHBN_USE_MODULES OFF CACHE BOOL "Use C++20 modules instead of headers" FORCE)
  else()
    message(STATUS "Configuring for building ${PROJECT_NAME} with C++ modules")
  endif()
else()
  message(STATUS "Configuring for building ${PROJECT_NAME} without C++ modules")
endif()

# Include Conan generated files
if(EXISTS "${CMAKE_BINARY_DIR}/generators/conan_toolchain.cmake")
  include("${CMAKE_BINARY_DIR}/generators/conan_toolchain.cmake")
endif()

# Prepare compile_commands.json for development tools such as documentation and
# LSP.
if(PROJECT_IS_TOP_LEVEL)
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

  # Automatically resolve the correct path regardless of generator type
  if(CMAKE_CONFIGURATION_TYPES)
    # Multi-Config outputs directly to the top-level build directory
    set(CDB_PATH "${CMAKE_BINARY_DIR}")
  else()
    # Single-Config outputs to the active Conan variant folder (Release/Debug)
    set(CDB_PATH "${CMAKE_CURRENT_BINARY_DIR}")
  endif()

  # Create an absolute invariant build target
  add_custom_target(docs
    COMMAND hdoc -p "${CDB_PATH}" --verbose
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Generating clean library documentation..."
  )
endif()

# Library without cpp files.
add_library(or_else-legacy INTERFACE)
target_sources(or_else-legacy
  INTERFACE
    FILE_SET HEADERS
      FILES include/tyghbn/or_else.hpp
      BASE_DIRS include
)

# Header-only library target: or_else
# The header-style library has to be declared as an INTERFACE library,
# while the module-style library can be unspecified (STATIC or SHARED).

if(TYGHBN_USE_MODULES)
  add_library(or_else)
  target_compile_features(or_else PUBLIC cxx_std_20)
  target_link_libraries(or_else
    PUBLIC
      or_else-legacy
  )
  target_sources(or_else
    PUBLIC
      FILE_SET CXX_MODULES
        FILES modules/or_else.cppm
  )
else()
  add_library(or_else INTERFACE)
  target_link_libraries(or_else
    INTERFACE
      or_else-legacy
  )
endif()

# Template for a library with at least one cpp file.
#
# To provide a consist interface for module and non-module versions, start with
# a base library which is a non-module version.
add_library(add_one-legacy)
target_sources(add_one-legacy
  PUBLIC
    FILE_SET HEADERS
      FILES include/tyghbn/add_one.hpp
      BASE_DIRS include
  PRIVATE
    src/add_one.cpp
)

# To expose the library as a C++ module, add cppm files that export symbols
# from header files.
if(TYGHBN_USE_MODULES)
  add_library(add_one)
  target_compile_features(add_one PUBLIC cxx_std_20)
  target_link_libraries(add_one
    PUBLIC
      add_one-legacy
  )
  target_sources(add_one
    PUBLIC
      FILE_SET CXX_MODULES
        FILES modules/add_one.cppm
  )
else()
  add_library(add_one INTERFACE)
  target_link_libraries(add_one
    INTERFACE
      add_one-legacy
  )
endif()

# Testing enabled only when the project is top-level and BUILD_TESTING is not
# explicitly defined as OFF.
if(PROJECT_IS_TOP_LEVEL AND NOT (DEFINED BUILD_TESTING AND NOT BUILD_TESTING))
  # Find doctest ONLY via the configuration of this project.
  find_package(doctest CONFIG QUIET)

  if(NOT doctest_FOUND)
    message(WARNING "doctest not found - tests will not be built")
    return()
  endif()

  # Enable testing
  enable_testing()

  list(APPEND CMAKE_MODULE_PATH ${doctest_CMAKE_MODULE_PATH})
  include(doctest)

  add_executable(test_tyghbn)

  # Pass the TYGHBN_USE_MODULES flag to the test code
  if(TYGHBN_USE_MODULES)
    target_compile_definitions(test_tyghbn
      PRIVATE
        TYGHBN_USE_MODULES
    )
  endif()

  add_subdirectory(tests)

  target_link_libraries(test_tyghbn
    PRIVATE
      doctest::doctest
  )

  doctest_discover_tests(test_tyghbn)

  option(TYGHBN_ENABLE_COVERAGE "Enable code coverage instrumentation" OFF)

  if(TYGHBN_ENABLE_COVERAGE)
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
      if(doctest_FOUND)
        target_compile_options(test_tyghbn PRIVATE --coverage -O0 -g)
        target_link_options(test_tyghbn PRIVATE --coverage)

        find_program(GCOVR gcovr)

        if(GCOVR)
          if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
            find_program(TYGHBN_LLVM_COV llvm-cov)
            if(TYGHBN_LLVM_COV)
              set(TYGHBN_GCOV_EXECUTABLE "${TYGHBN_LLVM_COV} gcov")
            else()
              message(WARNING "llvm-cov not found — coverage target will not be created")
              set(TYGHBN_ENABLE_COVERAGE OFF)
            endif()
          else()
            set(TYGHBN_GCOV_EXECUTABLE gcov)
          endif()

          if(TYGHBN_ENABLE_COVERAGE)
            set(TYGHBN_BUILD_DIR "$<TARGET_FILE_DIR:test_tyghbn>")
            add_custom_target(coverage
              COMMAND $<TARGET_FILE:test_tyghbn>
              COMMAND ${CMAKE_COMMAND} -E make_directory "${TYGHBN_BUILD_DIR}/coverage_report"
              COMMAND ${GCOVR} --root ${CMAKE_SOURCE_DIR}
                --txt
                "${TYGHBN_BUILD_DIR}/coverage_report/report.txt"
                --html-details
                "${TYGHBN_BUILD_DIR}/coverage_report/index.html"
                --cobertura
                "${TYGHBN_BUILD_DIR}/coverage_report/cobertura.xml"
                --markdown
                "${TYGHBN_BUILD_DIR}/coverage_report/summary.md"
                --exclude "${CMAKE_SOURCE_DIR}/tests/.*"
                --gcov-executable "${TYGHBN_GCOV_EXECUTABLE}"
                --txt-summary >
                "${TYGHBN_BUILD_DIR}/coverage_report/summary.txt"
              WORKING_DIRECTORY "${TYGHBN_BUILD_DIR}"
              COMMENT "Generating code coverage report in ${TYGHBN_BUILD_DIR}/coverage_report"
            )
          endif()
        else()
          message(WARNING "gcovr not found — coverage target will not be created")
        endif()
      endif()
    elseif(MSVC)
      message(WARNING "Code coverage is not supported with MSVC")
    else()
      message(WARNING "Code coverage is not supported with ${CMAKE_CXX_COMPILER_ID}")
    endif()
  endif()

else()
  message(WARNING "Not building tests")
  message(WARNING "BUILD_TESTING is ${BUILD_TESTING}")
endif()

# Installation rules
if(TYGHBN_USE_MODULES)
  install(TARGETS or_else add_one
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    FILE_SET CXX_MODULES
    DESTINATION modules
    FILE_SET HEADERS
    DESTINATION include
  )
else()
  install(TARGETS or_else add_one
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    FILE_SET HEADERS
    DESTINATION include
  )
endif()

