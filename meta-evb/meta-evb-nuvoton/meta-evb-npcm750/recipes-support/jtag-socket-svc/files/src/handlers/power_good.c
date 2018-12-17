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

#include "power_good.h"
#include "gpio.h"

STATUS power_good_initialize(const int gpio_fd)
{
	if (gpio_fd < 0)
		return ST_ERR;
#if CPU_PWRGD_GPIO_IS_PRESENT
	if (CPU_PWRGD_GPIO_IS_PRESENT) {
		if (set_gpio_dir_input(gpio_fd, CPU_PWRGD_GPIO) != ST_OK)
			return ST_ERR;
		if (set_gpio_event_mode(gpio_fd, CPU_PWRGD_GPIO, ASD_GPIO_TRIGGER_MODE_EDGE_BOTH) != ST_OK)
			return ST_ERR;
		if (set_gpio_event_enable(gpio_fd, CPU_PWRGD_GPIO, 1) != ST_OK)
			return ST_ERR;
	}
#endif
	return ST_OK;
}

STATUS power_good_deinitialize(const int gpio_fd)
{
	if (gpio_fd < 0)
		return ST_ERR;
#if CPU_PWRGD_GPIO_IS_PRESENT
	if (CPU_PWRGD_GPIO_IS_PRESENT) {
		// disable the event
		if (set_gpio_event_enable(gpio_fd, CPU_PWRGD_GPIO, 0) != ST_OK)
			return ST_ERR;
		if (set_gpio_dir_input(gpio_fd, CPU_PWRGD_GPIO) != ST_OK)
			return ST_ERR;
	}
#endif
	return ST_OK;
}

STATUS power_good_is_event_triggered(const int gpio_fd, bool* triggered)
{
	if (gpio_fd < 0)
		return ST_ERR;
	*triggered = false;
#if CPU_PWRGD_GPIO_IS_PRESENT
	if (CPU_PWRGD_GPIO_IS_PRESENT) {
		if (get_gpio_event_status(gpio_fd, CPU_PWRGD_GPIO, triggered) != ST_OK)
			return ST_ERR;
		if (*triggered)
			return clr_gpio_event_status(gpio_fd, CPU_PWRGD_GPIO);
	}
#endif
	return ST_OK;
}

STATUS power_good_is_asserted(const int gpio_fd, bool* asserted)
{
	if (gpio_fd < 0)
		return ST_ERR;
	STATUS status = ST_OK;
	*asserted = false;
#if CPU_PWRGD_GPIO_IS_PRESENT
	if (CPU_PWRGD_GPIO_IS_PRESENT) {
		GPIOstate pinState = GPIO_LOW;
		status = get_gpio_data(gpio_fd, CPU_PWRGD_GPIO, &pinState);
		if (status == ST_OK)
			*asserted = pinState == CPU_PWRGD_GPIO_ASSERT_HIGH ? GPIO_HIGH : GPIO_LOW;
	}
#endif
	return status;
}
