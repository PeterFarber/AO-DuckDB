cmake_minimum_required(VERSION 3.20 FATAL_ERROR)

project(LUA_DUCKDB CXX)
set(CMAKE_STATIC_LIBRARY_PREFIX "")

# Source files
set(LUA_DUCKDB_SRC_FILES
	l_duckdb.cpp
)


# Create Jolt lib
add_library(l_duckdb ${LUA_DUCKDB_SRC_FILES})

set_target_properties(l_duckdb PROPERTIES
	CXX_STANDARD 17
	CXX_STANDARD_REQUIRED ON
	CXX_EXTENSIONS OFF
)
