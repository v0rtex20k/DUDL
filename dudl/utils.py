import signal
from logging import ERROR
from typing import Any, Callable, NoReturn, Union

from flask_api import status
from flask import Request, abort, current_app


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

def abort_if_missing(request: Request, *attrs: str) -> Union[NoReturn, Any]:
    try:
        vals = []
        if not request:
            raise ValueError
        
        json = request.get_json()

        for attr in attrs:
            if (val := json[attr]) is None:
                raise AttributeError
            else:
                vals.append(val)
                
        return vals if len(vals) > 1 else vals[0]
    except Exception:
        log_and_abort(status.HTTP_400_BAD_REQUEST, f"Invalid Request - one or more attributes missing ({attrs})")