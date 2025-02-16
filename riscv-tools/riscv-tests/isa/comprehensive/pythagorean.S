# See LICENSE for license details.

#*****************************************************************************
# pythagorean.S
#-----------------------------------------------------------------------------
#
# Pythagorean theorem.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32M

RVTEST_CODE_BEGIN

	li TESTNUM, 2

	# s3 = 3^2 = 9
	li s3, 3
	mul s3, s3, s3

	# s4 = 4^2 = 16
	li s4, 4
	mul s4, s4, s4

	# a0 = 9 + 16 = 25
	add a0, s3, s4

	# Answer.
	li s2, 5

	# Calculate the square root of a0.
	li t0, 1
	mv t1, a0
	li t2, 10

sqrt_loop:

	div t3, t1, t0
	add t3, t3, t0
	srli t3, t3, 1
	mv t0, t3
	addi t2, t2, -1
	bnez t2, sqrt_loop

	mv a0, t0

	# Pass or fail ?
	bne s2, a0, fail

  	TEST_PASSFAIL

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
