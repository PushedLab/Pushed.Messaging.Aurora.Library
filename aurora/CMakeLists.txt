cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME pushed_messaging)
set(PLUGIN_NAME  pushed_messaging_platform_plugin)

project(${PROJECT_NAME} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_CXX_FLAGS "-Wall -Wextra -Wno-psabi")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

set(APP_ID_PATH /usr/share/${PROJECT_NAME}) 
set(APP_ID_FILE applicationidz)

add_definitions(-DDBUS_SERVICE="com.example.pushed_demo_aurora")
add_definitions(-DDBUS_PATH="com/example/pushed_demo_aurora")
add_definitions(-DDBUS_INTERFACE="com.example.pushed_demo_aurora")
add_definitions(-DAPP_ID_FILE_PATH="${APP_ID_PATH}/${APP_ID_FILE}")

find_package(PkgConfig REQUIRED)
find_package(Qt5 COMPONENTS Core Network DBus REQUIRED)

pkg_check_modules(FlutterEmbedder REQUIRED IMPORTED_TARGET flutter-embedder)
pkg_check_modules(NemoNotifications-Qt5 REQUIRED IMPORTED_TARGET nemonotifications-qt5)
pkg_check_modules(PushClient REQUIRED IMPORTED_TARGET pushclient)

add_library(${PLUGIN_NAME} SHARED 
            include/pushed_messaging/plugincontroller.cpp
            include/pushed_messaging/pluginservice.cpp
            pushed_messaging_plugin.cpp)

set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)

target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::FlutterEmbedder)
target_link_libraries(${PLUGIN_NAME} PUBLIC Qt5::Core Qt5::Network Qt5::DBus)
target_link_libraries(${PLUGIN_NAME} PUBLIC PkgConfig::NemoNotifications-Qt5)
target_link_libraries(${PLUGIN_NAME} PUBLIC PkgConfig::PushClient)

target_include_directories(${PLUGIN_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_compile_definitions(${PLUGIN_NAME} PRIVATE PLUGIN_IMPL)
