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

# Збір джерел: спочатку src/, якщо немає — корінь
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
    # Не намагатись збирати googletest як частину інтернет-відключеного середовища
    FetchContent_MakeAvailable(googletest)

    # Створити виконуваний файл для тестів
    add_executable(${PROJECT_NAME}_tests
        tests/unit_tests.cpp
    )

    # Забезпечити інклюди для тестів (щоб #include "../math_operations.h" / інші працювали)
    target_include_directories(${PROJECT_NAME}_tests PRIVATE ${CMAKE_SOURCE_DIR})

    # Якщо є бібліотека проекту — лінкуємо тести з нею, інакше додаємо всі джерела проекту в тестовий таргет
    if(TARGET ${PROJECT_NAME}_lib)
        target_link_libraries(${PROJECT_NAME}_tests PRIVATE GTest::gtest_main ${PROJECT_NAME}_lib)
    else()
        # Якщо немає окремої бібліотеки, підключаємо загальні джерела прямо до тестів
        if(ALL_SOURCES)
            target_sources(${PROJECT_NAME}_tests PRIVATE ${ALL_SOURCES})
        endif()
        target_link_libraries(${PROJECT_NAME}_tests PRIVATE GTest::gtest_main)
    endif()

    if(MSVC)
        target_compile_options(${PROJECT_NAME}_tests PRIVATE /W4 /permissive-)
    else()
        target_compile_options(${PROJECT_NAME}_tests PRIVATE -Wall -Wextra -Wpedantic)
    endif()

    # Додати тест до CTest
    add_test(NAME unit_tests COMMAND ${PROJECT_NAME}_tests)
endif()

# Правила встановлення
if(TARGET ${PROJECT_NAME})
    install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
endif()
if(TARGET ${PROJECT_NAME}_lib)
    install(TARGETS ${PROJECT_NAME}_lib ARCHIVE DESTINATION lib)
endif()