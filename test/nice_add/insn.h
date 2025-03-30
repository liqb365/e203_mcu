#ifndef __INSN_H__
#define __INSN_H__

#include <hbird_sdk_soc.h>

/**
 * custom_lbuf
 */
__STATIC_FORCEINLINE void custom_lbuf(int addr)
{
    int zero = 0;

    asm volatile (
       ".insn r 0x7b, 2, 1, x0, %1, x0"
           :"=r"(zero)
           :"r"(addr)
     );
}

/**
 * custom_sbuf
 */
__STATIC_FORCEINLINE void custom_sbuf(int addr)
{
    int zero = 0;

    asm volatile (
       ".insn r 0x7b, 2, 2, x0, %1, x0"
           :"=r"(zero)
           :"r"(addr)
     );
}

/**
 * custom_rowsum
 */
__STATIC_FORCEINLINE int custom_rowsum(int addr)
{
    int rowsum;

    asm volatile (
       ".insn r 0x7b, 6, 6, %0, %1, x0"
             :"=r"(rowsum)
             :"r"(addr)
     );

    return rowsum;
}

/**
 * custom_add
 */
__STATIC_FORCEINLINE int custom_add(int op1, int op2)
{
    int sum;

    asm volatile (
       ".insn r 0x7b, 7, 7, %0, %1, %2"
             :"=r"(sum)
             :"r"(op1), "r"(op2)
     );

    return sum;
}

#endif
