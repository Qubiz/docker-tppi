cmake_minimum_required(VERSION 3.7)
project(tppi)

set(CMAKE_CXX_STANDARD 14)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread -g -O0")

add_executable(tppi_server server.cpp)
target_link_libraries(tppi_server muduo_base muduo_net)

add_executable(tppi_client client.cpp)
target_link_libraries(tppi_client muduo_base muduo_net)
