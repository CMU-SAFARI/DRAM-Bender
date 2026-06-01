# pySoftMC

Python bindings for the DRAM Bender API via pybind11.

## Building with `make`

Requires the pybind11 submodule (`git clone --recursive` or `git submodule update --init --recursive`) and a system Python installation with headers at `/usr/include/python3.X`.

```
make
```

## Building with `setup.py`

A more portable alternative that works with virtual environments and pyenv.
Requires pybind11 installed in the active Python environment (`pip install pybind11`);
does not require the pybind11 git submodule.

```
pip install pybind11
python3 setup.py build_ext --inplace
```

This uses the active Python interpreter's own build machinery, so it works regardless of where Python is installed.
