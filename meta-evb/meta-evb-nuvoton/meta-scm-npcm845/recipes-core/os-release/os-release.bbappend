SCM_VERSION := "2.8.0-aurea"

def get_scm_ver(d):
    obmc_ver = d.getVar('PHOSPHOR_OS_RELEASE_DISTRO_VERSION', True)
    scm_ver = d.getVar('SCM_VERSION', True)
    index = obmc_ver.find("-")
    if (index > 0 ):
        return scm_ver + obmc_ver[index:]
    else:
        return scm_ver

DISTRO_VERSION:scm-npcm845 ?= "${@get_scm_ver(d)}"
