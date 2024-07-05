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
        
        # ADD PLAYERS
        collection.add_player_to_game(game_code=game_code, player_id=fake_uuid_1)
        collection.add_player_to_game(game_code=game_code, player_id=fake_uuid_2)

        # UPDATE PROFILES
        collection.update_player_profile_in_game(game_code=game_code, player_id=player_id, nickname="Yoda", rgba=dict(r=0, g=255, b=0, a=0.5))
        collection.update_player_profile_in_game(game_code=game_code, player_id=fake_uuid_1, nickname="Darth Vader", rgba=dict(r=255, g=0, b=0, a=0.5))
        collection.update_player_profile_in_game(game_code=game_code, player_id=fake_uuid_2, nickname="Obi-Wan Kenobi", rgba=dict(r=0, g=0, b=255, a=0.5))

        # START GAME
        collection.games[game_code].start()
        assert collection.games[game_code].started

        # ROUND 0: Initial Prompt
        collection.games[game_code].upload_content(content="Try you must", player_id=player_id, round_idx=0)
        collection.games[game_code].upload_content(content="I am your father", player_id=fake_uuid_1, round_idx=0)
        collection.games[game_code].upload_content(content="I have the high ground", player_id=fake_uuid_2, round_idx=0)
        
        random_drawing: str = "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"

        # ROUND 1: DrawFromPrompt
        collection.games[game_code].upload_content(content=random_drawing, player_id=player_id, round_idx=1)
        collection.games[game_code].upload_content(content=random_drawing, player_id=fake_uuid_1, round_idx=1)
        collection.games[game_code].upload_content(content=random_drawing, player_id=fake_uuid_2, round_idx=1)
        
        # ROUND 2: PromptFromDrawing
        collection.games[game_code].upload_content(content="green lightsaber", player_id=player_id, round_idx=2)
        collection.games[game_code].upload_content(content="red lightsaber", player_id=fake_uuid_1, round_idx=2)
        collection.games[game_code].upload_content(content="blue lightsaber", player_id=fake_uuid_2, round_idx=2)

        # END GAME
        collection.games[game_code].end()

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
        # uncomment as needed
        # current_app.logger.debug(f"Returning all active players in Game \"{game_code}\": {profiles}")

        active_profiles = []
        for p in profiles.values() or []:
            try:
                active_profiles.append(p.as_dict() | dict(game_code=game_code))
            except:
                pass
        
        return active_profiles, status.HTTP_200_OK

@dudl_blueprint.route('game-status')
class GameStatus(MethodView):
    def post(self)-> Tuple[bool, int]:
        """ DUDL is up and running """
        game_code: str = abort_if_missing(request, "gameCode")

        try:
            # is_started = collection.games[game_code].started
            # FIXME: uncomment as needed
            # current_app.logger.debug(f"Game \"{game_code}\" has{'' if is_started else ' NOT'} started!")
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

@dudl_blueprint.route('end-game')
class EndGame(MethodView):
    def put(self)-> Tuple[PlayerProfile, int]:
        game_code, player_id = abort_if_missing(request, "gameCode", "playerId")
        try:
            collection.games[game_code].end()
            if not collection.games[game_code].started:
                current_app.logger.debug(f"Manually Ended Game \"{game_code}\"!")
                return {}, status.HTTP_200_OK
            else:
                current_app.logger.warning(f"Failed to start Game \"{game_code}\"!")
                return {}, status.HTTP_412_PRECONDITION_FAILED
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Could not start Game \"{game_code}\": {e}")

#### GAME DYNAMICS ####

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


#### GAME RESULTS ####

@dudl_blueprint.route('load-results')
class LoadResults(MethodView):
    def post(self)-> List[Dict[str, str | PlayerProfile]]:
        game_code, player_id = abort_if_missing(request, "gameCode", "playerId")

        try:
            results = collection.games[game_code].load_player_results(head_player_id=player_id)
            current_app.logger.debug(f"Loading Player <{player_id}>'s Results in Game \"{game_code}\":\t\"{results}\" ...")
            
            if results:
                return results, status.HTTP_200_OK
            else:
                current_app.logger.warning(f"No results found for Player <{player_id}>'s in Game \"{game_code}\"")
                return [], status.HTTP_204_NO_CONTENT
        except Exception as e:
            log_and_abort(status.HTTP_404_NOT_FOUND, f"Failed to load Player <{player_id}>'s results in Game \"{game_code}\": {e}")
