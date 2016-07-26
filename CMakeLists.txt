cmake_minimum_required(VERSION 2.8)

# disable in-source builds to prevent cluttering
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
set(CMAKE_DISABLE_SOURCE_CHANGES ON)

project(phc_winner_argon2 C)

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

# select build type with `cmake -DCMAKE_BUILD_TYPE=type`
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -std=c89 -Wall -Wextra -Werror -Wno-type-limits")
set(CMAKE_C_FLAGS_DEBUG "-O0 -g -coverage")
set(CMAKE_C_FLAGS_MINSIZEREL "-Os -DNDEBUG")
set(CMAKE_C_FLAGS_RELEASE "-O3 -march=native -DNDEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O2 -g")

find_package(Threads REQUIRED)

set(ARGON2_SRC
    src/argon2.c
    src/blake2/blake2b.c
    src/core.c
    src/encoding.c
    src/thread.c)

# check to compile optimized version based on SSE2 support
find_package(SSE2)
if(SSE2_FOUND)
    set(ARGON2_SRC ${ARGON2_SRC} src/opt.c)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -msse -msse2")
else()
    set(ARGON2_SRC ${ARGON2_SRC} src/ref.c)
endif()

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fvisibility=hidden")
elseif(CMAKE_SYSTEM_NAME MATCHES "SunOS")
    add_definitions(-D_REENTRANT)
endif()

if(CMAKE_COMPILER_IS_CLANG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=address -fsanitize=undefined")
endif()

# select shared lib with `cmake -DBUILD_SHARED_LIBS=ON`
add_library(argon2 ${ARGON2_SRC})
target_link_libraries(argon2 ${CMAKE_THREAD_LIBS_INIT})
set_property(TARGET argon2 PROPERTY DEFINE_SYMBOL A2_VISCTL)
set_property(TARGET argon2 PROPERTY SOVERSION 0)

add_executable(bench_exe src/bench.c)
target_link_libraries(bench_exe argon2)
add_custom_target(bench COMMAND bench_exe)

if(BUILD_TESTING)
    enable_testing()
    # force debug build for `assert(...)`
    set(CMAKE_BUILD_TYPE Debug)

    if($ENV{CI})
        add_definitions(-D_FORTIFY_SOURCE=2 -DTEST_LARGE_RAM)
    endif()

    add_executable(test_exe src/test.c)
    target_link_libraries(test_exe argon2)
    add_test(Argon2 test_exe)
endif()
