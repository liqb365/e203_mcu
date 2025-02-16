# See LICENSE for license details.

#*****************************************************************************
# swapnumber.S
#-----------------------------------------------------------------------------
#
# Swap number between two numbers.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32M

RVTEST_CODE_BEGIN

	li TESTNUM, 2

	# s2 = 123
	li s2, 123

	# s3 = 456
	li s3, 456

	# s4 = 456
	li s4, 456

	# s2 = s2 ^ s3
	xor s2, s2, s3

	# s3 = s2 ^ s3
	xor s3, s2, s3

	# s2 = s2 ^ s3
	xor s2, s2, s3

	# Pass or fail ?
	bne s2, s4, fail

  	TEST_PASSFAIL

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
