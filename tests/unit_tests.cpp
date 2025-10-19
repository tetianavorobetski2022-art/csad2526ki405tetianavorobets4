
#include <gtest/gtest.h>
#include "../math_operations.h"


TEST(AdditionTest, Simple) {
    EXPECT_EQ(add(2, 3), 5);
}

TEST(AdditionTest, Zero) {
    EXPECT_EQ(add(0, 0), 0);
}

TEST(AdditionTest, NegativeNumbers) {
    EXPECT_EQ(add(-4, -6), -10);
}

TEST(AdditionTest, MixedSign) {
    EXPECT_EQ(add(7, -2), 5);
}

TEST(AdditionTest, LargeValues) {
    EXPECT_EQ(add(100000, 200000), 300000);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}