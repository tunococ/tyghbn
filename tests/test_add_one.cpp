#include <string>

#include <doctest/doctest.h>

#if TYGHBN_USE_MODULES
import tyghbn.add_one;
#else
#include <tyghbn/add_one.hpp>
#endif

using namespace tyghbn;

TEST_SUITE("add_one") {

    TEST_CASE("char") {
        CHECK(add_one('a') == 'b');
    }

    TEST_CASE("string") {
        CHECK(add_one(std::string("a")) == std::string("a1"));
    }
}
