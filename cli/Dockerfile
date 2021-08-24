FROM python:3.8-slim-buster

WORKDIR /opt/install-script

COPY . .

RUN set -eux; \
    pip install -e .
