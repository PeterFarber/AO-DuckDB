#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DUCKDB_DIR="${SCRIPT_DIR}/duckdb"
LUA_DUCKDB_DIR="${SCRIPT_DIR}/l_duckdb"
PROCESS_DIR="${SCRIPT_DIR}/aos/process"
LIBS_DIR="${PROCESS_DIR}/libs"

AO_IMAGE="p3rmaw3b/ao:0.1.2"

EMXX_CFLAGS="-sMEMORY64=1 /lua-5.3.4/src/liblua.a -I/lua-5.3.4/src -I/duckdb/src/include"

# Clone jolt if it doesn't exist
rm -rf ${DUCKDB_DIR}
if [ ! -d "${DUCKDB_DIR}" ]; then \
	git clone https://github.com/duckdb/duckdb.git ${DUCKDB_DIR}; \
	cd ${DUCKDB_DIR}; \
	cp ${SCRIPT_DIR}/inject/CMakeLists.txt ${DUCKDB_DIR}/CMakeLists.txt; \
	cp ${SCRIPT_DIR}/inject/Makefile ${DUCKDB_DIR}/Makefile; \
fi

# Make DuckDB
docker run -v ${DUCKDB_DIR}:/duckdb --platform linux/amd64 p3rmaw3b/ao:0.1.2  sh -c "cd /duckdb && make wasm_mvp"

# Fixing Permissions
sudo chmod -R 777 ${DUCKDB_DIR}

# Build lua jolt into a static library with emscripten
rm -rf ${LUA_DUCKDB_DIR}/build
docker run -v ${LUA_DUCKDB_DIR}:/l_duckdb -v ${DUCKDB_DIR}:/duckdb --platform linux/amd64 ${AO_IMAGE}  sh -c \
		"cd /l_duckdb && mkdir build && cd build && emcmake cmake -DCMAKE_CXX_FLAGS='${EMXX_CFLAGS}' -S .. -B ."

docker run -v ${LUA_DUCKDB_DIR}:/l_duckdb -v ${DUCKDB_DIR}:/duckdb --platform linux/amd64  ${AO_IMAGE} sh -c \
		"cd /l_duckdb/build && cmake --build ." 

# Fixing Permissions
sudo chmod -R 777 ${LUA_DUCKDB_DIR}

# Copy DuckDB to the libs directory
rm -rf ${LIBS_DIR}
mkdir -p $LIBS_DIR
find ./ -name '*.a' -exec cp {} ${LIBS_DIR} \;
cp ${LUA_DUCKDB_DIR}/build/l_duckdb.a ${LIBS_DIR}/l_duckdb.a
rm -f ${LIBS_DIR}/libduckdb_static.a

# Copy config.yml to the process directory
cp ${SCRIPT_DIR}/config.yml ${PROCESS_DIR}/config.yml

# Build the process module
cd ${PROCESS_DIR} 
docker run -e DEBUG=1 --platform linux/amd64 -v ./:/src ${AO_IMAGE} ao-build-module

# Copy the process module to the tests directory
cp ${PROCESS_DIR}/process.wasm ${SCRIPT_DIR}/tests/process.wasm
cp ${PROCESS_DIR}/process.js ${SCRIPT_DIR}/tests/process.js