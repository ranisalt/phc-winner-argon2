include(CheckCSourceRuns)
enable_language(C)
if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_CLANG)
    set(CMAKE_REQUIRED_FLAGS "-msse -msse2")
endif()

check_c_source_runs("
    #include <emmintrin.h>
    int main ()
    {
        __m128d a, b;
        double vals[2] = {0};
        a = _mm_loadu_pd (vals);
        b = _mm_add_pd (a,a);
        _mm_storeu_pd (vals,b);
        return (0);
    }" SSE2_FOUND)
