cmake_minimum_required(VERSION 3.16)
project(DRAMInspector VERSION 0.1.0 LANGUAGES CXX)

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

option(BUILD_TESTING "Build optional test and benchmark targets" OFF)
option(DRAMINSPECTOR_BUILD_PYTHON "Build Python bindings" ON)
option(DRAMINSPECTOR_BUILD_EXAMPLES "Build board-facing example binaries" OFF)
option(DRAMINSPECTOR_BUILD_BOARD_TESTS "Build board-facing test binaries" OFF)
option(DRAMINSPECTOR_BUILD_BOARD_BENCHMARKS "Build board-facing benchmark binaries" OFF)
set(DRAMINSPECTOR_PYTHON_PACKAGE_DIR ""
    CACHE PATH "Output directory for the draminspector Python package")

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

add_library(DRAMInspector
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

add_library(DRAMInspector::DRAMInspector ALIAS DRAMInspector)

target_include_directories(DRAMInspector
  PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(DRAMInspector
  PUBLIC
  Threads::Threads
)

target_compile_options(DRAMInspector
  PRIVATE
  -Wall
  -Wextra
  -Wpedantic
)

install(
  TARGETS DRAMInspector
  EXPORT DRAMInspectorTargets
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

set(DRAMINSPECTOR_CMAKE_INSTALL_DIR
    "${CMAKE_INSTALL_LIBDIR}/cmake/DRAMInspector")

install(
  EXPORT DRAMInspectorTargets
  NAMESPACE DRAMInspector::
  DESTINATION ${DRAMINSPECTOR_CMAKE_INSTALL_DIR}
  COMPONENT development
)

configure_package_config_file(
  cmake/DRAMInspectorConfig.cmake.in
  "${CMAKE_CURRENT_BINARY_DIR}/DRAMInspectorConfig.cmake"
  INSTALL_DESTINATION ${DRAMINSPECTOR_CMAKE_INSTALL_DIR}
)

write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/DRAMInspectorConfigVersion.cmake"
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

install(
  FILES
    "${CMAKE_CURRENT_BINARY_DIR}/DRAMInspectorConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/DRAMInspectorConfigVersion.cmake"
  DESTINATION ${DRAMINSPECTOR_CMAKE_INSTALL_DIR}
  COMPONENT development
)

if (DRAMINSPECTOR_BUILD_EXAMPLES)
  add_executable(draminspector_example_single_sided_rowhammer
    examples/single_sided_rowhammer.cpp
  )
  target_link_libraries(draminspector_example_single_sided_rowhammer PRIVATE DRAMInspector)

  add_executable(draminspector_example_read_write
    examples/read_write.cpp
  )
  target_link_libraries(draminspector_example_read_write PRIVATE DRAMInspector)
endif()

if (DRAMINSPECTOR_BUILD_BOARD_BENCHMARKS)
  add_executable(draminspector_board_single_sided_rowhammer_bench
    tests/jit_benchmark/single_sided_rowhammer_bench.cpp
  )
  target_link_libraries(draminspector_board_single_sided_rowhammer_bench PRIVATE DRAMInspector)

  add_executable(draminspector_board_read_write_bench
    tests/jit_benchmark/read_write_bench.cpp
  )
  target_link_libraries(draminspector_board_read_write_bench PRIVATE DRAMInspector)
endif()

if (BUILD_TESTING)
  if (DRAMINSPECTOR_BUILD_BOARD_TESTS)
    add_executable(draminspector_rw_test
      tests/board_tests/rw_test.cpp
    )
    target_link_libraries(draminspector_rw_test PRIVATE DRAMInspector)
  endif()

  add_executable(draminspector_jit_native_benchmark
    tests/jit_benchmark/jit_native_baseline.cpp
  )
  target_link_libraries(draminspector_jit_native_benchmark PRIVATE DRAMInspector)
endif()

if (DRAMINSPECTOR_BUILD_PYTHON)
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

  if (DRAMINSPECTOR_PYTHON_PACKAGE_DIR)
    set(_draminspector_python_package_dir "${DRAMINSPECTOR_PYTHON_PACKAGE_DIR}")
  else()
    set(_draminspector_python_package_dir
        "${CMAKE_CURRENT_BINARY_DIR}/python/draminspector")
  endif()

  file(MAKE_DIRECTORY "${_draminspector_python_package_dir}")

  nanobind_add_module(draminspector_core
    src/bindings/python/_core.cpp
  )

  set_target_properties(draminspector_core PROPERTIES
    OUTPUT_NAME "_core"
    LIBRARY_OUTPUT_DIRECTORY "${_draminspector_python_package_dir}"
  )

  target_include_directories(draminspector_core
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/src/bindings/python
  )

  target_link_libraries(draminspector_core
    PRIVATE
    DRAMInspector
  )

  install(
    TARGETS draminspector_core
    LIBRARY DESTINATION draminspector COMPONENT python
    RUNTIME DESTINATION draminspector COMPONENT python
  )

endif()
