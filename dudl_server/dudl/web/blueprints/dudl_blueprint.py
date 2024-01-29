from flask_api import status
import randomname
from flask import current_app, request
from flask.views import MethodView
from flask_smorest import Blueprint


dudl_blueprint = Blueprint("dudl", __name__, url_prefix='/', description="DUDL REST Endpoints")


@dudl_blueprint.route('/start-new-game')
class NewGame(MethodView):
    def post(self):
        """ DUDL is up and running """
        if not (requester_id := str(request.get_json().get('requester_id'))):
            return {}, 400

        current_app.logger.debug(f"Generating new game code for User {requester_id} ...")

        return dict(code=randomname.get_name()), 200
