FROM node:18-alpine as builder

# Set up the app directory for building
WORKDIR /app
COPY package*.json ./
COPY test_data_manager.js ./
COPY database_orchestrator.js ./
COPY manage_test_data.js ./

# Install dependencies
RUN npm install

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
COPY <<EOF /start.sh
#!/bin/sh
# Start chronyd in the background if it exists
if command -v chronyd >/dev/null 2>&1; then
    chronyd
fi

# Check if we're running a test data command
if [ "$1" = "seed" ]; then
    node /app/manage_test_data.js seed
    exit $?
elif [ "$1" = "update" ]; then
    node /app/manage_test_data.js update
    exit $?
elif [ "$1" = "rollback" ]; then
    node /app/manage_test_data.js rollback
    exit $?
elif [ "$1" = "status" ]; then
    node /app/manage_test_data.js status
    exit $?
fi

# Start Prometheus by default
exec /bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time=365d \
  --web.console.libraries=/usr/share/prometheus/console_libraries \
  --web.console.templates=/usr/share/prometheus/consoles \
  --web.external-url=http://localhost:9090 \
  --web.config.file=/etc/prometheus/web/web.yml \
  --log.level=info
EOF

RUN chmod +x /start.sh

# Set the entrypoint to our startup script
ENTRYPOINT ["/start.sh"]
 
