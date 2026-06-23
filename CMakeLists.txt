cmake_minimum_required(VERSION 3.16)
project(DRAMBender VERSION 0.1.0 LANGUAGES CXX)

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

option(BUILD_TESTING "Build optional test and benchmark targets" OFF)
option(DRAMBENDER_BUILD_PYTHON "Build Python bindings" ON)
option(DRAMBENDER_BUILD_EXAMPLES "Build board-facing example binaries" OFF)
option(DRAMBENDER_BUILD_BOARD_TESTS "Build board-facing test binaries" OFF)
option(DRAMBENDER_BUILD_BOARD_BENCHMARKS "Build board-facing benchmark binaries" OFF)
set(DRAMBENDER_PYTHON_PACKAGE_DIR ""
    CACHE PATH "Output directory for the drambender Python package")

set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "")

if (NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(Threads REQUIRED)

add_library(DRAMBender
  src/api/host_interface/host_interface.cpp
  src/api/host_interface/xdma.cpp
  src/api/board/DDR4.cpp
  src/api/board/HBM2.cpp
  src/api/board/board.cpp
  src/api/program/instruction.cpp
  src/api/program/program.cpp
  src/utils/utils.cpp
  src/utils/vm.cpp
)

add_library(DRAMBender::DRAMBender ALIAS DRAMBender)

target_include_directories(DRAMBender
  PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(DRAMBender
  PUBLIC
  Threads::Threads
)

target_compile_options(DRAMBender
  PRIVATE
  -Wall
  -Wextra
  -Wpedantic
)

install(
  TARGETS DRAMBender
  EXPORT DRAMBenderTargets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT development
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT runtime NAMELINK_COMPONENT development
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT runtime
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(
  DIRECTORY include/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  COMPONENT development
)

set(DRAMBENDER_CMAKE_INSTALL_DIR
    "${CMAKE_INSTALL_LIBDIR}/cmake/DRAMBender")

install(
  EXPORT DRAMBenderTargets
  NAMESPACE DRAMBender::
  DESTINATION ${DRAMBENDER_CMAKE_INSTALL_DIR}
  COMPONENT development
)

configure_package_config_file(
  cmake/DRAMBenderConfig.cmake.in
  "${CMAKE_CURRENT_BINARY_DIR}/DRAMBenderConfig.cmake"
  INSTALL_DESTINATION ${DRAMBENDER_CMAKE_INSTALL_DIR}
)

write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/DRAMBenderConfigVersion.cmake"
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

install(
  FILES
    "${CMAKE_CURRENT_BINARY_DIR}/DRAMBenderConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/DRAMBenderConfigVersion.cmake"
  DESTINATION ${DRAMBENDER_CMAKE_INSTALL_DIR}
  COMPONENT development
)

if (DRAMBENDER_BUILD_EXAMPLES)
  add_executable(drambender_example_single_sided_rowhammer
    examples/single_sided_rowhammer.cpp
  )
  target_link_libraries(drambender_example_single_sided_rowhammer PRIVATE DRAMBender)

  add_executable(drambender_example_read_write
    examples/read_write.cpp
  )
  target_link_libraries(drambender_example_read_write PRIVATE DRAMBender)
endif()

if (DRAMBENDER_BUILD_BOARD_BENCHMARKS)
  add_executable(drambender_board_single_sided_rowhammer_bench
    tests/jit_benchmark/single_sided_rowhammer_bench.cpp
  )
  target_link_libraries(drambender_board_single_sided_rowhammer_bench PRIVATE DRAMBender)

  add_executable(drambender_board_read_write_bench
    tests/jit_benchmark/read_write_bench.cpp
  )
  target_link_libraries(drambender_board_read_write_bench PRIVATE DRAMBender)
endif()

if (BUILD_TESTING)
  enable_testing()

  add_executable(drambender_program_metadata_test
    tests/program_metadata_test.cpp
  )
  target_link_libraries(drambender_program_metadata_test PRIVATE DRAMBender)
  add_test(NAME drambender_program_metadata_test COMMAND drambender_program_metadata_test)

  if (DRAMBENDER_BUILD_BOARD_TESTS)
    add_executable(drambender_rw_test
      tests/board_tests/rw_test.cpp
    )
    target_link_libraries(drambender_rw_test PRIVATE DRAMBender)
  endif()

  add_executable(drambender_jit_native_benchmark
    tests/jit_benchmark/jit_native_baseline.cpp
  )
  target_link_libraries(drambender_jit_native_benchmark PRIVATE DRAMBender)
endif()

if (DRAMBENDER_BUILD_PYTHON)
  include(FetchContent)

  if (CMAKE_VERSION VERSION_LESS 3.18)
    set(DEV_MODULE Development)
  else()
    set(DEV_MODULE Development.Module)
  endif()

  find_package(Python 3.9 COMPONENTS Interpreter ${DEV_MODULE} REQUIRED)
  find_package(nanobind CONFIG QUIET)
  if (NOT nanobind_FOUND)
    FetchContent_Declare(
      nanobind
      GIT_REPOSITORY https://github.com/wjakob/nanobind.git
      GIT_TAG        v2.12.0
      GIT_SHALLOW    TRUE
    )
    FetchContent_MakeAvailable(nanobind)
  endif()

  if (DRAMBENDER_PYTHON_PACKAGE_DIR)
    set(_drambender_python_package_dir "${DRAMBENDER_PYTHON_PACKAGE_DIR}")
  else()
    set(_drambender_python_package_dir
        "${CMAKE_CURRENT_BINARY_DIR}/python/drambender")
  endif()

  file(MAKE_DIRECTORY "${_drambender_python_package_dir}")

  nanobind_add_module(drambender_core
    src/bindings/python/_core.cpp
  )

  set_target_properties(drambender_core PROPERTIES
    OUTPUT_NAME "_core"
    LIBRARY_OUTPUT_DIRECTORY "${_drambender_python_package_dir}"
  )

  target_include_directories(drambender_core
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/src/bindings/python
  )

  target_link_libraries(drambender_core
    PRIVATE
    DRAMBender
  )

  install(
    TARGETS drambender_core
    LIBRARY DESTINATION drambender COMPONENT python
    RUNTIME DESTINATION drambender COMPONENT python
  )

endif()
