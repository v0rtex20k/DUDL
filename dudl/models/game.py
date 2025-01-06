import random
from copy import deepcopy
from flask_api import status
from flask import current_app
from typing import Any, List, Dict, Optional

from dudl.utils import log_and_abort
from dudl.models.playerprofile import PlayerProfile

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
                    self.player_profiles[pid].parent = batting_order[((i-1) % n_players)]
                    self.player_profiles[batting_order[((i-1) % n_players)]].child = self.player_profiles[pid].player_id

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
        if content:
            self.results[player_id][round_idx] = content

    def download_content(self, player_id: str, round_idx: int)-> str:
        return self.results[self.player_profiles[player_id].parent][round_idx]
    
    def load_player_results(self, head_player_id: str)-> List[Dict[str, str | PlayerProfile]]:
        npp = len(self.player_profiles)
        player_results_chain: List[str] = []

        def get_child(pid: str)-> str:
            if (profile := self.player_profiles.get(pid, None)) is None:
                log_and_abort(status.HTTP_404_NOT_FOUND, f"Refusing to load results for nonexistent Player \"{head_player_id}\"")
                return None
            
            return profile.child

        i = 0
        curr_pid = head_player_id

        while i < npp:
            player_results_chain.append((curr_pid, self.results[curr_pid][i]))
            curr_pid = get_child(curr_pid)
            i += 1

        return [
            dict(
                creator=self.player_profiles[pid].as_dict() | dict(game_code=self.code),
                content=content
            ) for pid, content in player_results_chain if content is not None
        ]