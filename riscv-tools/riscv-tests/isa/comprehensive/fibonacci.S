# See LICENSE for license details.

#*****************************************************************************
# fibonacci.S
#-----------------------------------------------------------------------------
#
# Fibonacci sequence.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32M

RVTEST_CODE_BEGIN

	li TESTNUM, 2

	# Index
	li t3, 0

	# Loop count.
	li t4, 11

	# First/Second number.
	li s2, 0
	li s3, 1

	# Variable i.
	li s4, 0

	# Const variable j
	li s5, 1

	# Result
	li s6, 0

	# 144 is the twelfth number in Fibonacci sequence.
	li s7, 144

loop:

	# If s4 is not 1, jump to add_to_s3.
	beq s4, s5, add_to_s3

	# Calculate next number.
	# Save to s2.
	add s2, s2, s3

	# Save s2 to s6.
	addi s6, s2, 0

	# Set s4 as 1.
	li s4, 1

	# Jump to continue.
	j continue

add_to_s3:

	# Calculate next number.
	# Save to s3.
	add s3, s2, s3

	# Save s3 to s6.
	addi s6, s3, 0

	# Set s4 as 0.
	li s4, 0

continue:

	# Increase index.
	addi t3, t3, 1

	# Loop, next round.
	bne t3, t4, loop

	# Pass or fail ?
	bne s6, s7, fail

  	TEST_PASSFAIL

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
