cmake_minimum_required(VERSION 3.20)
project(coldmanual LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Optimization: Limit GCC memory consumption
# -O2 uses substantially less compiler memory than -O3 while preserving full release performance
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(CMAKE_CXX_FLAGS_RELEASE "-O2 -DNDEBUG" CACHE STRING "" FORCE)
endif()

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Gui
    Quick
    Qml
    QuickControls2
    QuickEffects
    Sql
    Network
    Svg
    Concurrent
)

find_package(LibArchive REQUIRED)

# Shared Core Object Library: Compiled EXACTLY ONCE for both coldmanual and test_core
# Prevents duplicating compilation of all core cpp files and large qrc_resources.cpp
add_library(coldmanual_core OBJECT
    src/core/CatalogItem.h
    src/core/DocCatalogManager.h
    src/core/DocCatalogManager.cpp
    src/core/DocsetDownloader.h
    src/core/DocsetDownloader.cpp
    src/core/DocsetManager.h
    src/core/DocsetManager.cpp
    src/core/DocsetSearchEngine.h
    src/core/DocsetSearchEngine.cpp
    src/core/SettingsManager.h
    src/core/SettingsManager.cpp
    src/core/NetworkManager.h
    src/core/NetworkManager.cpp
    src/core/WindowsFramelessHelper.h
    src/core/WindowsFramelessHelper.cpp
    resources.qrc
)

target_include_directories(coldmanual_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
    ${LibArchive_INCLUDE_DIRS}
)

target_link_libraries(coldmanual_core PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::QuickControls2
    Qt6::QuickEffects
    Qt6::Sql
    Qt6::Network
    Qt6::Svg
    Qt6::Concurrent
    ${LibArchive_LIBRARIES}
)

if(WIN32)
    target_link_libraries(coldmanual_core PUBLIC dwmapi gdi32 wininet comctl32 psapi)
endif()

# Precompile common Qt headers to drastically cut down GCC memory & time per unit
target_precompile_headers(coldmanual_core PRIVATE
    <QtCore>
    <QtGui>
    <QtQuick>
    <QString>
    <QObject>
    <QSqlDatabase>
)

# Main Application Executable
set(APP_SOURCES
    src/main.cpp
)
if(WIN32)
    list(APPEND APP_SOURCES resources/app.rc)
endif()

add_executable(coldmanual WIN32
    ${APP_SOURCES}
    $<TARGET_OBJECTS:coldmanual_core>
)
target_link_libraries(coldmanual PRIVATE coldmanual_core)

# Automated Test Executable
add_executable(test_core
    tests/test_core.cpp
    $<TARGET_OBJECTS:coldmanual_core>
)
target_link_libraries(test_core PRIVATE coldmanual_core)
