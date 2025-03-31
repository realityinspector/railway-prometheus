#!/bin/sh

# Create the query log file in /tmp with correct permissions
touch /tmp/queries.active
chmod 666 /tmp/queries.active

# Start Prometheus with the query log file in /tmp
exec /bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time=365d \
  --web.console.libraries=/usr/share/prometheus/console_libraries \
  --web.console.templates=/usr/share/prometheus/consoles \
  --web.external-url=http://localhost:9090 \
  --web.config.file=/etc/prometheus/web/web.yml \
  --query.active-query-log-file=/tmp/queries.active \
  --log.level=info 