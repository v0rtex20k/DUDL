import logging
import signal
import sys
import time
import waitress
import inflection
import importlib
from flasgger import Swagger
from flask import Flask, current_app
from typing import Any, Callable, Dict
from flask.logging import create_logger
from flask_smorest import Blueprint, Api

from dudl.env import load_runtime_environment


def setup_logging(default_level=logging.INFO):
    logging.basicConfig(level=default_level)

    log_formatter = logging.Formatter("[%(asctime)s] %(levelname)s [%(filename)s::%(funcName)s:%(lineno)d] %(message)s",
                                      datefmt="%m/%d/%Y %I:%M:%S %p")
    

    current_app.logger = create_logger(current_app)
    current_app.logger.handlers.clear()
    current_app.logger.propagate = False
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(log_formatter)
    current_app.logger.addHandler(console_handler)

    logging.TRACE = 5
    logging.addLevelName(5, "TRACE")

    log_level = current_app.config.get("LOG_LEVEL", logging.INFO)
    if isinstance(log_level, str):
        logging._nameToLevel.get(log_level, logging.INFO)

    current_app.logger.setLevel(log_level)
    current_app.logger.debug(f"Logging Level set to {logging._levelToName.get(log_level, None)} ({log_level})")


def override_config_with_runtime_env(runtime_env: Dict[str, Any]):
    sanitize: Callable[[str], str] = lambda k : k.replace("_", "").lower()
    fuzzy_match: Callable[[str, str], str] = lambda s1, s2 : sanitize(s1) == sanitize(s2)

    matches = []
    for name in current_app.config:
        for runtime_name, runtime_val in runtime_env.items():
            if fuzzy_match(name, runtime_name):
                current_app.logger.debug(f"Overrode \"{name}\" to \"{runtime_val}\" based on runtime config ...")
                if runtime_val is not None:
                    current_app.config[name] = runtime_val
                    matches.append(runtime_name)

    for runtime_name, runtime_val in runtime_env.items():
        if runtime_val is not None and runtime_name not in matches:
            new_name = inflection.underscore(runtime_name).upper()
            current_app.logger.debug(f"Added ({new_name},{runtime_val}) from runtime config ...")
            current_app.config[new_name] = runtime_val


def auto_register_blueprints(api: Api, blueprint_dir: str = "dudl.blueprints"):
    """ Utility function to register all Flask blueprints. This allows us to
    delay blueprint imports, which in turn allows us to push the app context to
    enable proper logging statements.
    
    NOTE: This function makes three implicit assumptions:
        1. All blueprint files are located within blueprint_dir, which the user can specify
        2. Each blueprint file follows the naming convention *_blueprint.py
        3. Each blueprint file contains a Blueprint initialzied with a name identical to
        the blueprint file name. In other words, the file "my_blueprint.py" must contain "my_blueprint = Blueprint(...".    
    """

    try:
        d = importlib.resources.files(importlib.import_module(blueprint_dir))
        for file in d.iterdir():
            if not file.name.endswith('_blueprint.py'):
                continue  # breaks implicit assumption
            module = importlib.import_module(".".join((blueprint_dir, file.stem)))
            for attr_name in dir(module):
                attr = getattr(module, attr_name, None)
                if isinstance(attr, Blueprint):
                    current_app.logger.debug(f'Registering new Blueprint \"{attr_name}\" from {module.__name__}')
                    api.register_blueprint(attr)
    except Exception as e:
        current_app.logger.error(f"Failed to register one or more blueprints: {e}")
        raise e



def build_app(runtime_env: Dict[str, Any]):
    app = Flask(__name__)

    env : str = runtime_env.get("ENV", "dudl.env.ProductionEnvironment")
    try:
        app.config.from_object(env)
    except ModuleNotFoundError as e:
        raise ModuleNotFoundError(f'Cannot create app from nonexistant configuration \"{env}\"') from e

    api = Api(app)

    swagger_config = Swagger.DEFAULT_CONFIG
    swagger_config['title'] = app.config.get('API_TITLE', "DUDL Server")
    swagger_config['version'] = app.config.get("API_VERSION", "1.0")
    Swagger(app=app, config=swagger_config)
    

    with app.app_context():
        # Update configuration
        override_config_with_runtime_env(runtime_env)
        setup_logging()
        app.logger.debug(f"Config args: {app.config}")

        auto_register_blueprints(api)

    app.creation_time = time.time()

    return app

def start_server():
    runtime_env = load_runtime_environment()
    app = build_app(runtime_env)

    def handle_sig(sig, _):
        if sig == signal.SIGINT:
            app.logger.info(f"Forcibly shutting down DÜDL Server ...")
        server.close()

    app.logger.debug("Created DÜDL App ...")
    app.logger.debug("Starting DÜDL Server ...")

    server = waitress.create_server(
        application=app,
        host=app.config["DUDL_HOST"],
        port=app.config["DUDL_PORT"],
        threads=app.config["THREAD_COUNT"],
        server_name=app.config["SERVER_NAME"]
    )

    try:
        app.logger.info(f'Launching DÜDL at http://{app.config["DUDL_HOST"]}:{app.config["DUDL_PORT"]} ...')
        server.run()
    except ModuleNotFoundError as e:
        raise e
    except IOError:
        pass  # occurs when forcibly shut down
    except Exception as ex:
        app.logger.error(f"Exiting: {ex}")

if __name__ == "__main__":
    start_server()