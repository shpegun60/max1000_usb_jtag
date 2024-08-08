/*
timebase.c - system tick and delay

MIT License

Copyright (c) 2016 Yongqian Tang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include "base.h"
#include "timebase.h"

// cycles per microsecond
static uint32_t s_us_ticks = 0;

// cycles per millisecond
static uint32_t s_ms_ticks = 0;

// 1kHz systick timer. will rollover after 49 days
static volatile uint32_t s_system_up_ms = 0;

/*-----------------------------------*/

// SysTick�ж�
void SysTick_Handler(void)
{
    s_system_up_ms++;
}

/*-----------------------------------*/

// ��ʼ��
void timebase_init(void)
{
    // 1usʱ����
    s_us_ticks = SystemCoreClock / 1000000;
    // 1msʱ����
    s_ms_ticks = SystemCoreClock / 1000;
    // 1msʱ���ж�
    SysTick_Config(s_ms_ticks);
    // ����ж����ȼ��������������ж��е���ʱ��ʱ����
    NVIC_SetPriority(SysTick_IRQn, 0);
}

/*-----------------------------------*/

// return SysTick count
uint32_t ticks(void)
{
    return SysTick->VAL;
}

// ����ϵͳ����us�� (70�������)
uint32_t micros(void)
{
    register uint32_t ms, cycle_cnt;

    do {
        ms = s_system_up_ms;
        cycle_cnt = SysTick->VAL;
    } while (ms != s_system_up_ms);

    return (ms * 1000) + (s_ms_ticks - cycle_cnt) / s_us_ticks;
}

// ����ϵͳ���������� (49�����)
uint32_t millis(void)
{
    return s_system_up_ms;
}

/*-----------------------------------*/

// us����ʱ
void delay_us(uint32_t us)
{
    uint32_t now = micros();

    while (micros() - now < us);
}

// ms����ʱ
void delay_ms(uint32_t ms)
{
    while (ms--) {
        delay_us(1000);
    }
}
