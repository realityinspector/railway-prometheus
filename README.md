---
title: Prometheus
description: A minimal example of the Prometheus timeseries database
tags:
  - prometheus
  - observability
---

# Railway Prometheus with Test Data Management

This project provides a Prometheus instance with test data management capabilities for monitoring and testing purposes.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file based on the template:
```bash
cp .env.example .env
```

3. Configure your environment variables in `.env`:
```env
DATABASE_ORCHESTRATOR_URL=http://your-orchestrator-url
MAIN_FASTAPI_URL=http://your-fastapi-url
ENVIRONMENT=test  # or 'live' for production
PORT=9090
```

## Usage

### Test Data Management

The following commands are available for managing test data:

```bash
# Seed initial test data
npm run seed

# Update test data with new random values
npm run update

# Check test data status
npm run status

# Remove test data
npm run rollback
```

### Environment Variables

Required environment variables:
- `DATABASE_ORCHESTRATOR_URL`: URL of the database orchestrator service
- `MAIN_FASTAPI_URL`: URL of the FastAPI service

Optional environment variables:
- `ENVIRONMENT`: Set to 'test' or 'live' (defaults to 'live')
- `PORT`: Port for Prometheus (defaults to 9090)

## Test Data Structure

The test data includes:
- Test users with email addresses like 'test1@example.com'
- Metrics for each test user:
  - CPU usage
  - Memory usage
  - Disk usage
  - Network I/O
  - Error rate

## Prometheus Configuration

The Prometheus configuration includes:
- Self-monitoring
- Demo application metrics
- FastAPI metrics
- Test data metrics (when in test environment)

## Development

To modify the test data structure or add new metrics:
1. Update the SQL queries in `test_data_manager.js`
2. Add new metric types in the seed and update functions
3. Update the rollback function to handle new data types

# Prometheus Example

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/KmJatA?referralCode=9kQOPq)

Deploy Prometheus on Railway with one click. Pre-configured to self-monitor the Prometheus service and [a well-known demo-application](http://demo.do.prometheus.io:9090)

## Authentication
update your web.yml 