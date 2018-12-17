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

#include "power_debug.h"
#include "gpio.h"

STATUS power_debug_initialize(const int gpio_fd)
{
	if (gpio_fd < 0)
		return ST_ERR;
#if CPU_PWR_DEBUG_GPIO_IS_PRESENT
	if (CPU_PWR_DEBUG_GPIO_IS_PRESENT) {
		if (set_gpio_dir_output(gpio_fd, CPU_PWR_DEBUG_GPIO) != ST_OK)
			return ST_ERR;
	}
#endif
	return ST_OK;
}

STATUS power_debug_deinitialize(const int gpio_fd)
{
	if (gpio_fd < 0)
		return ST_ERR;
#if CPU_PWR_DEBUG_GPIO_IS_PRESENT
	if (CPU_PWR_DEBUG_GPIO_IS_PRESENT) {
		if (set_gpio_dir_input(gpio_fd, CPU_PWR_DEBUG_GPIO) != ST_OK)
			return ST_ERR;
	}
#endif
	return ST_OK;
}

STATUS power_debug_assert(const int gpio_fd, const bool assert)
{
	if (gpio_fd < 0)
		return ST_ERR;
#if CPU_PWR_DEBUG_GPIO_IS_PRESENT
	if (CPU_PWR_DEBUG_GPIO_IS_PRESENT) {
		if (set_gpio_data(gpio_fd, CPU_PWR_DEBUG_GPIO,
					assert == CPU_PWR_DEBUG_GPIO_ASSERT_HIGH ? GPIO_HIGH : GPIO_LOW) != ST_OK)
			return ST_ERR;
	}
#endif
	return ST_OK;
}

STATUS power_debug_is_asserted(const int gpio_fd, bool* asserted)
{
	if (gpio_fd < 0)
		return ST_ERR;
	*asserted = false;
	STATUS status = ST_OK;
#if CPU_PWR_DEBUG_GPIO_IS_PRESENT
	GPIOstate pinState = GPIO_LOW;
	if (CPU_PWR_DEBUG_GPIO_IS_PRESENT) {
		status = get_gpio_data(gpio_fd, CPU_PWR_DEBUG_GPIO, &pinState);
		if (status == ST_OK)
			*asserted = pinState == CPU_PWR_DEBUG_GPIO_ASSERT_HIGH ? GPIO_HIGH : GPIO_LOW;
	}
#endif
	return status;
}
