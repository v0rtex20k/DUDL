import random
from copy import deepcopy
from flask_api import status
from flask import current_app
from typing import Any, List, Dict, Optional, Union

from dudl.web.utils import log_and_abort
from dudl.web.models.playerprofile import PlayerProfile

class Game:
    def __init__(self, code: str) -> None:
        self.code = code
        self.started = False
        self.data: Dict[str, Any] = {}
        self.player_profiles: Dict[str, PlayerProfile] = {}

        # {source_player_id_1:  [round_1_content, ...], ... }
        self.results: Dict[str, List[str]] = {}

    def start(self):
        if not self.started:
            n_players = len(self.player_profiles or [])
            if n_players > 0:
                self.started = True

                batting_order = deepcopy(list(self.player_profiles.keys()))
                random.shuffle(batting_order)

                for i, pid in enumerate(batting_order):
                    self.results[pid] = [None] * n_players
                    self.player_profiles[pid].source = batting_order[((i-1) % n_players)]

                current_app.logger.debug(f"Game {self.code} has started w/ BO {batting_order}")
            else:
                raise ValueError(f"Refusing to start Game {self.code} with only {n_players} player(s)")
        else:
            current_app.logger.debug(f"Game {self.code} was already started")

    def end(self):
        self.started = False
        current_app.logger.debug(f"Game {self.code} has been ended")

    def get_player_profile(self, player_id: str)-> Optional[PlayerProfile]:
        return self.player_profiles.get(player_id)

    def update_player_profile(self, player_id: str, nickname: str, rgba: Dict[str, Any]):
        try:
            if (profile := self.player_profiles.get(player_id, None)) is not None:
                if isinstance(profile, bool):
                    is_host = profile
                elif isinstance(profile, PlayerProfile):
                    is_host = profile.is_host
                else:
                    raise ValueError

                self.player_profiles[player_id] = PlayerProfile(
                    player_id=player_id, nickname=nickname, rgba=rgba, is_host=is_host
                )
            else:
                raise AttributeError
        except AttributeError:
            log_and_abort(status.HTTP_409_CONFLICT, f"Duplicate Player \"{player_id}\"")
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Refusing to update PlayerProfile for \"{player_id}\": {e}")

    def add_player(self, player_id: str, is_host: bool):
        self.player_profiles[player_id] = is_host

    def upload_content(self, content: str, player_id: str, round_idx: int):
        self.results[player_id][round_idx] = content

    def download_content(self, player_id: str, round_idx: int)-> str:
        return self.results[self.player_profiles[player_id].source][round_idx]
    
    def load_player_results(self, head_player_id: str)-> List[Dict[str, str | PlayerProfile]]:
        player_source_chain: List[str] = []

        curr_pid: str = head_player_id

        for _ in range(len(self.player_profiles)):
            if (curr := self.player_profiles.get(curr_pid, None)) is None:
                log_and_abort(status.HTTP_404_NOT_FOUND, f"Refusing to load results for nonexistent Player \"{head_player_id}\"")
                return []
            
            curr_pid = curr.source

            # NOTE: this adds player ids in REVERSE order
            player_source_chain.append(curr_pid)

        return [
            dict(
                creator=self.player_profiles[pid].as_dict() | dict(game_code=self.code),
                content=self.results[pid][i]
            ) for i, pid in enumerate(player_source_chain[::-1]) if self.results[pid][i] is not None
        ]