# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a WISE-IoT Grafana v12 integration project for industrial monitoring dashboard. The project provides:
- Grafana v12 dashboard with SSO authentication
- Industrial monitoring for ovens with temperature, pressure, power, and motor metrics
- Kubernetes deployment with Nginx reverse proxy
- Multiple dashboard versions for different monitoring needs

## Commands

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
User → DNS (dash-wiseiot-ensaas.yesiang.com) 
     → Host Nginx (10.6.50.200:80/443)
     → K8s Ingress Controller (10.224.0.101)
     → dash-grafana Service (monitoring namespace)
     → Grafana v12 Pod + InfluxDB
```

### Key Components
- **Grafana v12**: Main dashboard application with SSO integration
- **InfluxDB**: Time-series database for IoT metrics
- **EnSaaS SSO**: Single sign-on authentication system
- **Nginx Reverse Proxy**: SSL termination and routing
- **Kubernetes Ingress**: Internal cluster routing

## File Structure

### Configuration Files
- `grafana-config-nodeport.yaml`: Complete Grafana v12 configuration with SSO
- `dash-wiseiot-ingress.yaml`: Kubernetes Ingress rules
- `dash-wiseiot.conf`: Nginx reverse proxy configuration

### Dashboard Files
- `oven1_dashboard_v12_corrected_full.json`: **Primary dashboard** - 27 panels, full industrial monitoring
- `oven1_dashboard_v12_working.json`: Basic dashboard - 5 panels, device status only
- `oven1_dashboard_v3.json`: Legacy reference dashboard

### Access Information
- **Production URL**: https://dash-wiseiot-ensaas.yesiang.com
- **NodePort Backup**: http://10.6.50.200:30300
- **SSO Login**: EnSaaS single sign-on (recommended)
- **Local Login**: admin/grafana123

## Development Workflow

1. **Configuration Changes**: Edit YAML files and apply with kubectl
2. **Dashboard Updates**: Import JSON files through Grafana UI
3. **SSL Changes**: Update certificates in Nginx configuration
4. **Testing**: Access via both HTTP/HTTPS to verify routing

## Data Sources

The project uses InfluxDB datasource with UID `IoTEdge-IoTHub-SimpleJson` for industrial IoT metrics including:
- Temperature monitoring (oven, auxiliary, exhaust)
- Pressure monitoring
- Power consumption
- Motor status and frequency
- Equipment operational status

## Important Notes

- This is a production monitoring system for Yesiang Enterprise
- The complete dashboard requires the InfluxDB datasource to be properly configured
- SSL certificates are managed externally and referenced in Nginx config
- SSO integration requires proper EnSaaS service connectivity