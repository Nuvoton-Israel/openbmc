AM_DEFAULT_SOURCE_EXT = .cpp
AM_CXXFLAGS = -std=c++20
bin_PROGRAMS = nuv_ocp_recovery
nuv_ocp_recovery_SOURCES = nuv_ocp_recovery.cpp

nuv_ocp_recovery_LDADD = \
    $(SDBUSPLUS_LIBS) \
    -lgpiod
