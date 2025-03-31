# Stage 1: Generate password hash
FROM httpd:2.4-alpine AS hash-generator
ARG ADMIN_PASSWORD
RUN if [ -n "$ADMIN_PASSWORD" ]; then \
    echo "admin:$(htpasswd -nbB "" "$ADMIN_PASSWORD" | cut -d ":" -f 2)" > /tmp/htpasswd; \
    fi

# Stage 2: Main Prometheus image
FROM prom/prometheus

# Copy the Prometheus configuration file
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Create web config file with basic auth
RUN mkdir -p /etc/prometheus/web
COPY web.yml /etc/prometheus/web/web.yml

# Copy the generated password hash if it exists
COPY --from=hash-generator /tmp/htpasswd /etc/prometheus/web/htpasswd

# Create a script to start Prometheus
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
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
 
