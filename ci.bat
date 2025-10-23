@echo off
REM Windows CI script: створення каталогу, конфіг, збірка, тестування, помітити build.sh як виконуваний у git
setlocal

if not exist build (
  mkdir build
)
pushd build

REM Конфігурація
cmake .. -DCMAKE_BUILD_TYPE=Release

REM Білд (підтримка Visual Studio --config Release)
cmake --build . --config Release -- /m

REM Запуск тестів
ctest --output-on-failure -C Release

pause