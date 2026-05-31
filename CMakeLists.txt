cmake_minimum_required(VERSION 3.15)
project(voidImageViewer C)

set(CMAKE_C_STANDARD 99)

# Define static library for WebP
add_library(webp STATIC)

# WebP Include directories (only standard webp folders, NOT src!)
target_include_directories(webp PRIVATE
    libwebp
    libwebp/src
)

# WebP Source files
file(GLOB WEBP_DEC_SOURCES libwebp/src/dec/*.c)
file(GLOB WEBP_DEMUX_SOURCES libwebp/src/demux/*.c)
file(GLOB WEBP_DSP_SOURCES libwebp/src/dsp/*.c)
file(GLOB WEBP_UTILS_SOURCES libwebp/src/utils/*.c)

target_sources(webp PRIVATE
    ${WEBP_DEC_SOURCES}
    ${WEBP_DEMUX_SOURCES}
    ${WEBP_DSP_SOURCES}
    ${WEBP_UTILS_SOURCES}
)

# Source files from src
file(GLOB VIV_SOURCES src/*.c)

# Resource file
set(VIV_RC res/voidImageViewer.rc)

# Target
add_executable(voidImageViewer
    ${VIV_SOURCES}
    ${VIV_RC}
)

# Application Include directories (only for voidImageViewer!)
target_include_directories(voidImageViewer PRIVATE
    src
    libwebp
    libwebp/src
)

# Compile definitions for voidImageViewer
target_compile_definitions(voidImageViewer PRIVATE
    UNICODE
    _UNICODE
    WIN32
    NDEBUG
    _WINDOWS
    BZ_NO_STDIO
    VERSION_X64
)

# Link options to make it a Windows GUI app (not console app)
set_target_properties(voidImageViewer PROPERTIES LINK_FLAGS "-mwindows")

# Link libraries
target_link_libraries(voidImageViewer PRIVATE
    webp
    comctl32
    shlwapi
    ole32
    uuid
    gdiplus
    comdlg32
    shell32
    gdi32
    user32
    kernel32
    winmm
    opengl32
)
