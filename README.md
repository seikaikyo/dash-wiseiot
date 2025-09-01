# WISE-IoT Grafana v12 整合專案

## 專案目標 ✅ 已完成
將 dash-grafana 升級至 v12 版本並整合 SSO 認證，同時保持現有環境不受影響。

## 核心配置文件

### Kubernetes 配置
- `grafana-config-nodeport.yaml` - **最終 Grafana v12 配置**（含 SSO 整合）
- `grafana-datasources-correct-influxdb.yaml` - **InfluxDB 資料源配置**
- `dash-wiseiot-ingress.yaml` - **Kubernetes Ingress 規則**

### Nginx 配置
- `dash-wiseiot.conf` - **主機 Nginx 反向代理配置**（HTTP/HTTPS 支援）

### 儀表板
- `oven1_dashboard_v12_corrected_full.json` - **🆕 v12 完整版** - 包含所有 15 個面板，使用正確資料源 ✅
- `oven1_dashboard_v12_complete_full.json` - 舊版本（備用）
- `oven1_dashboard_v12_working.json` - **基礎版** - 基於實際可用資料（5 個面板）
- `oven1_dashboard_v3.json` - 原始 v3 版本（參考用）

### 備份和文檔
- `backup/` - 原始配置文件備份
- `平台部署檢查報告_鈺祥企業股份有限公司.pdf` - 平台部署報告

## 🎉 部署完成狀態

### ✅ 全部完成
- [x] **Grafana v12 部署** - 使用最新版本，品牌設定匹配 v3
- [x] **SSO 整合** - EnSaaS 單一登入
- [x] **域名設定** - dash-wiseiot-ensaas.yesiang.com
- [x] **SSL 支援** - HTTP/HTTPS 都可用
- [x] **資料源修復** - 指向正確的 InfluxDB 且有實際資料
- [x] **儀表板修復** - v12 完整版 15 個面板正常顯示資料
- [x] **反向代理** - Nginx → K8s Ingress → Grafana

## 🌐 訪問方式

### 主要域名（推薦）
- **HTTP**: `http://dash-wiseiot-ensaas.yesiang.com`
- **HTTPS**: `https://dash-wiseiot-ensaas.yesiang.com`

### 備用訪問
- **NodePort**: `http://10.6.50.200:30300`

### 登入方式
- **SSO**: EnSaaS 單一登入（推薦）
- **本機帳號**: admin/grafana123

## 🏗️ 系統架構

```
使用者
    ↓
dash-wiseiot-ensaas.yesiang.com (DNS A 記錄)
    ↓
10.6.50.200:80/443 (主機 Nginx)
    ↓
10.224.0.101 (K8s Ingress Controller)  
    ↓
dash-grafana Service (監控命名空間)
    ↓  
Grafana v12 Pod + InfluxDB
```

## 📋 使用說明
1. **瀏覽器開啟**: https://dash-wiseiot-ensaas.yesiang.com
2. **選擇 SSO 登入** 或使用 admin 帳號
3. **導入儀表板**: 
   - **完整監控** 🌟：使用 `oven1_dashboard_v12_complete_full.json` (27個面板)
   - **基礎監控**：使用 `oven1_dashboard_v12_working.json` (5個面板)
4. **開始監控**: 查看溫度、壓力、電力、馬達等完整資料

### 📊 面板功能對比
| 儀表板版本 | 面板數量 | 涵蓋功能 |
|-----------|---------|----------|
| **完整版 v12** | **27 個** | 溫度指標、輔控溫度、出風溫度、節能箱、馬達狀態、壓力監控、電力監控、馬達頻率、設備狀態 |
| 基礎版 v12 | 5 個 | 設備狀態、PLC狀態、智能電表狀態 |
| 原始 v3 | 27 個 | 完整工業監控功能 |

---
**專案狀態**: ✅ 完全成功  
**完成日期**: 2025-08-07  
**版本**: v12 (最新)