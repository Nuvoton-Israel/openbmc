FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Host-compatibility fix for building on Ubuntu 24.04 (glibc 2.39 / GNU tar 1.35).
#
# The pinned pseudo (1.9.0+git, Oct 2024) predates pseudo's openat2() syscall
# handling. GNU tar 1.35 uses openat2() while extracting during do_package's
# copytree (tar | tar). Old pseudo does not intercept openat2(), so it loses
# track of the destination directory fd and fails with:
#   got *at() syscall for unknown directory, fd 4
#   unknown base path for fd 4, path include
#   couldn't allocate absolute path for 'include'.
#   tar: ./usr/include/drm: Cannot mkdir: No such file or directory
#
# Bump to the pseudo 1.9.8 release, which contains the full openat2 wrapper
# (added upstream in 1.9.3/1.9.5).
SRCREV = "823895ba708c63f6ae4dcbfc266210f26c02c698"
PV = "1.9.8"

# 0001-configure-Prune-PIE-flags.patch and glibc238.patch were merged upstream
# by pseudo 1.9.1 and no longer apply to 1.9.8; drop them.
SRC_URI:remove = "file://0001-configure-Prune-PIE-flags.patch file://glibc238.patch"
