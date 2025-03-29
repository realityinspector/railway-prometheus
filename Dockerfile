FROM node:18-alpine as builder

# Set up the app directory for building
WORKDIR /app
COPY package*.json ./
RUN npm install

# Copy application files
COPY test_data_manager.js ./
COPY database_orchestrator.js ./
COPY manage_test_data.js ./

FROM prom/prometheus

# Copy node and npm from node image
COPY --from=node:18-alpine /usr/local/bin/node /usr/local/bin/
COPY --from=node:18-alpine /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Copy our app from builder
COPY --from=builder /app /app

# copy the Prometheus configuration file
COPY prometheus.yml /etc/prometheus/prometheus.yml

# create web config file with basic auth
RUN mkdir -p /etc/prometheus/web
COPY web.yml /etc/prometheus/web/web.yml

# Install chrony for time sync
USER root
RUN mkdir -p /etc/chrony && \
    echo "pool pool.ntp.org iburst" > /etc/chrony/chrony.conf && \
    echo "makestep 1.0 3" >> /etc/chrony/chrony.conf && \
    echo "rtcsync" >> /etc/chrony/chrony.conf

# expose the Prometheus server port
EXPOSE 9090

# Create startup script
RUN echo '#!/bin/sh' > /start.sh && \
    echo '# Start chronyd in the background if it exists' >> /start.sh && \
    echo 'if command -v chronyd >/dev/null 2>&1; then' >> /start.sh && \
    echo '    chronyd' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Check if we are running a test data command' >> /start.sh && \
    echo 'if [ "$1" = "seed" ]; then' >> /start.sh && \
    echo '    node /app/manage_test_data.js seed' >> /start.sh && \
    echo '    exit $?' >> /start.sh && \
    echo 'elif [ "$1" = "update" ]; then' >> /start.sh && \
    echo '    node /app/manage_test_data.js update' >> /start.sh && \
    echo '    exit $?' >> /start.sh && \
    echo 'elif [ "$1" = "rollback" ]; then' >> /start.sh && \
    echo '    node /app/manage_test_data.js rollback' >> /start.sh && \
    echo '    exit $?' >> /start.sh && \
    echo 'elif [ "$1" = "status" ]; then' >> /start.sh && \
    echo '    node /app/manage_test_data.js status' >> /start.sh && \
    echo '    exit $?' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Prometheus by default' >> /start.sh && \
    echo 'exec /bin/prometheus \\' >> /start.sh && \
    echo '  --config.file=/etc/prometheus/prometheus.yml \\' >> /start.sh && \
    echo '  --storage.tsdb.path=/prometheus \\' >> /start.sh && \
    echo '  --storage.tsdb.retention.time=365d \\' >> /start.sh && \
    echo '  --web.console.libraries=/usr/share/prometheus/console_libraries \\' >> /start.sh && \
    echo '  --web.console.templates=/usr/share/prometheus/consoles \\' >> /start.sh && \
    echo '  --web.external-url=http://localhost:9090 \\' >> /start.sh && \
    echo '  --web.config.file=/etc/prometheus/web/web.yml \\' >> /start.sh && \
    echo '  --log.level=info' >> /start.sh && \
    chmod +x /start.sh

# Set the entrypoint to our startup script
ENTRYPOINT ["/start.sh"]
 
