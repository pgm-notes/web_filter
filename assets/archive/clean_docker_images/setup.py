#!/bin/python3

from setuptools import setup

setup(
    name="remove-chattr-tool",
    version="1.0",
    py_modules=["remove_chattr"],
    install_requires=["docker"],
    entry_points={
        "console_scripts": [
            "remove-chattr=remove_chattr:main",
        ],
    },
)

