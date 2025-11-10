#!/bin/bash
# =============================
# Linux CI build script
# 1. Створює build-каталог (якщо його нема)
# 2. Конфігурує CMake (Release)
# 3. Збирає проект
# 4. Запускає тести
# 5. Встановлює прапорець виконання цього файлу у git
# =============================

set -e  # зупинятись при будь-якій помилці
set -o pipefail

echo "[STEP] Creating build directory..."
mkdir -p build
cd build

echo "[STEP] Configuring project..."
cmake .. -DCMAKE_BUILD_TYPE=Release

echo "[STEP] Building project..."
cmake --build . --config Release -j"$(nproc)"

echo "[STEP] Running tests..."
ctest --output-on-failure -C Release

echo "[DONE] All steps completed successfully."
