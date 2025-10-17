#include <iostream>
#include <cstdlib>

// Підключіть заголовок; якщо ваш math_operations.h знаходиться в іншому місці,
// змініть шлях відповідно (наприклад: "../include/math_operations.h").
#include "../math_operations.h"

static int run_tests() {
    int failed = 0;

    // Тест 1: просте додавання
    if (add(2, 3) != 5) {
        std::cerr << "FAIL: add(2, 3) != 5\n";
        ++failed;
    }

    // Тест 2: нулі
    if (add(0, 0) != 0) {
        std::cerr << "FAIL: add(0, 0) != 0\n";
        ++failed;
    }

    // Тест 3: від'ємні числа
    if (add(-4, -6) != -10) {
        std::cerr << "FAIL: add(-4, -6) != -10\n";
        ++failed;
    }

    // Тест 4: змішані знаки
    if (add(7, -2) != 5) {
        std::cerr << "FAIL: add(7, -2) != 5\n";
        ++failed;
    }

    // Тест 5: великі значення (без перевірки переповнення)
    if (add(100000, 200000) != 300000) {
        std::cerr << "FAIL: add(100000, 200000) != 300000\n";
        ++failed;
    }

    return failed;
}

int main() {
    int failed = run_tests();
    if (failed == 0) {
        std::cout << "All tests passed.\n";
        return 0;
    } else {
        std::cerr << failed << " test(s) failed.\n";
        return EXIT_FAILURE;
    }
}