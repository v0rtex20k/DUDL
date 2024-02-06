
import traceback
from flask_api import status
from flask import current_app
from typing import Any, Dict, List, Set


from dudl.web.models.game import Game
from dudl.web.utils import log_and_abort
from dudl.web.models.playerprofile import PlayerProfile


class GameCollection:
    """ A collection of unique Game objects """
    def __init__(self) -> None:
        self.games: Dict[str, Game] = {}
    
    def remove_player_from_game(self, player_id: str, game_code: str)-> str:
        try:
            if not (game := self.games.get(game_code)):
                raise AttributeError
            
            if player_id in game.player_profiles:
                game.player_profiles.pop(player_id)
                if not game.player_profiles:
                    # NOTE: in case the game is now empty, drop it
                    return game_code
                
                current_app.logger.info(f"Removed Player \"{player_id}\" from {game_code}")

        except AttributeError as ae:
            traceback.print_exception(ae)
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Game \"{game_code}\" does not exist")
        except Exception as e:
            traceback.print_exception(e)
            log_and_abort(status.HTTP_500_INTERNAL_SERVER_ERROR, f"Failed to remove Player {player_id} from Game {game_code}")

    def remove_player_from_all_games(self, player_id: str, excludes: Set[str] = {*()}):
        empties = [self.remove_player_from_game(player_id=player_id, game_code=gc) for gc in self.games if gc not in excludes]
        [self.games.pop(code) for code in empties]

    def add_game(self, game_code: str, player_id: str):
        if game_code in self.games:
            # can't add the same game twice
            log_and_abort(status.HTTP_409_CONFLICT, f"Duplicate GameCode \"{game_code}\"")

        self.remove_player_from_all_games(player_id)
        
        self.games[game_code] = Game(code=game_code)

    def add_player_to_game(self, game_code: str, player_id: str, creator: bool=False):
        try:
            self.remove_player_from_all_games(player_id, excludes={game_code})
            if not (game := self.games.get(game_code)):
                raise AttributeError
            if game.get_player_profile(player_id) is None:
                game.add_player_to_game(player_id, creator)
            current_app.logger.debug(f"Added Player {'^^^' if creator else ''}{player_id} to Game {game_code}...")
        except NameError:
            log_and_abort(status.HTTP_400_BAD_REQUEST, f"Duplicate PlayerId: {player_id}")
        except AttributeError as ae:
            traceback.print_exception(ae)
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Game \"{game_code}\" does not exist")
        except Exception as e:
            traceback.print_exception(e)
            log_and_abort(status.HTTP_500_INTERNAL_SERVER_ERROR, f"Failed to add Player {'^^^' if creator else ''}{player_id} to Game {game_code}")
    
    def update_player_profile_in_game(self, game_code: str, player_id: str, nickname: str, rgba: Dict[str, Any]):
        try:
            self.games[game_code].update_player_profile(player_id=player_id,
                                                        nickname=nickname,
                                                        rgba=rgba)
        except Exception as e:
            traceback.print_exception(e)
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to update Player {player_id}'s profile in Game {game_code}")

    def get_all_active_players_profiles_in_game(self, game_code: str)-> List[PlayerProfile]:
        try:
            return [v for v in self.games[game_code].player_profiles.values()]
        except Exception as e:
            traceback.print_exception(e)
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to get all active PlayerProfiles in Game {game_code}")
