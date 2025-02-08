#!/bin/sh

# Remplace les variables d'environnement dans les fichiers JS
find /usr/share/nginx/html -type f -name "*.js" -exec sed -i "s|API_URL_PLACEHOLDER|$API_URL|g" {} \;

# Continue avec le démarrage normal de nginx
exec "$@" 