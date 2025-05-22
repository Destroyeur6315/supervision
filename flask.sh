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
EOL

# Installer les dépendances
pip install -r requirements.txt

# Créer un fichier app.py avec un peu de code
cat <<EOF > app.py
import time # Module pour gérer le temps, notamment pour simuler des
# Importer les modules OpenTelemetry nécessaires
from opentelemetry import trace # Pour créer et gérer les traces
from opentelemetry.sdk.resources import SERVICE_NAME, Resource # Pour définir le nom du service
from opentelemetry.sdk.trace import TracerProvider # Fournisseur de trace
from opentelemetry.sdk.trace.export import SimpleSpanProcessor # Pour exporter les spans
from opentelemetry.exporter.jaeger.thrift import JaegerExporter # Exporteur

# Configuration du fournisseur de trace avec le nom du service
trace.set_tracer_provider(
    TracerProvider(resource=Resource.create({SERVICE_NAME:
        "hello-trace-app"})) # Nom visible dans Jaeger
)
# Création d’un tracer spécifique à ce module
tracer = trace.get_tracer(__name__)
# Configuration de l'exporteur Jaeger (vers l'agent Jaeger local sur le port 6831)
jaeger_exporter = JaegerExporter(
    agent_host_name="localhost", # Adresse de Jaeger (localhost ici)
    agent_port=6831, # Port UDP par défaut utilisé par Jaeger
)
# Ajout d’un processeur de spans pour envoyer immédiatement les traces à
trace.get_tracer_provider().add_span_processor(
    SimpleSpanProcessor(jaeger_exporter) # Envoie les traces une par une dès
)
# Exemple de création d’un span (bloc de code mesuré dans la trace)
with tracer.start_as_current_span("say_hello") as span:
    print("Hello depuis OpenTelemetry + Python") # Affichage console
    span.set_attribute("exemple.key", "valeur") # Ajout d’un attribut à la
    span.add_event("Lancement de l'opération") # Ajout d’un événement dans
    time.sleep(1) # Pause pour simuler une opération d’une seconde
# ⏱ Pause supplémentaire pour s'assurer que l’exporteur a le temps d’envoyer

time.sleep(2)
EOF

# Créer un fichier app.py avec un peu de code
cat <<EOF > app_log.py
import time # Pour simuler le temps de traitement
import logging # Pour la journalisation (logs)
# Import des modules OpenTelemetry
from opentelemetry import trace
from opentelemetry.sdk.resources import SERVICE_NAME, Resource # Pour nommer
from opentelemetry.sdk.trace import TracerProvider # Fournisseur de trace
from opentelemetry.sdk.trace.export import BatchSpanProcessor # Pour
from opentelemetry.exporter.jaeger.thrift import JaegerExporter # Exporteur
from opentelemetry.instrumentation.logging import LoggingInstrumentor #

# Configuration de la journalisation standard Python
logging.basicConfig(level=logging.INFO) # Niveau d'affichage : INFO ou
logger = logging.getLogger(__name__) # Création d’un logger pour ce module
# 🔌 Instrumentation : lie les logs aux traces OpenTelemetry (trace_id,

LoggingInstrumentor().instrument(set_logging_format=True)
# Configuration du fournisseur de trace avec nom du service
trace.set_tracer_provider(
    TracerProvider(
    resource=Resource.create({SERVICE_NAME: "otel-log-demo"}) # Nom du
)
)
# Création d’un tracer
tracer = trace.get_tracer(__name__)
# Configuration d’un processeur de spans par lot avec export vers Jaeger
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor( # Envoie les traces de manière groupée (plus
        JaegerExporter(
            agent_host_name="localhost", # Adresse de l'agent Jaeger local
            agent_port=6831, # Port par défaut
        )
    )
)
# Début d’une trace nommée "traitement"
with tracer.start_as_current_span("traitement") as span:
    logger.info(" Début du traitement") # Log d'information, lié au trace_id
    span.set_attribute("traitement.status", "démarrage") # Ajout d’attributs
    time.sleep(1) # Pause pour simuler un traitement
    logger.warning(" Une étape a pris un peu de temps") # Log
    time.sleep(1) # Autre pause
    logger.info(" Traitement terminé") # Log final
EOF

echo "✅ Projet Python initialisé dans le dossier '$PROJECT_NAME'"
