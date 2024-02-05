
from typing import Any, Dict, List

from flask_api import status

from dudl.web.models.game import Game
from dudl.web.utils import log_and_abort
from dudl.web.models.playerprofile import PlayerProfile


class GameCollection:
    """ A collection of unique Game objects """
    def __init__(self) -> None:
        self.games: Dict[str, Game] = {}
    

    def add_game(self, game_code: str):
        if game_code in self.games:
            # can't add the same game twice
            raise AttributeError(f"Game \"{game_code}\" already exists!")
        
        self.games[game_code] = Game(code=game_code)


    def add_player_to_game(self, game_code: str, player_id: str, creator: bool=False):
        try:
            self.games[game_code].add_player_to_game(player_id, creator)
        except:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Game \"{game_code}\" does not exist!")
    
    def update_player_profile_in_game(self, game_code: str, player_id: str, nickname: str, rgba: Dict[str, Any]):
        try:
            self.games[game_code].update_player_profile(player_id=player_id,
                                                        nickname=nickname,
                                                        rgba=rgba)
        except:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Game \"{game_code}\" does not exist!")

    def get_all_active_players_profiles_in_game(self, game_code: str)-> List[PlayerProfile]:
        try:
            return [v for v in self.games[game_code].player_profiles.values()]
        except:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Game \"{game_code}\" does not exist!")