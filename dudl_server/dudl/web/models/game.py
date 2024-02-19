import random
from copy import deepcopy
from flask_api import status
from typing import Any, Dict, Optional, Set
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

    def start(self):
        if len(self.player_profiles or []) > 1:
            self.started = True

        n_players = len(self.player_profiles)

        shuffled_profiles = deepcopy(list(self.player_profiles.keys()))
        random.shuffle(shuffled_profiles)
        for player_id, profile in self.player_profiles.items():
            profile.target = shuffled_profiles[(shuffled_profiles.index(player_id) + 1) % n_players]



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


    # TODO: flesh data out