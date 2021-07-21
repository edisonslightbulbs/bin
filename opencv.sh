
BUILD_DIR="opencv/build"

if [ -d "$BUILD_DIR" ]; then rm -rf "$BUILD_DIR"; fi

mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR" || return

SOURCES_DIR=$(dirname $(dirname $(dirname $(readlink -f "$0"))))
OPENCV_DIR=$(dirname $(dirname $(readlink -f "$0")))

OPENCV_CONTRIB_DIR="$SOURCES_DIR/opencv_contrib/modules"

# echo "$SOURCES_DIR"
# echo "$OPENCV_DIR"
# echo "$OPENCV_CONTRIB_DIR"

cmake -DOPENCV_EXTRA_MODULES_PATH="$OPENCV_CONTRIB_DIR" "$OPENCV_DIR" -DBUILD_opencv_sfm=OFF
make
sudo make install
sudo ldconfig

# add_definitions(-D_GLIBCXX_USE_CXX11_ABI=0)
#   -- add this in opencv CMakeLists.txt
