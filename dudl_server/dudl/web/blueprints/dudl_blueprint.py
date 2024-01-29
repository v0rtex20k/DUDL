from flask import current_app
from flask_api import status
from flask.views import MethodView
from flask_smorest import Blueprint


dudl_blueprint = Blueprint("dudl", __name__, url_prefix='/', description="DUDL REST Endpoints")


@dudl_blueprint.route('/')
class Home(MethodView):
    def get(self):
        """ DUDL is up and running """
        current_app.logger.info("GOT GET!")
        data = {
            "id": "CODE",
            "players": [{
                "id": "CODE",
                "name": "Victor",
                "turn_index": 0
            }]
        }

        return data, 200
