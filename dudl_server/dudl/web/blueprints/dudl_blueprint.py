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

# NOTE: FOR DEBUG PURPOSES ONLY!!
def start_fake_solo_game(gc: str, pid: str):
    import uuid
    collection.add_game(host_id=pid, game_code=gc)
    
    pid2 = str(uuid.uuid4()).upper()
    collection.add_player_to_game(game_code=gc, player_id=pid2)

    collection.update_player_profile_in_game(game_code=gc, player_id=pid, nickname="Yoda", rgba=dict(r=0, g=255, b=0, a=0.5))
    collection.update_player_profile_in_game(game_code=gc, player_id=pid2, nickname="Darth Vader", rgba=dict(r=255, g=0, b=0, a=0.5))

    collection.games[gc].start()

    assert collection.games[gc].started

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
            
@dudl_blueprint.route('next-target')
class NextTarget(MethodView):
    def post(self)-> Tuple[str, int]:
        game_code, player_id = abort_if_missing(request, "gameCode", "playerId")

        try:
            if (game := collection.games[game_code]).started and player_id in game.player_profiles:
                target_player_id = game.targets[player_id].popleft()
                current_app.logger.debug(f"\t[{game_code}] {player_id} --(will_target)--> {player_id}")
                return dict(target=target_player_id), status.HTTP_200_OK
        except IndexError:
            current_app.logger.debug(f"\t[{game_code}] {player_id} has run out of targets")
            return dict(target=target_player_id), status.HTTP_204_NO_CONTENT
        except Exception as e:
            log_and_abort(status.HTTP_409_CONFLICT, f"Could not retrieve the status of Game \"{game_code}\": {e}")

@dudl_blueprint.route('upload-text')
class UploadText(MethodView):
    def post(self)-> Tuple[PlayerProfile, int]:
        game_code, player_id, target_id, text = abort_if_missing(request, "gameCode", "playerId", "targetId", "text")

        start_fake_solo_game(game_code, player_id)

        try:
            current_app.logger.debug(f"Submitting Player <{player_id}>'s text for Game \"{game_code}\": \"{text}\" ...")
            collection.games[game_code].upload_text(text=text, player_id=player_id, target_id=target_id)
            return {}, status.HTTP_200_OK
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to submit Player <{player_id}>'s text for Game \"{game_code}\": {e}")

@dudl_blueprint.route('upload-drawing')
class UploadDrawing(MethodView):
    def post(self)-> Tuple[PlayerProfile, int]:
        game_code, player_id, target_id, encoded_drawing = abort_if_missing(request, "gameCode", "playerId", "targetId", "encodedDrawing")

        start_fake_solo_game(game_code, player_id)

        try:
            current_app.logger.debug(f"Submitting Player <{player_id}>'s drawing for Game \"{game_code}\": \n\t\"{encoded_drawing}\" ...")
            collection.games[game_code].upload_drawing(drawing=encoded_drawing, player_id=player_id, target_id=target_id)
            return {}, status.HTTP_200_OK
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to submit Player <{player_id}>'s text for Game \"{game_code}\": {e}")


@dudl_blueprint.route('download-text')
class DownloadText(MethodView):
    def post(self)-> Tuple[PlayerProfile, int]:
        game_code, player_id, target_id, text = abort_if_missing(request, "gameCode", "playerId", "targetId", "text")

        start_fake_solo_game(game_code, player_id)

        try:
            current_app.logger.debug(f"Submitting Player <{player_id}>'s text for Game \"{game_code}\": \"{text}\" ...")
            collection.games[game_code].upload_text(text=text, player_id=player_id, target_id=target_id)
            return {}, status.HTTP_200_OK
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to submit Player <{player_id}>'s text for Game \"{game_code}\": {e}")

@dudl_blueprint.route('download-drawing')
class DownloadDrawing(MethodView):
    def post(self)-> Tuple[PlayerProfile, int]:
        game_code, player_id, target_id, encoded_drawing = abort_if_missing(request, "gameCode", "playerId", "targetId", "encodedDrawing")

        start_fake_solo_game(game_code, player_id)

        try:
            current_app.logger.debug(f"Submitting Player <{player_id}>'s drawing for Game \"{game_code}\": \n\t\"{encoded_drawing}\" ...")
            collection.games[game_code].upload_drawing(drawing=encoded_drawing, player_id=player_id, target_id=target_id)
            return {}, status.HTTP_200_OK
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to submit Player <{player_id}>'s text for Game \"{game_code}\": {e}")


@dudl_blueprint.route('pull-content')
class PullContent(MethodView):
    def post(self)-> Tuple[Dict[str, str], int]:
        game_code, player_id = abort_if_missing(request, "gameCode", "playerId")

        try:
            current_app.logger.debug(f"Pulling Player <{player_id}>'s content for Game \"{game_code}\" ...")
            content = collection.games[game_code].pull_content(player_id=player_id)
            current_app.logger.debug(f"\t--> \"{content}\"")
            return dict(content=content), status.HTTP_200_OK
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to pull Player <{player_id}>'s content for Game \"{game_code}\": {e}")

@dudl_blueprint.route('push-content')
class PushContent(MethodView):
    def post(self)-> Tuple[PlayerProfile, int]:
        game_code, player_id, content = abort_if_missing(request, "gameCode", "playerId", "content")

        start_fake_solo_game(game_code, player_id)

        try:
            current_app.logger.debug(f"Pushing Player <{player_id}>'s content for Game \"{game_code}\" \n\t--> {content} ...")
            content = collection.games[game_code].push_content(content=content, player_id=player_id)
            return {}, status.HTTP_200_OK
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to push Player <{player_id}>'s content for Game \"{game_code}\": {e}")

