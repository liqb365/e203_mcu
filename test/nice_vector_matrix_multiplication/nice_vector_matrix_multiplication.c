#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include "hbird_sdk_soc.h"
#include "nice_vector.h"

volatile unsigned int zero_array[3] = {0, 0, 0};
volatile unsigned int matrix1[3][3] = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}};
volatile unsigned int matrix2[3][3] = {{9, 8, 7}, {6, 5, 4}, {3, 2, 1}};
volatile unsigned int output_array[3][3];

/**
 * calculate
 */
void calculate(int index)
{
	/* Load zeros to resultvector. */
	nice_vector_load_resultvector((int)zero_array, 3);

	/* Load input values to vector1. */
	nice_vector_load_inputvector1((int)matrix2[0], 3);

	/* Multiply and accumulate. */
	nice_vector_mulacc(matrix1[index][0]);

	/* Load input values to vector1. */
	nice_vector_load_inputvector1((int)matrix2[1], 3);

	/* Multiply and accumulate. */
	nice_vector_mulacc(matrix1[index][1]);

	/* Load input values to vector1. */
	nice_vector_load_inputvector1((int)matrix2[2], 3);

	/* Multiply and accumulate. */
	nice_vector_mulacc(matrix1[index][2]);

	/* Store resultvector values to memory. */
	nice_vector_store_resultvector((int)output_array[index], 3);
}

/**
 * main
 */
int main(void)
{
	int i, j;

	/* Calculate. */
	for (i=0; i< 3;i++)
		calculate(i);

	/* Print out the output values. */
	for (i=0; i< 3; i++) {
		for (j=0; j< 3; j++)
			printf(" %d ", output_array[i][j]);
		printf("\n");
	}
	printf("\n");

	return 0;
}
