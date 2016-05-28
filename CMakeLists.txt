cmake_minimum_required(VERSION 3.5)
project(edge C ASM_NASM)

add_executable(${PROJECT_NAME} main.c canny.nasm)
target_link_libraries(${PROJECT_NAME} m)
