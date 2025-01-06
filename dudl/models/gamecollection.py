
import traceback
import randomname
from flask_api import status
from flask import current_app
from typing import Any, Dict, List, Optional, Set

from dudl.models.game import Game
from dudl.utils import log_and_abort
from dudl.models.playerprofile import PlayerProfile


class GameCollection:
    """ A collection of unique Game objects """
    def __init__(self) -> None:
        self.games: Dict[str, Game] = {}
    
    def remove_player_from_game(self, player_id: str, game_code: str)-> str:
        try:
            if not (game := self.games.get(game_code)):
                raise AttributeError
            
            if player_id in game.player_profiles:
                del game.player_profiles[player_id]

                if not game.player_profiles:
                    # NOTE: in case the game is now empty, drop it
                    return game_code
                else:
                    new_host = list(game.player_profiles.keys())[0]

                    if isinstance(game.player_profiles[new_host], PlayerProfile):
                        game.player_profiles[new_host].make_host()
                    else:
                        game.player_profiles[new_host] = True

                    current_app.logger.info(f"Player \"{new_host}\" is now the host of {game_code}")
                
                current_app.logger.info(f"Removed Player \"{player_id}\" from {game_code}")
            
                return game_code

        except AttributeError as ae:
            traceback.print_exception(ae)
            log_and_abort(status.HTTP_404_NOT_FOUND, f"[RPFG] Game \"{game_code}\" does not exist")
        except Exception as e:
            traceback.print_exception(e)
            log_and_abort(status.HTTP_500_INTERNAL_SERVER_ERROR, f"Failed to remove Player {player_id} from Game {game_code}")

    def remove_player_from_all_games(self, player_id: str, excludes: Set[str] = {*()}):
        empties = [self.remove_player_from_game(player_id=player_id, game_code=gc) for gc in self.games if gc not in excludes]
        [self.games.pop(code) for code in empties if code is not None]

    def add_game(self, host_id: str, game_code: Optional[str]=None)-> str:
        if game_code not in self.games:
            while not game_code:
                potential_game_code = randomname.get_name()

                if not potential_game_code in self.games:
                    # can't add the same game twice
                    game_code = potential_game_code

            self.remove_player_from_all_games(host_id)
            
            new_game = Game(code=game_code)
            new_game.add_player(player_id=host_id, is_host=True)

            self.games[game_code] = new_game
            current_app.logger.debug(f"Added Game \"{game_code}\" with Host Player {host_id} ...")
        return game_code

    def add_player_to_game(self, game_code: str, player_id: str):
        try:
            if not (game := self.games.get(game_code)):
                raise AttributeError
            
            if game.started:
                current_app.logger.warning(f"Refusing to add Player {player_id} to ongoing Game {game_code}...")
                return

            if player_id not in game.player_profiles:
                # if they're not already in the game, they can't be the host!
                self.remove_player_from_all_games(player_id, excludes={game_code})
                game.add_player(player_id, is_host=False)
                current_app.logger.debug(f"Added Player {player_id} to Game {game_code}...")
            else:
                is_host = isinstance(game.player_profiles[player_id], bool) and game.player_profiles[player_id]
                current_app.logger.debug(f"Player {player_id} is already {'hosting' if is_host else 'in'} Game {game_code}...")
        except AttributeError as ae:
            traceback.print_exception(ae)
            log_and_abort(status.HTTP_404_NOT_FOUND, f"[AG] Game \"{game_code}\" does not exist")
        except Exception as e:
            traceback.print_exception(e)
            log_and_abort(status.HTTP_500_INTERNAL_SERVER_ERROR, f"Failed to add Player {player_id} to Game {game_code}")
    
    def update_player_profile_in_game(self, game_code: str, player_id: str, nickname: str, rgba: Dict[str, Any]):
        try:
            self.games[game_code].update_player_profile(player_id=player_id,
                                                        nickname=nickname,
                                                        rgba=rgba)
        except KeyError:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"[UPPIG] Game \"{game_code}\" does not exist")
        except Exception as e:
            traceback.print_exception(e)
            log_and_abort(status.HTTP_500_INTERNAL_SERVER_ERROR, f"Failed to update Player {player_id}'s profile in Game {game_code}")

    def get_all_active_profiles_in_game(self, game_code: str)-> Dict[str, PlayerProfile]:
        try:
            return self.games[game_code].player_profiles or {}
        except KeyError:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"[GAAPIG] Game \"{game_code}\" does not exist")
        except Exception as e:
            traceback.print_exception(e)
            log_and_abort(status.HTTP_500_INTERNAL_SERVER_ERROR, f"Failed to get all active PlayerProfiles in Game {game_code}")
