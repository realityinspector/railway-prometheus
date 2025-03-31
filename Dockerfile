# Stage 1: Generate password hash
FROM httpd:2.4-alpine AS hash-generator
ARG ADMIN_PASSWORD
RUN if [ -n "$ADMIN_PASSWORD" ]; then \
    echo "admin:$(htpasswd -nbB "" "$ADMIN_PASSWORD" | cut -d ":" -f 2)" > /tmp/htpasswd; \
    fi

# Stage 2: Main Prometheus image
FROM prom/prometheus

# Switch to root for file operations
USER root

# Copy the Prometheus configuration file
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Create web config file with basic auth
RUN mkdir -p /etc/prometheus/web
COPY web.yml /etc/prometheus/web/web.yml

# Copy the generated password hash if it exists
COPY --from=hash-generator /tmp/htpasswd /etc/prometheus/web/htpasswd

# Copy and set up the entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# expose the Prometheus server port
EXPOSE 9090

# Switch back to the nobody user for better security
USER nobody

# Set the entrypoint to our script
ENTRYPOINT ["/docker-entrypoint.sh"]
