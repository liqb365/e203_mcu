#ifndef __INSN_H__
#define __INSN_H__

#include <hbird_sdk_soc.h>

/**
 * custom_lmatrix1
 */
__STATIC_FORCEINLINE void custom_lmatrix1(int addr, int size)
{
    int zero = 0;

    asm volatile (
       ".insn r 0x7b, 7, 0, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(size)
     );
}

/**
 * custom_smatrix1
 */
__STATIC_FORCEINLINE void custom_smatrix1(int addr, int size)
{
    int zero = 0;

    asm volatile (
       ".insn r 0x7b, 7, 1, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(size)
     );
}

/**
 * custom_lmatrix2
 */
__STATIC_FORCEINLINE void custom_lmatrix2(int addr, int size)
{
    int zero = 0;

    asm volatile (
       ".insn r 0x7b, 7, 2, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(size)
     );
}

/**
 * custom_smatrix2
 */
__STATIC_FORCEINLINE void custom_smatrix2(int addr, int size)
{
    int zero = 0;

    asm volatile (
       ".insn r 0x7b, 7, 3, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(size)
     );
}

/**
 * custom_lresultmatrix
 */
__STATIC_FORCEINLINE void custom_lresultmatrix(int addr, int size)
{
    int zero = 0;

    asm volatile (
       ".insn r 0x7b, 7, 4, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(size)
     );
}

/**
 * custom_sresultmatrix
 */
__STATIC_FORCEINLINE void custom_sresultmatrix(int addr, int size)
{
    int zero = 0;

    asm volatile (
       ".insn r 0x7b, 7, 5, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(size)
     );
}

/**
 * custom_mulacc
 */
__STATIC_FORCEINLINE void custom_mulacc(int addr, int size)
{
    int zero = 0;

    asm volatile (
       ".insn r 0x7b, 7, 6, %0, %1, %2"
           :"=r"(zero)
           :"r"(addr), "r"(size)
     );
}

#endif
