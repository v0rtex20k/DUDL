import signal
from logging import ERROR
from typing import Any, Callable, NoReturn, Union

from flask import Request, abort, current_app, logging
from flask_api import status


def shut_down_immediately():
    for sig_name in ['int', 'term', 'quit', 'hup', 'abrt', 'fpe', 'ill', 'segv']:
        try:
                if sig := getattr(signal, f"SIG{sig_name.upper()}"):
                    signal.raise_signal(sig)
        except Exception:
            continue

def register_signals(signal_handler_func: Callable):
    """ On Windows, signal() can only be called with SIGABRT, SIGFPE, SIGILL, SIGINT, SIGSEGV, SIGTERM"""
    for sig_name in ['int', 'term', 'quit', 'hup', 'abrt', 'fpe', 'ill', 'segv']:
        try:
            if sig := getattr(signal, f"SIG{sig_name.upper()}"):
                signal.signal(sig, signal_handler_func)
        except Exception:
            continue


def log_and_abort(status_code: int, desc: str, log_lvl: int = ERROR):
    current_app.logger.log(level=log_lvl, msg=desc)
    abort(status_code, description=desc)

def abort_if_missing(request: Request, attr: str, status_code: int = status.HTTP_400_BAD_REQUEST) -> Union[NoReturn, Any]:
    if not request or (val := request.get_json().get(attr)) is None:
        log_and_abort(status_code, f"Missing {attr} in Request!")
    
    return val