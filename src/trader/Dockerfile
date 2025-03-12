FROM python:3.12.6-slim-bookworm
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /python-docker

COPY requirements.txt .
RUN pip3 install --root-user-action=ignore -r requirements.txt

COPY app.py .
COPY model.py .

ENV ROUTER_HOST="router"
ENV PYTHONUNBUFFERED=1

EXPOSE 9001
CMD [ "flask", "run", "--host=0.0.0.0", "-p", "9001" ]
