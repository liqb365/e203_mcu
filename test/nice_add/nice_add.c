#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "hbird_sdk_soc.h"

#include "insn.h"

/**
 * main
 */
int main(void)
{
	int sum;
	int op1 = -777;
	int op2 = 2000;

	sum = custom_add(op1, op2);

	printf("Sum: %d\n", sum);

	return 0;
}
