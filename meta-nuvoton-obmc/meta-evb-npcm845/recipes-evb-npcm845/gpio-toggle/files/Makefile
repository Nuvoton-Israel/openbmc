CC ?= $(CROSS_COMPILE)gcc
CFLAGS ?= -Wall -O2
LDFLAGS ?= -lgpiod

TARGETS = pwm_tach_sim pwm_capture
SRCS = pwm_tach_sim.c pwm_capture.c

all: $(TARGETS)

pwm_tach_sim: pwm_tach_sim.c
	$(CC) $(CFLAGS) -o pwm_tach_sim pwm_tach_sim.c $(LDFLAGS)

pwm_capture: pwm_capture.c
	$(CC) $(CFLAGS) -o pwm_capture pwm_capture.c $(LDFLAGS)

clean:
	rm -f $(TARGETS)

install: $(TARGETS)
	install -d $(DESTDIR)$(sbindir)
	install -m 0755 pwm_tach_sim $(DESTDIR)$(sbindir)/
	install -m 0755 pwm_capture $(DESTDIR)$(sbindir)/

.PHONY: all clean install
