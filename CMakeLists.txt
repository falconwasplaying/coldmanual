cmake_minimum_required(VERSION 3.20)
project(coldmanual LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Gui
    Quick
    Qml
    QuickControls2
    Sql
    Network
    Svg
    Concurrent
)

find_package(LibArchive REQUIRED)

set(SOURCES
    src/main.cpp
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
    resources.qrc
)

add_executable(coldmanual WIN32 ${SOURCES})

target_include_directories(coldmanual PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
    ${LibArchive_INCLUDE_DIRS}
)

target_link_libraries(coldmanual PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::QuickControls2
    Qt6::Sql
    Qt6::Network
    Qt6::Svg
    Qt6::Concurrent
    ${LibArchive_LIBRARIES}
)

# if(WIN32)
#     set_target_properties(coldmanual PROPERTIES
#         WIN32_EXECUTABLE TRUE
#     )
# endif()

# Automated test executable
add_executable(test_core
    tests/test_core.cpp
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
    resources.qrc
)

target_include_directories(test_core PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
    ${LibArchive_INCLUDE_DIRS}
)

target_link_libraries(test_core PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::QuickControls2
    Qt6::Sql
    Qt6::Network
    Qt6::Svg
    Qt6::Concurrent
    ${LibArchive_LIBRARIES}
)
