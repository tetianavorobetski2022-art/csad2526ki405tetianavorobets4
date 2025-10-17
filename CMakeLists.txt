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

# Збір джерел: src/ і корінь
file(GLOB_RECURSE ALL_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/*.c"
    "${CMAKE_SOURCE_DIR}/*.cpp"
    "${CMAKE_SOURCE_DIR}/*.c"
)

# Знайти main-файли, щоб не включати їх у бібліотеку
file(GLOB_RECURSE MAIN_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/*main*.cpp"
    "${CMAKE_SOURCE_DIR}/*main*.cpp"
)

# Підготувати список для бібліотеки (ALL_SOURCES без MAIN_SOURCES)
set(LIB_SOURCES ${ALL_SOURCES})
if(MAIN_SOURCES)
    list(REMOVE_ITEM LIB_SOURCES ${MAIN_SOURCES})
endif()

# Якщо є джерела для бібліотеки — створюємо бібліотеку
if(LIB_SOURCES)
    add_library(${PROJECT_NAME}_lib STATIC ${LIB_SOURCES})
    target_include_directories(${PROJECT_NAME}_lib PUBLIC ${CMAKE_SOURCE_DIR})
    if(MSVC)
        target_compile_options(${PROJECT_NAME}_lib PRIVATE /W4 /permissive-)
    else()
        target_compile_options(${PROJECT_NAME}_lib PRIVATE -Wall -Wextra -Wpedantic)
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
    )
    # Завантажити і додати googletest
    FetchContent_MakeAvailable(googletest)

    # Створити тестовий виконуваний файл з наявного файла tests/unit_tests.cpp.
    # У вашому tests/unit_tests.cpp вже є власний main(), тому лінкуємо з GTest::gtest (не з gtest_main),
    # щоб не було конфлікту двох main.
    add_executable(${PROJECT_NAME}_tests
        tests/unit_tests.cpp
    )

    target_include_directories(${PROJECT_NAME}_tests PRIVATE ${CMAKE_SOURCE_DIR})

    # Лінкування: GTest (без gtest_main, оскільки main у тестах) і (за наявності) бібліотека проекту
    target_link_libraries(${PROJECT_NAME}_tests PRIVATE GTest::gtest)
    if(TARGET ${PROJECT_NAME}_lib)
        target_link_libraries(${PROJECT_NAME}_tests PRIVATE ${PROJECT_NAME}_lib)
    else()
        # Якщо не маєте окремої бібліотеки, додайте загальні джерела до тестів (щоб використовувати add())
        if(ALL_SOURCES)
            target_sources(${PROJECT_NAME}_tests PRIVATE ${ALL_SOURCES})
        endif()
    endif()

    if(MSVC)
        target_compile_options(${PROJECT_NAME}_tests PRIVATE /W4 /permissive-)
    else()
        target_compile_options(${PROJECT_NAME}_tests PRIVATE -Wall -Wextra -Wpedantic)
    endif()

    add_test(NAME unit_tests COMMAND ${PROJECT_NAME}_tests)
endif()

# Правила встановлення
if(TARGET ${PROJECT_NAME})
    install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
endif()
if(TARGET ${PROJECT_NAME}_lib)
    install(TARGETS ${PROJECT_NAME}_lib ARCHIVE DESTINATION lib)
endif()