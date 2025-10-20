cmake_minimum_required(VERSION 3.16)

# Ім'я проекту — взято з імені папки репозиторію
get_filename_component(PROJECT_NAME ${CMAKE_SOURCE_DIR} NAME)
project(${PROJECT_NAME} LANGUAGES CXX)

# Стандарт C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Вивід виконуваних файлів у bin/
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Для multi-config генераторів (Visual Studio) встановити директорії для кожної конфігурації
if(CMAKE_CONFIGURATION_TYPES)
  foreach(cfg ${CMAKE_CONFIGURATION_TYPES})
    string(TOUPPER "${cfg}" cfg_u)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${cfg_u} ${CMAKE_BINARY_DIR}/bin/${cfg})
  endforeach()
endif()



# Автоматичний пошук .cpp файлів у корені проекту та в src/, якщо змінні не задані
if(NOT DEFINED ALL_SOURCES)
    file(GLOB_RECURSE ALL_SOURCES CONFIGURE_DEPENDS
        "${CMAKE_SOURCE_DIR}/*.cpp"
        "${CMAKE_SOURCE_DIR}/src/*.cpp"
    )

    # Виключити директорії збірки й зовнішні залежності
    list(FILTER ALL_SOURCES EXCLUDE REGEX "(/|\\\\)(build|_deps|googletest|CMakeFiles|tests)(/|\\\\)")
endif()

if(NOT DEFINED MAIN_SOURCES)
    set(MAIN_SOURCES "")
    foreach(_f IN LISTS ALL_SOURCES)
        get_filename_component(_name ${_f} NAME)
        if(_name STREQUAL "main.cpp")
            list(APPEND MAIN_SOURCES ${_f})
        endif()
    endforeach()
    # Якщо немає знайдених main.cpp, але є main.cpp у корені — додати його
    if(MAIN_SOURCES STREQUAL "" AND EXISTS "${CMAKE_SOURCE_DIR}/main.cpp")
        set(MAIN_SOURCES "${CMAKE_SOURCE_DIR}/main.cpp")
    endif()
endif()

if(NOT DEFINED LIB_SOURCES)
    set(LIB_SOURCES ${ALL_SOURCES})
    if(MAIN_SOURCES)
        foreach(_m IN LISTS MAIN_SOURCES)
            list(REMOVE_ITEM LIB_SOURCES ${_m})
        endforeach()
    endif()
endif()

# Якщо є main-файли — створюємо виконуваний файл і лінкуємо з бібліотекою (якщо є)
if(MAIN_SOURCES)
    add_executable(${PROJECT_NAME} ${MAIN_SOURCES})
    target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR})
    if(TARGET ${PROJECT_NAME}_lib)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJECT_NAME}_lib)
    endif()
endif()

if(NOT LIB_SOURCES AND NOT MAIN_SOURCES)
    message(WARNING "No source files found. Додайте файли в src/ або корінь проекту (*.cpp).")
endif()

# Тести — якщо увімкнені
option(BUILD_TESTS "Enable building of tests" ON)
if(BUILD_TESTS AND EXISTS "${CMAKE_SOURCE_DIR}/tests/unit_tests.cpp")
    enable_testing()

    include(FetchContent)
    FetchContent_Declare(
      googletest
      URL https://github.com/google/googletest/archive/refs/heads/main.zip
      DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
    # Завантажити і додати googletest
    FetchContent_MakeAvailable(googletest)

    add_executable(${PROJECT_NAME}_tests
        tests/unit_tests.cpp
    )

    target_include_directories(${PROJECT_NAME}_tests PRIVATE ${CMAKE_SOURCE_DIR})

    # Лінкування: GTest main (надає main) і (за наявності) бібліотека проекту
    target_link_libraries(${PROJECT_NAME}_tests PRIVATE GTest::gtest_main)
    if(TARGET ${PROJECT_NAME}_lib)
        target_link_libraries(${PROJECT_NAME}_tests PRIVATE ${PROJECT_NAME}_lib)
    else()
        # Якщо не маєте окремої бібліотеки, додайте бібліотечні джерела (без main) до тестів
        if(LIB_SOURCES)
            target_sources(${PROJECT_NAME}_tests PRIVATE ${LIB_SOURCES})
        endif()
    endif()

    if(MSVC)
        target_compile_options(${PROJECT_NAME}_tests PRIVATE /W4 /permissive-)
    else()
        target_compile_options(${PROJECT_NAME}_tests PRIVATE -Wall -Wextra -Wpedantic)
    endif()

    # Використовувати TARGET_FILE у add_test, щоб CTest знав точний шлях у multi-config
    add_test(NAME unit_tests COMMAND $<TARGET_FILE:${PROJECT_NAME}_tests>)
endif()

# Правила встановлення
if(TARGET ${PROJECT_NAME})
    install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
endif()
if(TARGET ${PROJECT_NAME}_lib)
    install(TARGETS ${PROJECT_NAME}_lib ARCHIVE DESTINATION lib)
endif()