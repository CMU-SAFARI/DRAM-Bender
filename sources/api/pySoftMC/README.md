# pySoftMC

Python bindings for the DRAM Bender API via pybind11.

## Building with `make`

Requires the pybind11 submodule (`git clone --recursive` or `git submodule update --init --recursive`) and a system Python installation with headers at `/usr/include/python3.X`.

```
make
```

## Building with `setup.py`

A more portable alternative that works with virtual environments and pyenv:

```
python3 setup.py build_ext --inplace
```

This uses the active Python interpreter's own build machinery, so it works regardless of where Python is installed.
