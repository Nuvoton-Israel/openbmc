/*
   Copyright (c) 2017, Intel Corporation

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of Intel Corporation nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 */

#include "tck_mux_select.h"
#include "gpio.h"

STATUS tck_mux_select_initialize(const int gpio_fd)
{
	if (gpio_fd < 0)
		return ST_ERR;
#if TCK_MUX_SEL_GPIO_IS_PRESENT
	if (TCK_MUX_SEL_GPIO_IS_PRESENT) {
		return set_gpio_dir_output(gpio_fd, TCK_MUX_SEL_GPIO);
	}
#endif
	return ST_OK;
}

STATUS tck_mux_select_deinitialize(const int gpio_fd)
{
	if (gpio_fd < 0)
		return ST_ERR;
#if TCK_MUX_SEL_GPIO_IS_PRESENT
	if (TCK_MUX_SEL_GPIO_IS_PRESENT) {
		return set_gpio_dir_input(gpio_fd, TCK_MUX_SEL_GPIO);
	}
#endif
	return ST_OK;
}
