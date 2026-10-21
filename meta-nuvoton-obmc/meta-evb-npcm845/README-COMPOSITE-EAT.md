# Composite EAT Attestation

This document describes BMC-mediated Composite EAT attestation on the Nuvoton
NPCM845 EVB (`meta-evb-npcm845`). For general board setup, build and flash
instructions, see the [NPCM845 EVB README](README.md).

## Table of Contents

- [Build Composite EAT Image](#build-composite-eat-image)
- [What the Distro Enables](#what-the-distro-enables)
- [Collection Plan](#collection-plan)
- [Generate a Composite EAT Bundle](#generate-a-composite-eat-bundle)

The BMC can collect SPDM evidence from the devices behind it and return it as
one signed Composite EAT (Entity Attestation Token) Bundle through Redfish.
The feature is controlled by the `composite-eat` DISTRO_FEATURE, which is off
by default. Only the `arbel-evb-composite-eat` distro turns it on.

## Build Composite EAT Image

```bash
$ . setup evb-npcm845-stage
$ DISTRO=arbel-evb-composite-eat bitbake obmc-phosphor-image
```

Or set it in `conf/local.conf`:

```
DISTRO = "arbel-evb-composite-eat"
```

The distro is defined in `conf/distro/arbel-evb-composite-eat.conf`. It is
based on `openbmc-phosphor` and requires
`conf/distro/include/composite-eat.inc` from `meta-common`.

## What the Distro Enables

`composite-eat.inc` adds `composite-eat` to `DISTRO_FEATURES`, adds the
`df-composite-eat` override, and requires `spdm.inc`. Recipes use the
override to add the following only for this distro:

| Component | Change |
|---|---|
| U-Boot | Kernel entry/load address `UBOOT_ENTRYPOINT`/`UBOOT_LOADADDRESS` moves from `0x6200000` to `0x6300000` |
| Kernel | Composite EAT mailbox client, UAPI, DT bindings, KUnit tests and `CONFIG_NPCM_COMPOSITE_EAT=y` (`composite-eat.cfg`) |
| TIP firmware | Prebuilt TIP FW (L0 0.8.9, L1 0.7.8) with the Composite EAT service (`npcm8xx-tip-fw-composite-eat.inc`) |
| spdmd | NVIDIA SPDM stack with the composite core and the `bmc-direct-composite-eat` Lead Attester backend (`spdm-composite-eat.inc`) |
| bmcweb | `ComponentIntegrity` resources and the `OpenBMCCompositeEATBundle` OEM API (`-Dredfish-component-integrity`, `-Dredfish-composite-eat`) |
| phosphor-dbus-interfaces | `SPDM.Responder` and `Inventory.Item.SPDMResponder` interfaces |
| mctpd | Publish `Common.UUID` when it is learned after the endpoint is published |
| Image | Adds `curl` |

Other distros (`arbel-evb-entity`, `arbel-evb-emmc`, ...) do not get any of
these changes and keep the default `0x6200000` load address.

Composite EAT evidence is collected over SPDM, which runs over MCTP. The
machine configuration already includes `conf/distro/include/mctp.inc`.

## Collection Plan

spdmd reads `/etc/spdmd/composite.json` to map discovered SPDM endpoints
(MCTP EIDs) to stable topology identifiers in the Composite EAT. The EVB
default is:

```json
{
    "environments": [
        { "env": "env.smc.0",  "match": { "mctpEid": 36 } },
        { "env": "env.smc.1",  "match": { "mctpEid": 9 } }
    ]
}
```

Edit `recipes-phosphor/spdm/files/composite.json` when the endpoint EIDs on
your board are different.

## Generate a Composite EAT Bundle

1. Check that the measured devices are listed:

   ```bash
   $ curl -k -u root:0penBmc https://${BMC_IP}/redfish/v1/ComponentIntegrity
   ```

2. Start generation with a standard base64 encoded 32-byte nonce (44
   characters, ending in one `=`):

   ```bash
   $ NONCE=$(head -c 32 /dev/urandom | base64)
   $ curl -k -u root:0penBmc -X POST \
       -H "Content-Type: application/json" \
       -d "{\"Nonce\": \"${NONCE}\"}" \
       https://${BMC_IP}/redfish/v1/ComponentIntegrity/Actions/Oem/OpenBMCCompositeEATBundle.Generate
   ```

   The BMC returns `202 Accepted` with
   `Location: /redfish/v1/ComponentIntegrity/CompositeEATBundle`. If a
   generation is already running, it returns `503 Service Unavailable` with
   `Retry-After`.

3. Poll the result until `Status` is `Ready`:

   ```bash
   $ curl -k -u root:0penBmc https://${BMC_IP}/redfish/v1/ComponentIntegrity/CompositeEATBundle
   ```

   ```json
   {
     "@odata.id": "/redfish/v1/ComponentIntegrity/CompositeEATBundle",
     "@odata.type": "#OpenBMCCompositeEATBundle.v1_0_0.CompositeEATBundle",
     "Id": "CompositeEATBundle",
     "Name": "Platform Composite EAT Bundle",
     "Status": "Ready",
     "CompositeEATBundle": "2QJY..."
   }
   ```

   `Status` is one of `Idle`, `InProgress`, `Ready` or `Error`.
   `CompositeEATBundle` is the base64 encoded CBOR bundle and is only present
   when `Status` is `Ready`. A producer error is returned as a Redfish
   internal error.
