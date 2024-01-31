from typing import Any, Dict, NoReturn, Union
import randomname
from flask_api import status
import randomname
from flask import current_app, request
from flask.views import MethodView
from flask_smorest import Blueprint
from flask import current_app, request, Request

from dudl.web.utils import log_and_abort


dudl_blueprint = Blueprint("dudl", __name__, url_prefix='/', description="DUDL REST Endpoints")

def abort_if_missing(request: Request, attr: str, status_code: int = status.HTTP_400_BAD_REQUEST) -> Union[NoReturn, Any]:
    if not request or (val := request.get_json().get(attr)) is None:
        log_and_abort(status_code, f"Missing {attr} in Request!")
    
    return val


@dudl_blueprint.route('/start-game')
class NewGame(MethodView):
    def post(self):
        """ DUDL is up and running """
        player_id: str = abort_if_missing(request, "playerId")

        current_app.logger.debug(f"Generating new game code for Player {player_id} ...")

        return dict(gameCode=randomname.get_name()), status.HTTP_200_OK
    
@dudl_blueprint.route('/join-game')
class JoinGame(MethodView):
    def post(self):
        """ DUDL is up and running """
        player_id: str = abort_if_missing(request, "playerId")
        game_code: str = abort_if_missing(request, "gameCode")

        current_app.logger.debug(f"Adding Player {player_id} to Game {game_code}...")

        return dict(playerId=player_id), status.HTTP_200_OK


@dudl_blueprint.route('update-player-profile')
class UpdatePlayerProfile(MethodView):
    def post(self):
        """ DUDL is up and running """
        player_id: str = abort_if_missing(request, "playerId")
        nickname: str  = abort_if_missing(request, "nickname")
        rgba: Dict[str, float]  = abort_if_missing(request, "rgba")

        current_app.logger.debug(f"Updating Player {player_id} (aka {nickname})'s Profile ({rgba}) ...")

        return dict(playerId=player_id), status.HTTP_200_OK