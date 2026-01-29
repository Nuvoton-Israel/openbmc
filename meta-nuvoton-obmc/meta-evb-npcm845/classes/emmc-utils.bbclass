# Helper utilities for eMMC-enabled distros
#
# This class provides utility functions to conditionally include
# configuration based on whether the distro supports eMMC storage.

# List of distros that have eMMC support enabled
EMMC_ENABLED_DISTROS = "arbel-evb-emmc arbel-evb-emmc-entity"

def emmc_enabled(d, truevalue, falsevalue=""):
    """
    Check if the current DISTRO has eMMC support enabled.
    
    Args:
        d: BitBake data store
        truevalue: Value to return if eMMC is enabled
        falsevalue: Value to return if eMMC is not enabled (default: empty string)
    
    Returns:
        truevalue if current DISTRO is in EMMC_ENABLED_DISTROS, otherwise falsevalue
    """
    distro = d.getVar("DISTRO")
    emmc_distros = d.getVar("EMMC_ENABLED_DISTROS")
    
    if distro and emmc_distros:
        if distro in emmc_distros.split():
            return truevalue
    
    return falsevalue


