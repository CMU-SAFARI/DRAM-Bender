from setuptools import setup, Extension
import os, pybind11

here    = os.path.dirname(os.path.abspath(__file__))
api_dir = os.path.join(here, "..")
pybind11_include = pybind11.get_include()

ext = Extension(
    "pySoftMC",
    sources=[
        os.path.join(api_dir, "board.cpp"),
        os.path.join(api_dir, "instruction.cpp"),
        os.path.join(api_dir, "platform.cpp"),
        os.path.join(api_dir, "prog.cpp"),
        os.path.join(here, "pySoftMC.cpp"),
    ],
    include_dirs=[here, api_dir, pybind11_include],
    language="c++",
    extra_compile_args=["-std=c++14", "-pthread", "-O3", "-DPYSMC"],
)

setup(name="pySoftMC", ext_modules=[ext])
