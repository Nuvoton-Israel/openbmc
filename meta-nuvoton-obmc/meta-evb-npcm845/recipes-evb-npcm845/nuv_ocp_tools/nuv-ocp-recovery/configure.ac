# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.60)

AC_INIT([nuv_ocp_recovery], [0.1])
AC_LANG([C++])
AC_CONFIG_HEADER([config.h])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])

# Checks for programs.
AC_PROG_CXX
AM_PROG_AR
AC_PROG_INSTALL
AC_PROG_MAKE_SET

PKG_CHECK_MODULES(
    [SDBUSPLUS],
    [sdbusplus],
    [],
    [AC_MSG_ERROR(["sdbusplus required and not found"])]
)

AC_CHECK_HEADER(
    nlohmann/json.hpp,
    [],
    [AC_MSG_ERROR([Could not find nlohmann/json.hpp])]
)

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

#AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_FILES([
 Makefile
 src/Makefile
])
AC_OUTPUT
