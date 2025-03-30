#ifndef NICE_VECTOR_H
#define NICE_VECTOR_H

#include <hbird_sdk_soc.h>

/**
 * nice_vector_load_inputvector1
 */
__STATIC_FORCEINLINE void nice_vector_load_inputvector1(int addr, int size)
{
    int zero = 0;
	int last_index = size - 1;

    asm volatile (
       ".insn r 0x7b, 7, 0, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(last_index)
     );
}

/**
 * nice_vector_store_inputvector1
 */
__STATIC_FORCEINLINE void nice_vector_store_inputvector1(int addr, int size)
{
    int zero = 0;
	int last_index = size - 1;

    asm volatile (
       ".insn r 0x7b, 7, 1, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(last_index)
     );
}

/**
 * nice_vector_load_inputvector2
 */
__STATIC_FORCEINLINE void nice_vector_load_inputvector2(int addr, int size)
{
    int zero = 0;
	int last_index = size - 1;

    asm volatile (
       ".insn r 0x7b, 7, 2, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(last_index)
     );
}

/**
 * nice_vector_store_inputvector2
 */
__STATIC_FORCEINLINE void nice_vector_store_inputvector2(int addr, int size)
{
    int zero = 0;
	int last_index = size - 1;

    asm volatile (
       ".insn r 0x7b, 7, 3, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(last_index)
     );
}

/**
 * nice_vector_load_resultvector
 */
__STATIC_FORCEINLINE void nice_vector_load_resultvector(int addr, int size)
{
    int zero = 0;
	int last_index = size - 1;

    asm volatile (
       ".insn r 0x7b, 7, 4, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(last_index)
     );
}

/**
 * nice_vector_store_resultvector
 */
__STATIC_FORCEINLINE void nice_vector_store_resultvector(int addr, int size)
{
    int zero = 0;
	int last_index = size - 1;

    asm volatile (
       ".insn r 0x7b, 7, 5, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(last_index)
     );
}

/**
 * nice_vector_mulacc
 */
__STATIC_FORCEINLINE void nice_vector_mulacc(int multiple)
{
    int zero = 0;

    asm volatile (
       ".insn r 0x7b, 7, 6, %0, %1, %2"
           :"=r"(zero)
           :"r"(0), "r"(multiple)
     );
}

#endif
