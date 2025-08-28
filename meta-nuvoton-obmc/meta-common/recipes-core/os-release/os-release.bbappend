PHOSPHOR_OS_RELEASE_DISTRO_VERSION := "${@run_git(d, 'describe  --tags --dirty')}"
