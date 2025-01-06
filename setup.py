from setuptools import find_packages, setup

setup(
    name='dudl',
    version='0.6.0',    
    description='The DUDL Game',
    url='https://github.com/v0rtex20k/DUDL/',
    packages=find_packages(),
    include_package_data=True,
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",  # Use 'text/markdown' for Markdown or 'text/x-rst' for reStructuredText
    install_requires=[
        "psutil==6.1.1",
        "Flask==2.3.3",
        "Flask-API>=3.1",
        "flask-smorest>=0.42.3",
        "randomname>=0.2.1",
        "Werkzeug==2.3.8", # when > 2.3.8, conflicting import w/ flask
        "flasgger>=0.9.7.1",
        "pathlib>=1.0.1",
        "waitress>=2.1.2",
        "inflection>=0.5.1",
        "itsdangerous>=2.1.2",
        "requests>=2.31.0",
        "ConfigArgParse>=1.7",
        "setuptools>=75.0.0"
    ],
    entry_points={
        "console_scripts": [
            "start-dudl=dudl.dudl_app:start_server",  # Adjust to match your structure
        ],
    },
    python_requires=">=3.12",
)

