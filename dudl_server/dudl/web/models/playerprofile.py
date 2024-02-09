from typing import Dict
from marshmallow import fields, Schema

class PlayerProfileSchema(Schema):
    player_id = fields.String()
    nickname = fields.String()
    rgba = fields.Dict(keys=fields.Str(), values=fields.Float())

class PlayerProfile:
    def __init__(self, player_id: str, nickname: str, rgba: Dict[str, float], is_host: bool = False) -> None:
        self.player_id = player_id
        self.nickname = nickname
        self.rgba = rgba
        self.is_host = is_host
    
    def make_host(self):
        self.is_host = True

    def as_dict(self):
        return {
            "playerId": self.player_id,
            "nickname": self.nickname,
            "rgba": self.rgba
        }

    def __repr__(self) -> str:
        return f" ({'#' if self.is_host else ''}{self.player_id}: <{self.nickname}, {list(self.rgba.values())}>) "
