import os
from os import path
from codecs import open
from setuptools import setup, find_namespace_packages

# get current directory
here = path.abspath(path.dirname(__file__))

# get the long description from the README file
# with open(path.join(here, 'README.md'), encoding='utf-8') as f:
#     long_description = f.read()

# Read the API version from disk. This file should be located in the package
# folder, since it's also used to set the pkg.__version__ variable.
version_path = os.path.join(here, 'cli', '_version.py')
version_ns = {
    '__file__': version_path
}
with open(version_path) as f:
    exec(f.read(), {}, version_ns)


# setup the package
setup(
    name='feder8',
    version='2.0.19',
    description='Feder8 command line interface',
    url='https://github.com/Solventrix/Honeur-Setup',
    packages=find_namespace_packages(),
    python_requires='>=3.6',
    install_requires=[
        'click==8.0.1',
        'docker==5.0.0',
        'questionary==1.10.0',
        'config-client==0.12.0',
        'six==1.16.0',
        'StringGenerator==0.4.4',
        'psycopg2-binary==2.9.2'
    ],
    extras_require={
        'dev': [
            'coverage==5.5'
        ]
    },
    package_data={
        'cli': [
            '__build__'
        ],
    },
    entry_points={
        'console_scripts': [
            'feder8=cli.feder8:cli_feder8'
        ]
    }
)