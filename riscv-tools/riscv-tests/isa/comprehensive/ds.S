# See LICENSE for license details.

#*****************************************************************************
# ds.S
#-----------------------------------------------------------------------------
#
# Difference of Squares.
# a^2 - b^2 = (a+b)(a-b)
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32M

RVTEST_CODE_BEGIN

	li TESTNUM, 2

	# s3 = 5x5 = 25
	li s2, 5
	mul s3, s2, s2

	# s5 = 4x4 = 16
	li s4, 4
	mul s5, s4, s4

	# s6 = 25 - 16 = 9
	sub s6, s3, s5

	# s7 = s2 + s4
	#    = 5 + 4
 	#	 = 9
	add s7, s2, s4

	# s7 = s2 - s4
	#    = 5 - 4
 	#	 = 1
	sub s8, s2, s4

	# s9 = s7 x s8
	#	 = 9 x 1
	#	 = 9
	mul s9, s7, s8

	# Pass or fail?
	bne s6, s9, fail

  	TEST_PASSFAIL

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
