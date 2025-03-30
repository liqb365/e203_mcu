#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include "hbird_sdk_soc.h"
#include "nice_vector.h"

#define ARRAY_SIZE	(16)

/**
 * vector_times_scalar
 */
void vector_times_scalar(int multiples, int times)
{
	volatile unsigned int zero_array[ARRAY_SIZE];
	volatile unsigned int input_array[ARRAY_SIZE];
	volatile unsigned int output_array[ARRAY_SIZE];
	int i;

	/* Init arrays. */
	for (i=0; i< ARRAY_SIZE; i++) {
		input_array[i] = i + 1;
		zero_array[i] = 0;
		output_array[i] = 0;
	}

	/* Load input values to vector1. */
	nice_vector_load_inputvector1((int)input_array, ARRAY_SIZE);

	/* Load zeros to resultvector. */
	nice_vector_load_resultvector((int)zero_array, ARRAY_SIZE);

	/* Multiply and accumulate. */
	for (i=0; i<times; i++)
		nice_vector_mulacc(multiples);

	/* Store resultvector values to memory. */
	nice_vector_store_resultvector((int)output_array, ARRAY_SIZE);

	/* Print out the output values. */
	for (i=0; i< ARRAY_SIZE; i++)
		printf(" %d ", output_array[i]);
	printf("\n");
}

/**
 * main
 */
int main(void)
{
	/* First time, vector times scalar, no accumulation. */
	vector_times_scalar(5, 1);
	/* Then,   */
	vector_times_scalar(5, 2);
	return 0;
}
