#!/bin/bash

# WISE-IoT Grafana v12 一鍵安裝腳本
# 作者: seikaikyo
# 版本: 1.0

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日誌函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 清理函數
cleanup() {
    log_warning "安裝被中斷，正在清理..."
    # 可以在這裡添加清理邏輯
}

trap cleanup EXIT

echo "========================================"
echo "    WISE-IoT Grafana v12 一鍵安裝"
echo "========================================"
echo

# 步驟 1: 環境檢查
log_info "檢查系統環境..."

if ! command -v kubectl &> /dev/null; then
    log_error "kubectl 未安裝或不在 PATH 中"
    exit 1
fi

if ! command -v nginx &> /dev/null; then
    log_error "nginx 未安裝或不在 PATH 中"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    log_error "curl 未安裝或不在 PATH 中"
    exit 1
fi

# 測試 kubectl 連接
if ! kubectl cluster-info &> /dev/null; then
    log_error "無法連接到 Kubernetes 集群"
    exit 1
fi

log_success "環境檢查通過"

# 步驟 2: 交互式配置
echo
log_info "配置安裝參數..."

# 網域設定
read -p "請輸入主網域 (例如: example.com): " MAIN_DOMAIN
while [[ -z "$MAIN_DOMAIN" ]]; do
    log_error "主網域不能為空"
    read -p "請輸入主網域 (例如: example.com): " MAIN_DOMAIN
done

read -p "請輸入子網域前綴 (預設: dash-wiseiot): " SUBDOMAIN_PREFIX
SUBDOMAIN_PREFIX=${SUBDOMAIN_PREFIX:-dash-wiseiot}
FULL_DOMAIN="${SUBDOMAIN_PREFIX}.${MAIN_DOMAIN}"

echo
log_info "完整網域將是: ${FULL_DOMAIN}"

# Grafana 帳號設定
echo
read -p "Grafana 管理員用戶名 (預設: admin): " GRAFANA_USER
GRAFANA_USER=${GRAFANA_USER:-admin}

read -p "Grafana 管理員密碼 (預設: grafana123): " GRAFANA_PASSWORD
GRAFANA_PASSWORD=${GRAFANA_PASSWORD:-grafana123}

# SSL 證書路徑確認
read -p "SSL 證書路徑 (預設: /etc/nginx/conf.d/fullchain.pem): " SSL_CERT_PATH
SSL_CERT_PATH=${SSL_CERT_PATH:-/etc/nginx/conf.d/fullchain.pem}

read -p "SSL 私鑰路徑 (預設: /etc/nginx/conf.d/private.pem): " SSL_KEY_PATH
SSL_KEY_PATH=${SSL_KEY_PATH:-/etc/nginx/conf.d/private.pem}

echo
log_info "SSL 證書路徑: ${SSL_CERT_PATH}"
log_info "SSL 私鑰路徑: ${SSL_KEY_PATH}"

if [[ ! -f "$SSL_CERT_PATH" ]] || [[ ! -f "$SSL_KEY_PATH" ]]; then
    log_warning "SSL 證書文件不存在，將僅配置 HTTP 訪問"
    USE_SSL=false
else
    USE_SSL=true
    log_success "SSL 證書文件確認存在"
fi

# 確認安裝
echo
echo "========================================"
echo "安裝配置確認:"
echo "  主網域: ${MAIN_DOMAIN}"
echo "  完整網域: ${FULL_DOMAIN}"
echo "  Grafana 用戶: ${GRAFANA_USER}"
echo "  Grafana 密碼: ${GRAFANA_PASSWORD}"
echo "  SSL 支援: ${USE_SSL}"
echo "========================================"
echo

read -p "確認開始安裝? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    log_info "安裝已取消"
    exit 0
fi

# 步驟 3: 生成 MIS 設定文件
log_info "生成 MIS 設定文件..."

cat > dns-setup-guide.txt << EOF
=== DNS A 記錄設定要求 ===

網域名稱: ${FULL_DOMAIN}
目標 IP: 10.6.50.200
TTL: 300 (建議)
記錄類型: A

設定完成後測試指令:
nslookup ${FULL_DOMAIN}

預期結果:
Name: ${FULL_DOMAIN}
Address: 10.6.50.200

注意事項:
- 請確保 DNS 記錄生效 (通常需要 5-15 分鐘)
- 建議同時設定 IPv4 A 記錄
- 如有 CDN 或防火牆，請確認允許 80, 443 端口流量
EOF

cat > mis-checklist.md << EOF
# MIS 部署確認清單

## DNS 設定
- [ ] DNS A 記錄已設定: ${FULL_DOMAIN} → 10.6.50.200
- [ ] DNS 記錄已生效 (使用 nslookup 測試)

## 網路連通性測試
- [ ] HTTP 訪問測試: \`curl -I http://${FULL_DOMAIN}\`
- [ ] HTTPS 訪問測試: \`curl -I https://${FULL_DOMAIN}\`
- [ ] 防火牆規則確認 (80, 443 端口開放)

## SSL 證書
- [ ] SSL 證書有效期確認
- [ ] 證書路徑正確: ${SSL_CERT_PATH}
- [ ] 私鑰路徑正確: ${SSL_KEY_PATH}

## 服務驗證
- [ ] Grafana 登入正常: ${GRAFANA_USER}/${GRAFANA_PASSWORD}
- [ ] 儀表板顯示正常
- [ ] InfluxDB 資料源連接正常

## 訪問資訊
- **主要網址**: https://${FULL_DOMAIN}
- **備用網址**: http://10.6.50.200:30300
- **管理帳號**: ${GRAFANA_USER}
- **管理密碼**: ${GRAFANA_PASSWORD}

## 支援聯絡
如有問題請聯絡系統管理員或參考部署文檔。
EOF

log_success "MIS 設定文件已生成"
log_info "  - dns-setup-guide.txt"
log_info "  - mis-checklist.md"

# 步驟 4: 創建 monitoring namespace
log_info "創建 Kubernetes namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 步驟 5: 生成動態 Grafana 配置
log_info "生成 Grafana 配置..."

cat > grafana-config-dynamic.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-config
  namespace: monitoring
data:
  grafana.ini: |
    [server]
    http_port = 3000
    root_url = http://${FULL_DOMAIN}/
    app_title = Dashboard
    
    [security]
    admin_user = ${GRAFANA_USER}
    admin_password = ${GRAFANA_PASSWORD}
    
    [users]
    allow_sign_up = false
    auto_assign_org = true
    auto_assign_org_role = Viewer
    
    [auth]
    disable_login_form = false
    disable_signout_menu = false
    
    [log]
    mode = console
    level = info
    
    [analytics]
    reporting_enabled = false
    check_for_updates = false
    
    [branding]
    app_title = Dashboard
    login_title = Dashboard
    login_subtitle = 
    footer_links = 
    logo_url = https://${FULL_DOMAIN}/public/img/Dashboard-logo.svg
    favicon_url = https://${FULL_DOMAIN}/public/img/Dashboard-logo.svg
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dash-grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dash-grafana
  template:
    metadata:
      labels:
        app: dash-grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:12.0.0
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: "${GRAFANA_USER}"
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "${GRAFANA_PASSWORD}"
        volumeMounts:
        - name: grafana-config
          mountPath: /etc/grafana/grafana.ini
          subPath: grafana.ini
      volumes:
      - name: grafana-config
        configMap:
          name: grafana-config
---
apiVersion: v1
kind: Service
metadata:
  name: dash-grafana
  namespace: monitoring
spec:
  selector:
    app: dash-grafana
  ports:
  - name: grafana
    port: 3000
    targetPort: 3000
    nodePort: 30300
  type: NodePort
EOF

# 步驟 6: 生成動態 Ingress 配置
cat > ingress-dynamic.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dash-wiseiot-ingress
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  ingressClassName: nginx
  rules:
  - host: ${FULL_DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: dash-grafana
            port:
              number: 3000
EOF

# 步驟 7: 生成動態 Nginx 配置
cat > nginx-dynamic.conf << EOF
server {
    listen 80;
    server_name ${FULL_DOMAIN};

    location / {
        proxy_pass http://10.224.0.101;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        # Grafana specific headers
        proxy_set_header Authorization \$http_authorization;
        proxy_pass_header Authorization;
    }
}
EOF

if [[ "$USE_SSL" == "true" ]]; then
cat >> nginx-dynamic.conf << EOF

server {
    listen 443 ssl;
    server_name ${FULL_DOMAIN};

    ssl_certificate ${SSL_CERT_PATH};
    ssl_certificate_key ${SSL_KEY_PATH};
    
    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://10.224.0.101;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect off;
        
        # Grafana specific headers
        proxy_set_header Authorization \$http_authorization;
        proxy_pass_header Authorization;
    }
}
EOF
fi

# 步驟 8: 部署到 Kubernetes
log_info "部署 Grafana 到 Kubernetes..."
kubectl apply -f grafana-config-dynamic.yaml
kubectl apply -f ingress-dynamic.yaml

# 等待 Pod 啟動
log_info "等待 Grafana Pod 啟動..."
kubectl wait --for=condition=ready pod -l app=dash-grafana -n monitoring --timeout=300s

log_success "Kubernetes 部署完成"

# 步驟 9: 配置 Nginx
log_info "配置 Nginx 反向代理..."
sudo cp nginx-dynamic.conf /etc/nginx/conf.d/${SUBDOMAIN_PREFIX}-wiseiot.conf

# 測試 Nginx 配置
if sudo nginx -t; then
    sudo nginx -s reload
    log_success "Nginx 配置完成"
else
    log_error "Nginx 配置測試失敗"
    exit 1
fi

# 步驟 10: 等待服務啟動並導入儀表板
log_info "等待 Grafana 服務啟動..."
sleep 30

# 測試 Grafana API 可用性
GRAFANA_URL="http://10.6.50.200:30300"
for i in {1..10}; do
    if curl -f -s "${GRAFANA_URL}/api/health" > /dev/null; then
        log_success "Grafana 服務已啟動"
        break
    fi
    log_info "等待 Grafana 啟動... (${i}/10)"
    sleep 10
done

# 導入儀表板
if [[ -f "oven1_dashboard_v12_corrected_full.json" ]]; then
    log_info "導入完整版儀表板..."
    
    # 創建 datasource (如果不存在)
    curl -X POST \
        -H "Content-Type: application/json" \
        -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        -d '{
            "name": "IoTEdge-IoTHub-SimpleJson",
            "type": "influxdb",
            "url": "http://influxdb:8086",
            "database": "iotedge",
            "access": "proxy"
        }' \
        "${GRAFANA_URL}/api/datasources" || log_warning "資料源可能已存在"
    
    # 導入儀表板
    DASHBOARD_JSON=$(cat oven1_dashboard_v12_corrected_full.json)
    curl -X POST \
        -H "Content-Type: application/json" \
        -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        -d "{\"dashboard\": ${DASHBOARD_JSON}, \"overwrite\": true}" \
        "${GRAFANA_URL}/api/dashboards/db" && \
        log_success "儀表板導入完成" || \
        log_warning "儀表板導入可能失敗，請手動導入"
fi

# 步驟 11: 清理臨時文件
rm -f grafana-config-dynamic.yaml ingress-dynamic.yaml nginx-dynamic.conf

# 步驟 12: 連通性測試
echo
log_info "執行連通性測試..."

# 測試 HTTP
if curl -f -s "http://${FULL_DOMAIN}" > /dev/null; then
    log_success "HTTP 訪問正常: http://${FULL_DOMAIN}"
else
    log_warning "HTTP 訪問測試失敗，請檢查 DNS 設定"
fi

# 測試 HTTPS (如果啟用 SSL)
if [[ "$USE_SSL" == "true" ]]; then
    if curl -f -s "https://${FULL_DOMAIN}" > /dev/null; then
        log_success "HTTPS 訪問正常: https://${FULL_DOMAIN}"
    else
        log_warning "HTTPS 訪問測試失敗，請檢查 SSL 配置"
    fi
fi

# 完成安裝
echo
echo "========================================"
log_success "WISE-IoT Grafana v12 安裝完成！"
echo "========================================"
echo
echo "📋 請將以下文件提供給 MIS："
echo "   - dns-setup-guide.txt (DNS 設定指導)"
echo "   - mis-checklist.md (部署確認清單)"
echo
echo "🌐 訪問資訊："
echo "   - 主要網址: https://${FULL_DOMAIN}"
echo "   - 備用網址: http://10.6.50.200:30300"
echo "   - 管理帳號: ${GRAFANA_USER}"
echo "   - 管理密碼: ${GRAFANA_PASSWORD}"
echo
echo "📊 儀表板："
echo "   - 完整版監控面板已自動導入"
echo "   - 如需重新導入，使用: oven1_dashboard_v12_corrected_full.json"
echo

trap - EXIT