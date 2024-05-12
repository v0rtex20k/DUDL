from collections import deque
import random
from copy import deepcopy
from flask_api import status
from typing import Any, Dict, Optional, List, Tuple
from marshmallow import Schema, ValidationError, fields, validates

from dudl.web.utils import log_and_abort
from dudl.web.models.playerprofile import PlayerProfile, PlayerProfileSchema

class GameSchema(Schema):
    code = fields.String()
    started = fields.Bool()
    player_profiles = fields.Dict(keys=fields.Str(), values=fields.Dict())
    data = fields.Dict(keys=fields.Str(), values=fields.String())

    @validates('player_profiles')
    def no_duplicate_player_profiles(self, value: list):
        if len(value) != len(set(value)):
            raise ValidationError('DUDL does not support duplicate player profiles')

class Game:
    def __init__(self, code: str) -> None:
        self.code = code
        self.started = False
        self.player_profiles: Dict[str, PlayerProfile] = {}
        self.data: Dict[str, Any] = {}

        # {source_player_id_1: {target_player_id_1: content, ... }, ... }
        self.results: Dict[str, Dict[str, str]] = {}

        self.targets: Dict[str, deque] = {}

    def start(self):
        if len(self.player_profiles or []) > 1:
            self.started = True

        n_players = len(self.player_profiles)

        shuffled_player_ids = deepcopy(list(self.player_profiles.keys()))
        random.shuffle(shuffled_player_ids)

        for i, pid in enumerate(shuffled_player_ids):
            target_ids = [shuffled_player_ids[(i+j+1) % n_players] for j in range(len(shuffled_player_ids))]
            self.results[pid] = dict.fromkeys(target_ids)
            self.targets[pid] = deque(target_ids, maxlen=len(shuffled_player_ids))

        print(f"GAME {self.code} has STARTED")

    def get_player_profile(self, player_id: str)-> Optional[PlayerProfile]:
        return self.player_profiles.get(player_id)

    def update_player_profile(self, player_id: str, nickname: str, rgba: Dict[str, Any]):
        try:
            if (profile := self.player_profiles.get(player_id)) is not None:
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


    def upload_text(self, text: str, player_id: str, target_id: str):
        if (player_profile := self.player_profiles.get(player_id)) is None:
            raise ValueError(f"Player <{player_id}> is not allowed to push content to {self.code}")
        
        player_profile

    def upload_drawing(self, drawing: str, player_id: str, target_id: str):
        if (player_profile := self.player_profiles.get(player_id)) is None:
            raise ValueError(f"Player <{player_id}> is not allowed to push content to {self.code}")
        
        player_profile

    def upload_text(self, text: str, player_id: str, target_id: str):
        if (player_profile := self.player_profiles.get(player_id)) is None:
            raise ValueError(f"Player <{player_id}> is not allowed to push content to {self.code}")
        
        player_profile

    def upload_drawing(self, drawing: str, player_id: str, target_id: str):
        if (player_profile := self.player_profiles.get(player_id)) is None:
            raise ValueError(f"Player <{player_id}> is not allowed to push content to {self.code}")
        
        player_profile
                
                