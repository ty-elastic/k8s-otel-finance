FROM python:3.12.6-slim-bookworm
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /python-docker

COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip pip3 install --root-user-action=ignore -r requirements.txt

COPY app.py .

ENV TRADER_SERVICE="trader:9001"
ENV PYTHONUNBUFFERED=1

EXPOSE 9002
CMD [ "flask", "run", "--host=0.0.0.0", "-p", "9002" ]