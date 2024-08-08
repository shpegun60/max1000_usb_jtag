/*
ringbuf.c - common ring buffer

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
#include <string.h>
#include "ringbuf.h"

// �ж�x�Ƿ���2�Ĵη�
#define is_power_of_2(x) ((x) != 0 && (((x) & ((x) - 1)) == 0))

// ��ʼ��������
u32 ringbuf_init(ringbuf_t *ring_buf, void *buffer, u32 size)
{
    if (!is_power_of_2(size)) {
        return FALSE;
    }
    
    memset(ring_buf, 0, sizeof(ringbuf_t));
    ring_buf->buffer = buffer;
    ring_buf->size = size;
    ring_buf->in = 0;
    ring_buf->out = 0;
    
    return TRUE;
}

// ���������ݵĳ���
u32 ringbuf_use_len(const ringbuf_t *ring_buf)
{
    return (ring_buf->in - ring_buf->out);
}

// �жϻ������Ƿ���
u32 ringbuf_is_full(const ringbuf_t *ring_buf)
{
    return (ring_buf->in - ring_buf->out == ring_buf->size);
}

// �ӻ�������ȡ����
u32 ringbuf_get(ringbuf_t *ring_buf, void *buffer, u32 size)
{
    u32 len = 0;
    
    size = MIN(size, ring_buf->in - ring_buf->out);
    /* first get the data from fifo->out until the end of the buffer */
    len = MIN(size, ring_buf->size - (ring_buf->out & (ring_buf->size - 1)));
    memcpy((u8*)buffer, (u8*)ring_buf->buffer + (ring_buf->out & (ring_buf->size - 1)), len);
    /* then get the rest (if any) from the beginning of the buffer */
    memcpy((u8*)buffer + len, (u8*)ring_buf->buffer, size - len);
    ring_buf->out += size;
    
    // buffer��û������
    if (ring_buf->in == ring_buf->out) {
        ring_buf->in = ring_buf->out = 0;
    }
    
    return size;
}

// �򻺳����д�����
u32 ringbuf_put(ringbuf_t *ring_buf, const void *buffer, u32 size)
{
    u32 len = 0;
    
    size = MIN(size, ring_buf->size - ring_buf->in + ring_buf->out);
    /* first put the data starting from fifo->in to buffer end */
    len  = MIN(size, ring_buf->size - (ring_buf->in & (ring_buf->size - 1)));
    memcpy((u8*)ring_buf->buffer + (ring_buf->in & (ring_buf->size - 1)), (u8*)buffer, len);
    /* then put the rest (if any) at the beginning of the buffer */
    memcpy((u8*)ring_buf->buffer, (u8*)buffer + len, size - len);
    ring_buf->in += size;
    
    return size;
}

// �򻺳����д��ֽ�����
u32 ringbuf_putc(ringbuf_t *ring_buf, const u8 c)
{
    if (ringbuf_is_full(ring_buf)) {
        return 0;
    }

    *((u8*)ring_buf->buffer + (ring_buf->in & (ring_buf->size - 1))) = c;
    ring_buf->in++;
    
    return 1;
}
