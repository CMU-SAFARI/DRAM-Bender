# Prebuilt Bitstreams

This directory is reserved for an optional git submodule containing prebuilt
DRAM-Bender bitstreams and probes files.

The main repository does not track `.bit` or `.ltx` artifacts. Once the
bitstream repository exists, replace this placeholder with a submodule at this
same path:

```sh
git submodule add <bitstream-repo-url> hw/prebuilt
```
