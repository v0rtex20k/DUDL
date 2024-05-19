from typing import Dict, List, Tuple
from flasgger import swag_from
from flask_api import status
from flask import current_app, request
from flask.views import MethodView
from flask_smorest import Api, Blueprint
from flask import current_app, request

from dudl.web.utils import abort_if_missing, log_and_abort
from dudl.web.models.playerprofile import PlayerProfile
from dudl.web.models.gamecollection import GameCollection

collection: GameCollection = GameCollection()

dudl_blueprint = Blueprint("dudl", __name__, url_prefix='/', description="DUDL REST Endpoints")

@dudl_blueprint.route('debug')
class Debug(MethodView):
    def post(self):
        # NOTE: FOR DEBUG PURPOSES ONLY!!
        game_code, player_id = abort_if_missing(request, "gameCode", "playerId")

        fake_uuid_1 = "F01959E7-CA61-42FA-B4C2-BA5775F7D146"
        fake_uuid_2 = "CC4B4E2E-5CEB-4007-8C4E-B3C1B8113182"
        collection.add_game(host_id=player_id, game_code=game_code)
        
        collection.add_player_to_game(game_code=game_code, player_id=fake_uuid_1)
        collection.add_player_to_game(game_code=game_code, player_id=fake_uuid_2)

        collection.update_player_profile_in_game(game_code=game_code, player_id=player_id, nickname="Yoda", rgba=dict(r=0, g=255, b=0, a=0.5))
        collection.update_player_profile_in_game(game_code=game_code, player_id=fake_uuid_1, nickname="Darth Vader", rgba=dict(r=255, g=0, b=0, a=0.5))
        collection.update_player_profile_in_game(game_code=game_code, player_id=fake_uuid_2, nickname="Obi-Wan Kenobi", rgba=dict(r=0, g=0, b=255, a=0.5))

        collection.games[game_code].start()

        assert collection.games[game_code].started

        return {}, status.HTTP_200_OK

@dudl_blueprint.route('create-game')
class CreateGame(MethodView):
    @swag_from('create-game.yml')
    def post(self)-> Tuple[Dict[str, str], int]:
        """ Create a new DUDL Game """
        player_id: str = abort_if_missing(request, "playerId")

        game_code = collection.add_game(host_id=player_id)

        return dict(gameCode=game_code), status.HTTP_200_OK
    
@dudl_blueprint.route('join-game')
class JoinGame(MethodView):
    def post(self)-> Tuple[Dict[str, str], int]:
        """ Join an existing DUDL Game """
        game_code, player_id = abort_if_missing(request, "gameCode", "playerId")

        existing_player = False

        if isinstance(collection.get_all_active_profiles_in_game(game_code=game_code).get(player_id), PlayerProfile):
            existing_player = True
        else:
            current_app.logger.debug(f"Attempting to add Player {player_id} to Game {game_code}...")
            collection.add_player_to_game(game_code=game_code, player_id=player_id)


        return dict(playerId=player_id, existingPlayer=existing_player), status.HTTP_200_OK
    
@dudl_blueprint.route('leave-game')
class LeaveGame(MethodView):
    def post(self)-> Tuple[Dict[str, str], int]:
        """ Leave an existing DUDL Game """
        game_code, player_id = abort_if_missing(request, "gameCode", "playerId")

        was_removed = False

        if isinstance(collection.get_all_active_profiles_in_game(game_code=game_code).get(player_id), PlayerProfile):
            existing_player = True
            current_app.logger.debug(f"Attempting to remove Player {player_id} from Game {game_code}...")
            rem = collection.remove_player_from_game(player_id=player_id, game_code=game_code)
            was_removed = (rem is not None)

        return dict(removed=was_removed), status.HTTP_200_OK


@dudl_blueprint.route('update-player-profile')
class UpdatePlayerProfile(MethodView):
    def post(self)-> Tuple[Dict[str, str], int]:
        """ Update PlayerProfile for a player within an existing DUDL Game """
        game_code, player_id, nickname, rgba = abort_if_missing(request, "gameCode", "playerId", "nickname", "rgba")

        collection.update_player_profile_in_game(game_code=game_code, player_id=player_id, nickname=nickname, rgba=rgba)

        current_app.logger.debug(f"Updated Player {player_id} (aka {nickname})'s Profile ({rgba}) ...")

        return dict(playerId=player_id), status.HTTP_200_OK

@dudl_blueprint.route('get-all-active-player-profiles')
class GetAllActivePlayerProfiles(MethodView):
    def post(self)-> Tuple[List[PlayerProfile], int]:
        """ DUDL is up and running """
        game_code: str = abort_if_missing(request, "gameCode")

        profiles = collection.get_all_active_profiles_in_game(game_code=game_code)
        current_app.logger.debug(f"Returning all active players in Game \"{game_code}\": {profiles}")

        active_profiles = []
        for p in profiles.values() or []:
            try:
                active_profiles.append(p.as_dict())
            except:
                pass
        
        return active_profiles, status.HTTP_200_OK

@dudl_blueprint.route('game-status')
class GameStatus(MethodView):
    def post(self)-> Tuple[bool, int]:
        """ DUDL is up and running """
        game_code: str = abort_if_missing(request, "gameCode")

        try:
            is_started = collection.games[game_code].started
            current_app.logger.debug(f"Game \"{game_code}\" has{'' if is_started else ' NOT'} started!")
            return dict(started=collection.games[game_code].started), status.HTTP_200_OK
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Could not retrieve the status of Game \"{game_code}\": {e}")

@dudl_blueprint.route('start-game')
class StartGame(MethodView):
    def post(self)-> Tuple[PlayerProfile, int]:
        game_code: str = abort_if_missing(request, "gameCode")
        try:
            collection.games[game_code].start()
            if collection.games[game_code].started:
                current_app.logger.debug(f"Manually Started Game \"{game_code}\"!")
                return {}, status.HTTP_200_OK
            else:
                current_app.logger.warning(f"Failed to start Game \"{game_code}\"!")
                return {}, status.HTTP_412_PRECONDITION_FAILED
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Could not start Game \"{game_code}\": {e}")


#### GAME DYNAMICS ### 

@dudl_blueprint.route('upload-content')
class UploadContent(MethodView):
    def post(self)-> Tuple[PlayerProfile, int]:
        game_code, player_id, content, round_idx = abort_if_missing(request, "gameCode", "playerId", "content", "roundIdx")

        try:
            current_app.logger.debug(f"Uploading Player <{player_id}>'s content for Round {round_idx} of Game \"{game_code}\": \"{content}\" ...")
            collection.games[game_code].upload_content(content=content, player_id=player_id, round_idx=round_idx)
            
            return {}, status.HTTP_200_OK
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to upload Player <{player_id}>'s content for Round {round_idx} of Game \"{game_code}\": {e}")

@dudl_blueprint.route('download-content')
class DownloadContent(MethodView):
    def post(self)-> Tuple[PlayerProfile, int]:
        game_code, player_id, round_idx = abort_if_missing(request, "gameCode", "playerId", "roundIdx")

        try:
            content = collection.games[game_code].download_content(player_id=player_id, round_idx=round_idx)
            current_app.logger.debug(f"Downloading Player <{player_id}>'s content for Round {round_idx} of Game \"{game_code}\":\t\"{content}\" ...")
            
            if content:
                return dict(content=content), status.HTTP_200_OK
            else:
                current_app.logger.warning(f"Got null content for Player <{player_id}>'s content for Round {round_idx} of Game \"{game_code}\"")
                return {}, status.HTTP_204_NO_CONTENT
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to download Player <{player_id}>'s content for Round {round_idx} of Game \"{game_code}\": {e}")