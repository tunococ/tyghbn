#define ANKERL_NANOBENCH_IMPLEMENT
#include <nanobench.h>

#include <string>

#if TYGHBN_USE_MODULES
import tyghbn;
#else
#include <tyghbn/add_one.hpp>
#include <tyghbn/or_else.hpp>
#endif

using namespace ankerl::nanobench;

int main() {
  Bench bench;

  bench.run("add_one<int>", [] {
    auto x = 42;
    doNotOptimizeAway(x);
    doNotOptimizeAway(tyghbn::add_one(x));
  });

  bench.run("add_one<double>", [] {
    auto x = 3.14;
    doNotOptimizeAway(x);
    doNotOptimizeAway(tyghbn::add_one(x));
  });

  bench.run("or_else<int>", [] {
    auto x = 2;
    auto y = 1;
    doNotOptimizeAway(x);
    doNotOptimizeAway(y);
    doNotOptimizeAway(tyghbn::or_else(x, y));
  });

  bench.run("or_else<int> with zero", [] {
    auto x = 0;
    auto y = 1;
    doNotOptimizeAway(x);
    doNotOptimizeAway(y);
    doNotOptimizeAway(tyghbn::or_else(x, y));
  });

  return 0;
}
