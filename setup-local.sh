#!/bin/bash
#
# Microsoft Rewards - Setup Local (2 contas em paralelo)
#
set -e

# ============================================
# CONFIGURAÇÕES - EDITE AQUI
# ============================================
ACCOUNTS='[
    {
        "email": "CONTA1@gmail.com",
        "password": "SENHA1",
        "totpSecret": "",
        "recoveryEmail": "",
        "geoLocale": "auto",
        "langCode": "pt",
        "proxy": { "proxyAxios": false, "url": "", "port": 0, "username": "", "password": "" },
        "saveFingerprint": { "mobile": false, "desktop": false }
    },
    {
        "email": "CONTA2@gmail.com",
        "password": "SENHA2",
        "totpSecret": "",
        "recoveryEmail": "",
        "geoLocale": "auto",
        "langCode": "pt",
        "proxy": { "proxyAxios": false, "url": "", "port": 0, "username": "", "password": "" },
        "saveFingerprint": { "mobile": false, "desktop": false }
    }
]'

CONFIG='{
    "baseURL": "https://rewards.bing.com",
    "sessionPath": "sessions",
    "headless": true,
    "clusters": 2,
    "errorDiagnostics": false,
    "workers": {
        "doDailySet": true,
        "doSpecialPromotions": true,
        "doMorePromotions": true,
        "doPunchCards": true,
        "doAppPromotions": true,
        "doDesktopSearch": true,
        "doMobileSearch": true,
        "doDailyCheckIn": true,
        "doReadToEarn": true
    },
    "searchOnBingLocalQueries": false,
    "globalTimeout": "30sec",
    "searchSettings": {
        "scrollRandomResults": false,
        "clickRandomResults": false,
        "parallelSearching": true,
        "queryEngines": ["google", "wikipedia", "reddit", "local"],
        "searchResultVisitTime": "10sec",
        "searchDelay": { "min": "30sec", "max": "1min" },
        "readDelay": { "min": "30sec", "max": "1min" }
    },
    "debugLogs": false,
    "consoleLogFilter": { "enabled": false, "mode": "whitelist", "levels": ["error", "warn"], "keywords": ["starting account"], "regexPatterns": [] },
    "proxy": { "queryEngine": true },
    "webhook": {
        "telegram": {
            "enabled": true,
            "botToken": "SEU_BOT_TOKEN",
            "chatId": "SEU_CHAT_ID",
            "parseMode": "HTML",
            "silent": false
        },
        "ntfy": { "enabled": false, "url": "", "topic": "", "token": "", "title": "", "tags": [], "priority": 3 },
        "webhookLogFilter": {
            "enabled": true,
            "mode": "whitelist",
            "levels": ["error"],
            "keywords": ["starting account", "collected", "ACCOUNT-END", "ACCOUNT-ERROR", "RUN-END"],
            "regexPatterns": []
        }
    }
}'

INSTALL_DIR="$HOME/ms-rewards"
AUTO_SHUTDOWN=true
SHUTDOWN_DELAY=2
SCHEDULE_TIME="07:00"

detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    else
        DISTRO="unknown"
    fi
    echo "Sistema: $DISTRO"
}

install_deps() {
    echo "Instalando dependências..."
    case $DISTRO in
        arch|cachyos|manjaro|endeavouros)
            sudo pacman -S --needed --noconfirm nodejs npm git jq ;;
        ubuntu|debian|linuxmint|pop)
            sudo apt update && sudo apt install -y nodejs npm git jq ;;
        fedora|rhel|centos)
            sudo dnf install -y nodejs npm git jq ;;
        *)
            echo "Instale manualmente: nodejs npm git jq" ;;
    esac
    NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)
    [ -z "$NODE_VERSION" ] || [ "$NODE_VERSION" -lt 20 ] && echo "Node.js 20+ necessario" && exit 1
}

setup_project() {
    echo "Configurando projeto..."
    [ -d "$INSTALL_DIR" ] && rm -rf "$INSTALL_DIR"
    git clone https://github.com/Chrispsz/ms-rewards-telegram.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    npm install
    npm run build
    npx patchright install chromium
    mkdir -p dist/browser/sessions
    echo "$ACCOUNTS" | jq '.' > src/accounts.json
    cp src/accounts.json dist/
    echo "$CONFIG" | jq '.' > src/config.json
    cp src/config.json dist/
}

create_systemd() {
    cat > /tmp/ms-rewards.service << EOF
[Unit]
Description=Microsoft Rewards Script
After=network.target
[Service]
Type=oneshot
ExecStart=/usr/bin/npm start
WorkingDirectory=$INSTALL_DIR
User=$USER
TimeoutStartSec=3600
[Install]
WantedBy=multi-user.target
EOF
    cat > /tmp/ms-rewards.timer << EOF
[Unit]
Description=Microsoft Rewards Daily Timer
[Timer]
OnCalendar=*-*-* $SCHEDULE_TIME
Persistent=true
[Install]
WantedBy=timers.target
EOF
    sudo mv /tmp/ms-rewards.service /etc/systemd/system/
    sudo mv /tmp/ms-rewards.timer /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable ms-rewards.timer
    echo "Timer configurado para $SCHEDULE_TIME"
}

create_run_script() {
    cat > "$INSTALL_DIR/run.sh" << 'EOF'
#!/bin/bash
cd "$HOME/ms-rewards"
mkdir -p ~/rewards-logs
LOG=~/rewards-logs/rewards-$(date +%Y-%m-%d).log
npm start 2>&1 | tee "$LOG"
EOF
    chmod +x "$INSTALL_DIR/run.sh"
}

show_summary() {
    echo ""
    echo "Instalacao concluida!"
    echo "Diretorio: $INSTALL_DIR"
    echo "Clusters: 2 (paralelo)"
    echo ""
    echo "Comandos:"
    echo "  Rodar: $INSTALL_DIR/run.sh"
    echo "  Logs: tail -f ~/rewards-logs/*.log"
    echo "  Timer: systemctl status ms-rewards.timer"
}

main() {
    echo "Microsoft Rewards - Setup Local"
    detect_system
    install_deps
    setup_project
    create_run_script
    create_systemd
    show_summary
}

main "$@"
