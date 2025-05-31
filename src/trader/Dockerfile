FROM python:3.12.6-slim-bookworm
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /python-docker

COPY requirements.txt .
RUN pip3 install --root-user-action=ignore -r requirements.txt

RUN edot-bootstrap --action=install
RUN pip3 uninstall -y opentelemetry-instrumentation-click

COPY app.py .
COPY model.py .

ENV ROUTER_HOST="router"
ENV PYTHONUNBUFFERED=1

ENV OTEL_SERVICE_NAME="trader"
ENV OTEL_PYTHON_LOG_LEVEL="info"
ENV OTEL_PYTHON_LOG_CORRELATION="true"
ENV OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED="true"
ENV OTEL_EXPERIMENTAL_RESOURCE_DETECTORS="process_runtime"
ENV OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE="delta"

EXPOSE 9001
CMD [ "flask", "run", "--host=0.0.0.0", "-p", "9001" ]
