# macOS-Build-Wrapper fuer SDR++-Out-of-tree-Module (angepasst aus CI sdrpp_module_hack.cmake)
# Linkt gegen die libsdrpp_core.dylib der installierten SDR++.app (install-name @rpath/...).

if (NOT SDRPP_CORE_ROOT)
    message(FATAL_ERROR "SDRPP_CORE_ROOT not set")
endif ()
if (NOT SDRPP_CORE_LIB)
    set(SDRPP_CORE_LIB "/Applications/SDR++.app/Contents/Frameworks/libsdrpp_core.dylib")
endif ()

set(SDRPP_MODULE_COMPILER_FLAGS -O3 $<$<COMPILE_LANGUAGE:CXX>:-std=c++17> -Wno-unused-command-line-argument)

# Brew-Prefix fuer transitive Header (volk, fftw3, GLFW, zstd) + libmirisdr
set(BREW /opt/homebrew)

link_directories(${BREW}/lib)

add_library(${PROJECT_NAME} SHARED ${SRC})
set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")

target_include_directories(${PROJECT_NAME} PRIVATE
    "${SDRPP_CORE_ROOT}/src/"
    "${SDRPP_CORE_ROOT}/src/imgui/"
    "${BREW}/include"
    "${BREW}/include/volk"
)

# Core-Symbole werden zur Laufzeit vom sdrpp-Host aufgeloest; trotzdem die dylib
# mitlinken, damit der Recorded-Dependency-Name @rpath/libsdrpp_core.dylib stimmt.
target_link_libraries(${PROJECT_NAME} PRIVATE "${SDRPP_CORE_LIB}")
target_link_options(${PROJECT_NAME} PRIVATE -undefined dynamic_lookup)

target_compile_options(${PROJECT_NAME} PRIVATE ${SDRPP_MODULE_COMPILER_FLAGS})

install(TARGETS ${PROJECT_NAME} DESTINATION lib/sdrpp/plugins)
