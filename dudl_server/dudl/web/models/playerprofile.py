from typing import Dict
from marshmallow import fields, Schema

class PlayerProfile:
    def __init__(self, player_id: str, nickname: str, rgba: Dict[str, float], is_host: bool = False) -> None:
        self.player_id = player_id
        self.nickname = nickname
        self.rgba = rgba
        self.is_host = is_host

        self.__source_player_id: str = None
    
    def make_host(self):
        self.is_host = True

    @property
    def source(self):
        return self.__source_player_id
    
    @source.setter
    def source(self, value: str):
        if value == self.player_id:
            return ValueError(f"Player <{self.player_id}> cannot be its own source!")
        self.__source_player_id = value

    def as_dict(self):
        return {
            "playerId": self.player_id,
            "nickname": self.nickname,
            "rgba": self.rgba,
            "isHost": self.is_host
        }

    def __repr__(self) -> str:
        return f" ({'#' if self.is_host else ''}{self.player_id}: <{self.nickname}, {list(self.rgba.values())}>) "
