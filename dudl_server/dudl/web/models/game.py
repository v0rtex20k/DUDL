from flask_api import status
from typing import Any, Dict, Set
from marshmallow import Schema, ValidationError, fields, validates

from dudl.web.utils import log_and_abort
from dudl.web.models.playerprofile import PlayerProfile, PlayerProfileSchema

class GameSchema(Schema):
    code = fields.String()
    player_profiles = fields.Dict(keys=fields.Str(), values=fields.Dict())
    data = fields.Dict(keys=fields.Str(), values=fields.String())

    @validates('player_profiles')
    def no_duplicate_player_profiles(self, value: list):
        if len(value) != len(set(value)):
            raise ValidationError('DUDL does not support duplicate player profiles')

class Game:
    def __init__(self, code: str) -> None:
        self.code = code
        self.player_profiles: Dict[str, PlayerProfile] = {}
        self.data: Dict[str, Any] = {}

    def update_player_profile(self, player_id: str, nickname: str, rgba: Dict[str, Any]):
        try:
            if player_id in self.player_profiles:
                creator = self.player_profiles[player_id]
                self.player_profiles[player_id] = PlayerProfile(
                    player_id=player_id, nickname=nickname, rgba=rgba, creator=creator
                )
            else:
                raise AttributeError(f"Duplicate Player \"{player_id}\"")
        except:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Refusing to update PlayerProfile for \"{player_id}\"")

        self.player_profiles.add(PlayerProfile(
            player_id=player_id, nickname=nickname, rgba=rgba
        ))

    def add_player_to_game(self, player_id: str, creator: bool=False):
        self.player_profiles[player_id] = creator


    # TODO: flesh data out