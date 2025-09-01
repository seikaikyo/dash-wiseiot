# WISE-IoT Grafana v12 一鍵安裝系統

## 專案說明
提供 Grafana v12 工業監控儀表板的完整自動化部署解決方案，支援自定義網域和認證設定。

## 🚀 快速開始

### 一鍵安裝
```bash
chmod +x install.sh
./install.sh
```

安裝腳本會詢問：
- **主網域** (例如: company.com)
- **子網域前綴** (預設: dash-wiseiot)
- **Grafana 管理員帳號** (預設: admin)
- **Grafana 管理員密碼** (預設: grafana123)
- **SSL 證書路徑**

## 📁 核心文件

### 配置文件
- `install.sh` - **一鍵安裝腳本**
- `grafana-config-nodeport.yaml` - Grafana v12 Kubernetes 配置
- `dash-wiseiot-ingress.yaml` - Kubernetes Ingress 規則
- `dash-wiseiot.conf` - Nginx 反向代理配置範本

### 備份文件
- `backup/` - 原始配置文件備份

## 🏗️ 系統架構

```
使用者
    ↓
自定義網域 (DNS A 記錄)
    ↓
主機 Nginx (80/443)
    ↓
K8s Ingress Controller
    ↓
dash-grafana Service (monitoring namespace)
    ↓  
Grafana v12 Pod + InfluxDB
```

## 📋 部署需求

### 系統要求
- Kubernetes 集群 (已安裝 kubectl)
- Nginx (已安裝並可管理)
- SSL 證書 (選用，支援 HTTPS)

### MIS 需要配置
安裝完成後，腳本會生成：
- `dns-setup-guide.txt` - DNS A 記錄設定指導
- `mis-checklist.md` - 部署確認清單

## 🔧 手動部署 (選用)

如需手動部署，請依序執行：

1. **創建 namespace**
```bash
kubectl create namespace monitoring
```

2. **部署 Grafana**
```bash
kubectl apply -f grafana-config-nodeport.yaml
kubectl apply -f dash-wiseiot-ingress.yaml
```

3. **配置 Nginx**
```bash
cp dash-wiseiot.conf /etc/nginx/conf.d/
nginx -t && nginx -s reload
```

## 📊 監控功能

- **溫度監控**: 爐體、輔助、排氣溫度
- **壓力監控**: 系統壓力狀態
- **電力監控**: 功耗和電力狀態  
- **馬達監控**: 馬達狀態和頻率
- **設備狀態**: PLC 和設備運行狀態

## 🎯 訪問方式

安裝完成後可透過以下方式訪問：
- **主要網址**: https://[您的網域]
- **備用網址**: http://[主機IP]:30300
- **管理帳號**: [您設定的帳號]/[您設定的密碼]

---
**版本**: v12 (最新)  
**支援**: Kubernetes + Nginx + Grafana v12