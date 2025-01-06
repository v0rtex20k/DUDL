import pathlib
import socket
import psutil
import configargparse
from typing import Any, Dict
from logging import DEBUG, INFO
from flask import Config as Environment


def environment_specifier(k: str)-> str:
    if not k:
        k = "PROD"
    
    env = {"DEV": "Development", "PROD": "Production", "TEST": "Testing"}.get(k.strip().upper(), "Production")

    path = f"{pathlib.Path(__file__).with_suffix('').name}.{env}Environment"
    for part in pathlib.Path(__file__).parents:
        if part.name == "dudl":
            break
        path = part.name + '.' + path

    return path


def load_runtime_environment() -> Dict[str, Any]:
    parser = configargparse.ArgParser()
    
    parser.add_argument('--dudlPort', type=int, help="dudl server port", env_var="DUDL_PORT")
    parser.add_argument('--threadCount', type=int, help="number of threads to use", env_var="DUDL_THREAD_COUNT")
    parser.add_argument('--mongoUrl', type=int, help="number of threads to use", env_var="DUDL_THREAD_COUNT")

    parser.add_argument('--mongoTimeout', type=str, required=False, help='mongo retry timeout', env_var="DUDL_MONGO_TIMEOUT")
    parser.add_argument('--appTimeout', type=str, required=False, help='dudl iOS app timeout', env_var="DUDL_APP_TIMEOUT")

    parser.add_argument('--logLevel', type=str, required=False, help='logging level', env_var="DUDL_LOG_LEVEL")
    parser.add_argument('--env', type=str, required=False, help='DUDL env Specifier: [DEV, PROD, TEST]', env_var="DUDL_ENV")

    config_args, remaining_args = parser.parse_known_args()

    if len(remaining_args) > 0:
        print(f"Unknown args: {remaining_args}")

    return vars(config_args)


def get_ip_address()-> str:
    try: 
        addrs = psutil.net_if_addrs()
        for addr in addrs['en0']:
            if addr.family == socket.AF_INET:
                return addr.address
    except:
        return "127.0.0.1"

class BaseEnvironment(Environment):
    """ DEFAULT VALUES FOR DUDL """
    DUDL_HOST = "127.0.0.1"
    DUDL_PORT = 8001
    THREAD_COUNT = 8

    MONGO_URL = "http://mongo" # FIXME: change this

    MONGO_TIMEOUT = 1
    APP_TIMEOUT = 1

    # OPENAPI
    OPENAPI_URL_PREFIX = "/api"
    OPENAPI_REDOC_PATH = "/redoc"
    OPENAPI_SWAGGER_UI_PATH = "/swagger"
    OPENAPI_SWAGGER_UI_URL = "https://cdnjs.cloudfare.com/ajax/libs/swagger-ui/3.24.2/"
    API_SPEC_OPTIONS = {'x-internal-id': "2"}
    API_TITLE = "DUDL Server"
    API_VERSION = "1.0"
    OPENAPI_VERSION = "3.0.2"

class DevelopmentEnvironment(BaseEnvironment):
    LOG_LEVEL = DEBUG

class ProductionEnvironment(BaseEnvironment):
    DUDL_HOST = get_ip_address()
    LOG_LEVEL = INFO

class TestingEnvironment(BaseEnvironment):
    LOG_LEVEL = 5  # TRACE

