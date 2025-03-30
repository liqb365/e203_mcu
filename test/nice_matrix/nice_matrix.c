#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include "hbird_sdk_soc.h"

#include "insn.h"

/**
 * main
 */
int main(void)
{
#define WIDTH		8
#define HEIGHT		8
#define ARRAY_SIZE	(WIDTH * HEIGHT)
#define LAST_INDEX	(ARRAY_SIZE - 1)

	unsigned int begin_instret, end_instret, instret_normal, instret_nice;
	unsigned int begin_cycle,   end_cycle,   cycle_normal,   cycle_nice;
	volatile unsigned int input_array1[WIDTH][HEIGHT];
	volatile unsigned int input_array2[WIDTH][HEIGHT];
	volatile unsigned int output_array[WIDTH][HEIGHT];
	int i, j, k = 0;

	for (i=0; i<WIDTH; i++) {
		for (j=0; j<WIDTH; j++) {
			input_array1[i][j] = k;
			input_array2[i][j] = 256 + k;
			k++;
		}
	}

	memset((void *)output_array, 0, ARRAY_SIZE * sizeof(unsigned int));

	begin_instret =  __get_rv_instret();
	begin_cycle   =  __get_rv_cycle();

	custom_lmatrix1((int)input_array1, LAST_INDEX);
	custom_lmatrix2((int)input_array2, LAST_INDEX);

	custom_sresultmatrix((int)output_array, LAST_INDEX);

	end_instret = __get_rv_instret();
	end_cycle   = __get_rv_cycle();

	instret_nice = end_instret - begin_instret;
	cycle_nice = end_cycle - begin_cycle;

	printf("With nice, instrent: %u cycle: %u\n", instret_nice, cycle_nice);

	memset((void *)output_array, 0, ARRAY_SIZE * sizeof(unsigned int));

	begin_instret =  __get_rv_instret();
	begin_cycle   =  __get_rv_cycle();

	for (i=0; i<WIDTH; i++) {
		for (j=0; j<WIDTH; j++) {
			output_array[i][j] = input_array1[i][j] + input_array2[i][j];
		}
	}

	end_instret = __get_rv_instret();
	end_cycle   = __get_rv_cycle();

	instret_normal = end_instret - begin_instret;
	cycle_normal = end_cycle - begin_cycle;

	printf("With normal, instrent: %u cycle: %u\n", instret_normal, cycle_normal);

	return 0;
}
