FROM python:3.12-slim-bullseye

WORKDIR /opt/ag/dudl_server
COPY pyproject.toml ./


COPY dudl dudl
RUN python3 -m pip install -U .

ARG DUDL_VERSION
ENV DUDL_VERSION=${DUDL_VERSION}

EXPOSE 8001
ENTRYPOINT ["start-dudl"]
