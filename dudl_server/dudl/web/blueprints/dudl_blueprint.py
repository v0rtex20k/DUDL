from flask_api import status
from flask.views import MethodView
from flask_smorest import Blueprint


dudl_blueprint = Blueprint("dudl", __name__, url_prefix='/', description="DUDL REST Endpoints")

@dudl_blueprint.route('/')
class Home(MethodView):
    def get(self):
        return "DUDL is up and running"
    
    # data = {
    #     "id" : "CODE",
    #     "players": [{
    #         "id": "CODE",
    #         "name": "Victor",
    #         "turn_index": 0
    #     }]
    # }
