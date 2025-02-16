# See LICENSE for license details.

#*****************************************************************************
# demo.S
#-----------------------------------------------------------------------------
#
# Demo code. We can develope any new program from here.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32M

RVTEST_CODE_BEGIN

	li TESTNUM, 2

	li x1, 1
	li x2, 1
	bne x1, x2, fail

  	TEST_PASSFAIL

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
