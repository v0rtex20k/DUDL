import randomname
from flask_api import status
import randomname
from flask import current_app, request
from flask.views import MethodView
from flask_smorest import Blueprint
from flask import current_app, request


dudl_blueprint = Blueprint("dudl", __name__, url_prefix='/', description="DUDL REST Endpoints")


@dudl_blueprint.route('/start-game')
class NewGame(MethodView):
    def post(self):
        """ DUDL is up and running """
        if not (player_id := str(request.get_json().get('playerId'))):
            return {}, 400

        current_app.logger.debug(f"Generating new game code for User {player_id} ...")

        return dict(gameCode=randomname.get_name()), 200
    
@dudl_blueprint.route('/join-game')
class JoinGame(MethodView):
    def post(self):
        """ DUDL is up and running """
        if not (player_id := str(request.get_json().get('playerId'))):
            return {}, 400
        
        if not (game_code := str(request.get_json().get('gameCode'))):
            return {}, 400

        current_app.logger.debug(f"Adding User {player_id} to Game {game_code}...")

        return dict(playerId=player_id), 200
