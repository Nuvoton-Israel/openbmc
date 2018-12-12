sbin_PROGRAMS = ipmbbridged

ipmbbridged_SOURCES = ipmbbridged.cpp ipmbutils.cpp
ipmbbridged_LDFLAGS = $(SYSTEMD_LIBS) \
                      $(SDBUSPLUS_LIBS)
ipmbbridged_CFLAGS = $(SYSTEMD_CFLAGS) \
                     $(SDBUSPLUS_CFLAGS)
