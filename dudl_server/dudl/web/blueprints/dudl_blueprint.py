from typing import Dict, List, Tuple
import randomname
from flask_api import status
from flask import current_app, request
from flask.views import MethodView
from flask_smorest import Blueprint
from flask import current_app, request

from dudl.web.utils import abort_if_missing
from dudl.web.models.playerprofile import PlayerProfile
from dudl.web.models.gamecollection import GameCollection

collection: GameCollection = GameCollection()

dudl_blueprint = Blueprint("dudl", __name__, url_prefix='/', description="DUDL REST Endpoints")

@dudl_blueprint.route('/start-game')
class NewGame(MethodView):
    def post(self)-> Tuple[Dict[str, str], int]:
        """ Create a new DUDL Game """
        player_id: str = abort_if_missing(request, "playerId")

        game_code = randomname.get_name()
        current_app.logger.debug(f"Generating new GameCode \"{game_code}\" for Player #{player_id} ...")
        collection.add_game(game_code=game_code, host_id=player_id)
        collection.add_player_to_game(game_code=game_code, player_id=player_id)


        return dict(gameCode=game_code), status.HTTP_200_OK
    
@dudl_blueprint.route('/join-game')
class JoinGame(MethodView):
    def post(self)-> Tuple[Dict[str, str], int]:
        """ Join an existing DUDL Game """
        game_code: str = abort_if_missing(request, "gameCode")
        player_id: str = abort_if_missing(request, "playerId")

        current_app.logger.debug(f"Attempting to add Player {player_id} to Game {game_code}...")
        collection.add_player_to_game(game_code=game_code, player_id=player_id)

        return dict(playerId=player_id), status.HTTP_200_OK


@dudl_blueprint.route('update-player-profile')
class UpdatePlayerProfile(MethodView):
    def post(self)-> Tuple[Dict[str, str], int]:
        """ Update PlayerProfile for a player within an existing DUDL Game """
        game_code: str = abort_if_missing(request, "gameCode")
        player_id: str = abort_if_missing(request, "playerId")
        nickname: str  = abort_if_missing(request, "nickname")
        rgba: Dict[str, float]  = abort_if_missing(request, "rgba")

        collection.update_player_profile_in_game(game_code=game_code, player_id=player_id, nickname=nickname, rgba=rgba)

        current_app.logger.debug(f"Updated Player {player_id} (aka {nickname})'s Profile ({rgba}) ...")

        return dict(playerId=player_id), status.HTTP_200_OK

@dudl_blueprint.route('get-all-active-player-profiles')
class GetAllActivePlayerProfiles(MethodView):
    def post(self)-> Tuple[List[PlayerProfile], int]:
        """ DUDL is up and running """
        game_code: str = abort_if_missing(request, "gameCode")

        profiles = collection.get_all_active_players_profiles_in_game(game_code=game_code)
        current_app.logger.debug(f"Returning all active players in Game \"{game_code}\": {profiles}")

        return [p.as_dict() for p in profiles], status.HTTP_200_OK

@dudl_blueprint.route('eject-player')
class EjectPlayer(MethodView):
    def post(self)-> Tuple[PlayerProfile, int]:
        """ DUDL is up and running """
        game_code: str = abort_if_missing(request, "gameCode")
        player_id: str = abort_if_missing(request, "playerId")

        profiles = collection.remove_player_from_all_games(player_id=player_id)
        current_app.logger.debug(f"Returning all active players in Game \"{game_code}\": {profiles}")

        return [p.as_dict() for p in profiles], status.HTTP_200_OK