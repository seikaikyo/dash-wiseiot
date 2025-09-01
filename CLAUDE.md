# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a WISE-IoT Grafana v12 integration project for industrial monitoring dashboard. The project provides:
- Grafana v12 dashboard with local authentication
- Industrial monitoring for ovens with temperature, pressure, power, and motor metrics
- Kubernetes deployment with Nginx reverse proxy
- One-click installation script with customizable domain configuration

## Commands

### One-Click Installation
```bash
chmod +x install.sh
./install.sh
```

### Kubernetes Deployment
```bash
# Apply Grafana configuration
kubectl apply -f grafana-config-nodeport.yaml

# Apply Ingress rules
kubectl apply -f dash-wiseiot-ingress.yaml

# Check deployment status
kubectl get pods -n monitoring
kubectl get services -n monitoring
kubectl get ingress -n monitoring
```

### Nginx Configuration
```bash
# Test Nginx configuration
nginx -t

# Reload Nginx configuration
nginx -s reload

# Apply the reverse proxy config
cp dash-wiseiot.conf /etc/nginx/conf.d/
```

## Architecture

### System Flow
```
User → DNS (custom domain) 
     → Host Nginx (80/443)
     → K8s Ingress Controller
     → dash-grafana Service (monitoring namespace)
     → Grafana v12 Pod + InfluxDB
```

### Key Components
- **Grafana v12**: Main dashboard application with local authentication
- **InfluxDB**: Time-series database for IoT metrics
- **Nginx Reverse Proxy**: SSL termination and routing
- **Kubernetes Ingress**: Internal cluster routing

## File Structure

### Configuration Files
- `install.sh`: One-click installation script with interactive configuration
- `grafana-config-nodeport.yaml`: Grafana v12 Kubernetes configuration (no SSO)
- `dash-wiseiot-ingress.yaml`: Kubernetes Ingress rules template
- `dash-wiseiot.conf`: Nginx reverse proxy configuration template

### Generated Files
The install script generates:
- `dns-setup-guide.txt`: DNS A record setup guide for MIS
- `mis-checklist.md`: Deployment verification checklist
- Dynamic configuration files based on user input

## Installation Process

1. **Interactive Configuration**: User specifies domain, subdomain, and credentials
2. **Environment Check**: Validates kubectl, nginx, curl availability
3. **Dynamic Configuration**: Generates configs based on user input
4. **Kubernetes Deployment**: Deploys Grafana v12 with custom settings
5. **Nginx Setup**: Configures reverse proxy with optional SSL
6. **Health Verification**: Tests connectivity and service availability
7. **MIS Documentation**: Generates setup guides for network administrators

## Data Sources

The project uses InfluxDB datasource for industrial IoT metrics including:
- Temperature monitoring (oven, auxiliary, exhaust)
- Pressure monitoring
- Power consumption
- Motor status and frequency
- Equipment operational status

## Important Notes

- Uses local Grafana authentication (no external SSO dependency)
- SSL certificates are configurable during installation
- Supports both HTTP and HTTPS access
- All sensitive data is excluded via .gitignore
- Install script generates MIS documentation automatically