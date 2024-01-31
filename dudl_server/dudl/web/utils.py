import signal
from logging import ERROR
from typing import Callable

from flask import abort, current_app, logging


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