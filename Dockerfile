FROM prom/prometheus

# Install apache2-utils for htpasswd
USER root
RUN apt-get update && apt-get install -y apache2-utils && rm -rf /var/lib/apt/lists/*

# Copy the Prometheus configuration file
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Create web config file with basic auth
RUN mkdir -p /etc/prometheus/web
COPY web.yml /etc/prometheus/web/web.yml

# Create a script to generate the password hash and start Prometheus
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'if [ -n "$ADMIN_PASSWORD" ]; then' >> /docker-entrypoint.sh && \
    echo '    ADMIN_PASSWORD_HASH=$(htpasswd -nbB "" "$ADMIN_PASSWORD" | cut -d ":" -f 2)' >> /docker-entrypoint.sh && \
    echo '    export ADMIN_PASSWORD_HASH' >> /docker-entrypoint.sh && \
    echo 'fi' >> /docker-entrypoint.sh && \
    echo 'exec /bin/prometheus \' >> /docker-entrypoint.sh && \
    echo '  --config.file=/etc/prometheus/prometheus.yml \' >> /docker-entrypoint.sh && \
    echo '  --storage.tsdb.path=/prometheus \' >> /docker-entrypoint.sh && \
    echo '  --storage.tsdb.retention.time=365d \' >> /docker-entrypoint.sh && \
    echo '  --web.console.libraries=/usr/share/prometheus/console_libraries \' >> /docker-entrypoint.sh && \
    echo '  --web.console.templates=/usr/share/prometheus/consoles \' >> /docker-entrypoint.sh && \
    echo '  --web.external-url=http://localhost:9090 \' >> /docker-entrypoint.sh && \
    echo '  --web.config.file=/etc/prometheus/web/web.yml \' >> /docker-entrypoint.sh && \
    echo '  --log.level=info' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# expose the Prometheus server port
EXPOSE 9090

# Set the entrypoint to our script
ENTRYPOINT ["/docker-entrypoint.sh"]
 
