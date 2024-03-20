#!/usr/bin/env bash

set -e

if ! [ -d "$JAVA_HOME" ] ; then
  echo "## $0: Set JAVA_HOME to JDK 22" 1>&2
  exit 2
fi
export PATH="$JAVA_HOME/bin:$PATH"
javaVersion="$(java --version)"
javaVersionNum="$(echo "$javaVersion" | sed -n '1s|.* \([^ ][^ ]*\) .*|\1|p')"
if ! [ "22" == "${javaVersionNum}" ] ; then
  echo "## $0: Unable to verify java 22." 
  echo " # got: $javaVersionNum"
  echo " # from: $javaVersion"
  exit 3
fi 1>&2

cd "$(dirname $0)"
BENCHMARK_DIR="$(pwd)"

# Build Java
mvn clean verify

# Build Native
cd "$BENCHMARK_DIR/src/main/native"
rm -rf "cmake-build-release"
mkdir "cmake-build-release"
cd "cmake-build-release"
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .

# run
cd "$BENCHMARK_DIR"
mkdir -p logs

java_options=(
  --enable-preview
  --enable-native-access=ALL-UNNAMED
  --add-modules=jdk.incubator.vector
  --add-opens=java.base/java.lang=ALL-UNNAMED
  --add-opens=java.base/jdk.internal.misc=ALL-UNNAMED
  -Xms4g -Xmx4g
  "-Dorg.glavo.benchmark.libpath=$BENCHMARK_DIR/src/main/native/cmake-build-release/libffi-benchmark.so"
)

benchmark_options=(
  -tu ms -f 1 -gc true
)

if [ "$SHORT_BENCHMARK" == "true" ]; then
  benchmark_options+=(-wi 5 -w 5 -i 3 -r 3 )
else
  benchmark_options+=(-wi 7 -w 5 -i 5 -r 5)
fi

if [ "$JIT_COMPILER" == "C1" ]; then
  java_options+=(-XX:TieredStopAtLevel=1)
elif [ "$JIT_COMPILER" == "NONE" ]; then
  java_options+=(-Xint)
fi

$JAVA_HOME/bin/java \
  "${java_options[@]}" \
  -jar "$BENCHMARK_DIR/target/benchmarks.jar" \
  "${benchmark_options[@]}" "$@" \
  2>&1 | tee "$BENCHMARK_DIR/logs/benchmark-$(date '+%F_%H%M%S').log"
