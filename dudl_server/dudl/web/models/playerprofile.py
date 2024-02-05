from typing import Dict
from marshmallow import fields, Schema

class PlayerProfileSchema(Schema):
    player_id = fields.String()
    nickname = fields.String()
    rgba = fields.Dict(keys=fields.Str(), values=fields.Float())

class PlayerProfile:
    def __init__(self, player_id: str, nickname: str, rgba: Dict[str, float], creator: bool = False) -> None:
        self.player_id = player_id
        self.nickname = nickname
        self.creator = creator
        self.rgba = rgba

    def is_creator(self):
        return self.creator

    def __repr__(self) -> str:
        return f" ({self.player_id}: <{self.nickname}, {list(self.rgba.values)}>) "
