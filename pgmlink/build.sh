if [[ "$CPLEX_ROOT_DIR" == "<UNDEFINED>" || "$CPLEX_ROOT_DIR" == "" ]]; then
    # Look for CPLEX_ROOT_DIR in the cplex-shared cache file.
    CPLEX_LOCATION_CACHE_FILE="${PREFIX}/../../share/cplex-root-dir.path"
    CPLEX_ROOT_DIR=`cat ${CPLEX_LOCATION_CACHE_FILE} 2> /dev/null` \
    || CPLEX_ROOT_DIR="<UNDEFINED>"
fi

if [ "$CPLEX_ROOT_DIR" == "<UNDEFINED>" ]; then
    set +x
    echo "******************************************"
    echo "* You must define CPLEX_ROOT_DIR in your *"
    echo "* environment before building pgmlink.   *"
    echo "******************************************"
    exit 1
fi

CFLAGS=""
CXXFLAGS=""
LDFLAGS=""

LINKER_FLAGS="-L${PREFIX}/lib"
if [ `uname` != "Darwin" ]; then
    LINKER_FLAGS="-Wl,-rpath-link,${PREFIX}/lib ${LINKER_FLAGS}"
fi

mkdir build
cd build
cmake ..\
    -DCMAKE_C_COMPILER=${PREFIX}/bin/gcc \
    -DCMAKE_CXX_COMPILER=${PREFIX}/bin/g++ \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.7\
    -DCMAKE_INSTALL_PREFIX=${PREFIX}\
    -DCMAKE_PREFIX_PATH=${PREFIX}\
    -DCMAKE_SHARED_LINKER_FLAGS="${LINKER_FLAGS}" \
    -DCMAKE_EXE_LINKER_FLAGS="${LINKER_FLAGS}" \
    -DBUILD_SHARED_LIBS=ON\
    -DWITH_PYTHON=ON\
    -DWITH_CHECKED_STL=OFF\
    -DWITH_TESTS=ON\
    -DCPLEX_ROOT_DIR="${CPLEX_ROOT_DIR}"

make -j${CPU_COUNT}
make install

CPLEX_LIB_DIR=`echo $CPLEX_ROOT_DIR/cplex/lib/*/static_pic`
CONCERT_LIB_DIR=`echo $CPLEX_ROOT_DIR/concert/lib/*/static_pic`

if [ `uname` == "Darwin" ]; then
    # Set install names according using @rpath, which will be configured via the post-link script.
    install_name_tool -change ${CPLEX_LIB_DIR}/libcplex.dylib @rpath/libcplex.dylib ${PREFIX}/lib/libpgmlink.dylib
    install_name_tool -change ${CPLEX_LIB_DIR}/libilocplex.dylib @rpath/libilocplex.dylib ${PREFIX}/lib/libpgmlink.dylib
    install_name_tool -change ${CONCERT_LIB_DIR}/libconcert.dylib @rpath/libconcert.dylib ${PREFIX}/lib/libpgmlink.dylib

    install_name_tool -change ${CPLEX_LIB_DIR}/libcplex.dylib @rpath/libcplex.dylib ${PREFIX}/lib/python2.7/site-packages/pgmlink.so
    install_name_tool -change ${CPLEX_LIB_DIR}/libilocplex.dylib @rpath/libilocplex.dylib ${PREFIX}/lib/python2.7/site-packages/pgmlink.so
    install_name_tool -change ${CONCERT_LIB_DIR}/libconcert.dylib @rpath/libconcert.dylib ${PREFIX}/lib/python2.7/site-packages/pgmlink.so
fi
