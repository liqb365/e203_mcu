# See LICENSE for license details.

#*****************************************************************************
# sumas.S
#-----------------------------------------------------------------------------
#
# Sum of an arithmetic sequence (from 1 to 100).
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32M

RVTEST_CODE_BEGIN

	li TESTNUM, 2

	# Cumulative Sum.
	li s2, 0

	# Index
	li s3, 1

	# Range
	li s4, 51

	# Result
	li s5, 5050

	# Constant.
	li s6, 101

loop:

	# Prepare another addend.
	sub s7, s6, s3

	# Calculate the sum.
	add s8, s3, s7

	# Calculate the cumulative sum.
	add s2, s2, s8

	# Index increment.
	addi s3, s3, 1

	# Branch.
	bne s3, s4, loop

	# Pass or fail ?
	bne s2, s5, fail

  	TEST_PASSFAIL

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
