#!/bin/bash

# Nom du projet
PROJECT_NAME="flask_project"

# Créer le dossier
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# Créer un environnement virtuel
python3 -m venv venv

# Activer l’environnement virtuel
# (Note : cela ne fonctionne que dans une session interactive, mais requis pour les installations)
source venv/bin/activate

# Créer un fichier requirements.txt avec des dépendances
cat <<EOL > requirements.txt
flask
opentelemetry-api
opentelemetry-sdk
opentelemetry-exporter-jaeger
opentelemetry.instrumentation
opentelemetry.instrumentation.logging
opentelemetry-instrumentation-flask
logging
EOL

# Installer les dépendances
pip install -r requirements.txt

# Créer un fichier app.py avec un peu de code
cat <<EOF > app.py
from flask import Flask, request
from app_log import setup_syslog_logger

from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger.thrift import JaegerExporter

# === Configure OpenTelemetry ===
trace.set_tracer_provider(
    TracerProvider(
        resource=Resource.create({SERVICE_NAME: "flask-syslog-app"})
    )
)
jaeger_exporter = JaegerExporter(
    agent_host_name="localhost",  # ou l'IP de ta VM si externe
    agent_port=6831,
)
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)
tracer = trace.get_tracer(__name__)

# === Flask App ===
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)

# === Syslog Logger ===
logger = setup_syslog_logger()

@app.route("/")
def index():
    logger.info("Requête reçue sur /")
    with tracer.start_as_current_span("index-span"):
        return "Bonjour depuis Flask avec OpenTelemetry + Syslog !"

@app.route("/test")
def test():
    logger.info("Requête reçue sur /test")
    with tracer.start_as_current_span("test-span"):
        return "Route test OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

# Créer un fichier app.py avec un peu de code
cat <<EOF > app_log.py
# logging_syslog.conf
import logging
import logging.handlers

def setup_syslog_logger():
    logger = logging.getLogger("flaskapp")
    logger.setLevel(logging.INFO)

    handler = logging.handlers.SysLogHandler(address='/dev/log')  # pour Ubuntu/Debian
    formatter = logging.Formatter('%(asctime)s flaskapp: %(message)s')
    handler.setFormatter(formatter)

    logger.addHandler(handler)
    return logger
EOF

echo "✅ Projet Python initialisé dans le dossier '$PROJECT_NAME'"
