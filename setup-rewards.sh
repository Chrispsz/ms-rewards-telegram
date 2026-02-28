#!/bin/bash
#
# ██████████████████████████████████████████████████████████████████████████████
# █      MICROSOFT REWARDS - INSTALADOR AUTOMÁTICO COM TELEGRAM              █
# ██████████████████████████████████████████████████████████████████████████████

set -e

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURAÇÕES
# ═══════════════════════════════════════════════════════════════════════════════

INSTALL_DIR="$HOME/Microsoft-Rewards-Script"
LOG_FILE="$HOME/rewards-install.log"
REPO_URL="https://github.com/Chrispsz/ms-rewards-telegram.git"

# ═══════════════════════════════════════════════════════════════════════════════
# CORES
# ═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# ═══════════════════════════════════════════════════════════════════════════════
# FUNÇÕES
# ═══════════════════════════════════════════════════════════════════════════════

log() { echo -e "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║       🎁 MICROSOFT REWARDS - INSTALADOR COM TELEGRAM                   ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

ask() { echo -ne "${YELLOW}$1${NC}: "; read -r "$2"; }
ask_default() { echo -ne "${YELLOW}$1${NC} [${WHITE}$3${YELLOW}]: "; read -r "$2"; [ -z "${!2}" ] && eval "$2='$3'"; }
confirm() { echo -ne "${YELLOW}$1${NC} [${WHITE}s/N${YELLOW}]: "; read -r r; [[ "$r" =~ ^[sS](im)?$ ]]; }
check_command() { command -v "$1" &> /dev/null; }

# ═══════════════════════════════════════════════════════════════════════════════
# DETECÇÃO DE SISTEMA
# ═══════════════════════════════════════════════════════════════════════════════

detect_system() {
    print_step "Detectando sistema..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_info "Distribuição: $NAME"
    fi

    if check_command pacman; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
    elif check_command apt; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
    elif check_command dnf; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
    else
        print_error "Gerenciador não suportado"
        exit 1
    fi

    print_success "Gerenciador: $PKG_MANAGER"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDÊNCIAS
# ═══════════════════════════════════════════════════════════════════════════════

install_dependencies() {
    print_step "Instalando dependências..."

    local packages="nodejs npm git jq curl"

    print_info "Instalando: $packages"
    $INSTALL_CMD $packages

    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 20 ]; then
        print_error "Node.js muito antigo (precisa >= 20)"
        exit 1
    fi

    print_success "Node.js $NODE_VERSION ✓"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CLONE
# ═══════════════════════════════════════════════════════════════════════════════

clone_project() {
    print_step "Clonando repositório..."

    if [ -d "$INSTALL_DIR" ]; then
        print_info "Removendo instalação anterior..."
        rm -rf "$INSTALL_DIR"
    fi

    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    print_success "Clonado!"
}

# ═══════════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════════

build_project() {
    print_step "Compilando projeto..."

    npm install
    npm run build

    # Instalar navegador Chromium para o Playwright
    print_info "Instalando navegador Chromium..."
    npx patchright install chromium

    print_success "Build concluído!"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURAÇÃO DE CONTA
# ═══════════════════════════════════════════════════════════════════════════════

configure_account() {
    print_step "Configuração da conta Microsoft"

    echo -e "${WHITE}Por favor, insira os dados da sua conta:${NC}"
    echo ""

    ask "📧 Email" ACCOUNT_EMAIL
    ask "🔑 Senha" ACCOUNT_PASSWORD
    ask "🔐 TOTP Secret (vazio se não usar 2FA)" ACCOUNT_TOTP
    ask "📧 Email de recuperação (opcional)" ACCOUNT_RECOVERY
    ask_default "🌍 País (br, us, pt)" ACCOUNT_GEO "auto"
    ask_default "🌐 Idioma (pt, en)" ACCOUNT_LANG "pt"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURAÇÃO DO TELEGRAM
# ═══════════════════════════════════════════════════════════════════════════════

configure_telegram() {
    print_step "Telegram (Notificações)"

    echo -e "${WHITE}Receber notificações no Telegram?${NC}"
    echo "  • Status de execução"
    echo "  • Pontos ganhos"
    echo "  • Alertas de erro"
    echo ""

    if confirm "Configurar Telegram?"; then
        echo ""
        echo -e "${CYAN}══ Como obter ══${NC}"
        echo "1. Fale com @BotFather no Telegram"
        echo "2. Envie /newbot e siga as instruções"
        echo "3. Fale com @userinfobot para descobrir seu Chat ID"
        echo ""

        ask "🤖 Bot Token" TELEGRAM_TOKEN
        ask "💬 Chat ID" TELEGRAM_CHAT_ID
        TELEGRAM_ENABLED="true"
        print_success "Telegram configurado!"
    else
        TELEGRAM_ENABLED="false"
        TELEGRAM_TOKEN=""
        TELEGRAM_CHAT_ID=""
        print_info "Telegram pulado"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# AGENDAMENTO
# ═══════════════════════════════════════════════════════════════════════════════

configure_schedule() {
    print_step "Agendamento"

    echo -e "${WHITE}Horário de execução diária:${NC}"
    echo "  1) 07:00"
    echo "  2) 08:00"
    echo "  3) 09:00"
    echo "  4) 12:00"
    echo "  5) 18:00"
    echo "  6) 22:00"
    echo "  7) Personalizado"
    echo ""

    ask_default "Opção" SCHEDULE_OPTION "2"

    case $SCHEDULE_OPTION in
        1) CRON_TIME="0 7 * * *" ;;
        2) CRON_TIME="0 8 * * *" ;;
        3) CRON_TIME="0 9 * * *" ;;
        4) CRON_TIME="0 12 * * *" ;;
        5) CRON_TIME="0 18 * * *" ;;
        6) CRON_TIME="0 22 * * *" ;;
        7) ask "Formato cron (min hora * * *)" CRON_TIME ;;
        *) CRON_TIME="0 8 * * *" ;;
    esac

    print_success "Agendamento: $CRON_TIME"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DESLIGAMENTO AUTOMÁTICO
# ═══════════════════════════════════════════════════════════════════════════════

configure_shutdown() {
    print_step "Economia de energia"

    echo -e "${WHITE}Desligar o PC após completar?${NC}"
    echo "  • Economiza energia"
    echo "  • Execução automática"
    echo ""

    if confirm "Desligar automaticamente?"; then
        AUTO_SHUTDOWN="true"
        ask_default "Minutos antes de desligar" SHUTDOWN_DELAY "1"
    else
        AUTO_SHUTDOWN="false"
        SHUTDOWN_DELAY="0"
    fi

    print_success "Configurado!"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIAR ARQUIVOS DE CONFIGURAÇÃO
# ═══════════════════════════════════════════════════════════════════════════════

create_accounts() {
    print_step "Criando accounts.json..."

    cat > "$INSTALL_DIR/src/accounts.json" << EOF
[
    {
        "email": "$ACCOUNT_EMAIL",
        "password": "$ACCOUNT_PASSWORD",
        "totpSecret": "${ACCOUNT_TOTP:-}",
        "recoveryEmail": "${ACCOUNT_RECOVERY:-}",
        "geoLocale": "$ACCOUNT_GEO",
        "langCode": "$ACCOUNT_LANG",
        "proxy": { "proxyAxios": false, "url": "", "port": 0, "username": "", "password": "" },
        "saveFingerprint": { "mobile": false, "desktop": false }
    }
]
EOF

    cp "$INSTALL_DIR/src/accounts.json" "$INSTALL_DIR/dist/accounts.json"

    print_success "Conta configurada!"
}

create_config() {
    print_step "Criando config.json..."

    cat > "$INSTALL_DIR/src/config.json" << EOF
{
    "baseURL": "https://rewards.bing.com",
    "sessionPath": "sessions",
    "headless": true,
    "clusters": 1,
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
    "proxy": { "queryEngine": true },
    "webhook": {
        "telegram": {
            "enabled": $TELEGRAM_ENABLED,
            "botToken": "$TELEGRAM_TOKEN",
            "chatId": "$TELEGRAM_CHAT_ID",
            "parseMode": "HTML",
            "silent": false
        },
        "webhookLogFilter": {
            "enabled": true,
            "mode": "whitelist",
            "levels": ["error"],
            "keywords": ["starting account", "select number", "collected", "ACCOUNT-END", "ACCOUNT-ERROR"],
            "regexPatterns": []
        }
    }
}
EOF

    cp "$INSTALL_DIR/src/config.json" "$INSTALL_DIR/dist/config.json"
    mkdir -p "$INSTALL_DIR/dist/browser/sessions"

    print_success "Config criado!"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIAR SCRIPTS DE EXECUÇÃO
# ═══════════════════════════════════════════════════════════════════════════════

create_scripts() {
    print_step "Criando scripts..."

    cat > "$HOME/rewards-run.sh" << SCRIPT
#!/bin/bash
set -e

INSTALL_DIR="$INSTALL_DIR"
LOG_DIR="\$HOME/rewards-logs"
LOG_FILE="\$LOG_DIR/rewards-\$(date +%Y-%m-%d).log"
LOCK_FILE="/tmp/rewards-running.lock"
AUTO_SHUTDOWN="$AUTO_SHUTDOWN"
SHUTDOWN_DELAY="$SHUTDOWN_DELAY"

log() { echo "[\$(date '+%H:%M:%S')] \$1" | tee -a "\$LOG_FILE"; }

if [ -f "\$LOCK_FILE" ] && ps -p \$(cat "\$LOCK_FILE") > /dev/null 2>&1; then
    log "⚠️ Script já está rodando"
    exit 1
fi
echo \$\$ > "\$LOCK_FILE"
trap 'rm -f \$LOCK_FILE' EXIT

mkdir -p "\$LOG_DIR"

log "════════════════════════════════════════════════════════════"
log "🎁 Microsoft Rewards - Iniciando"
log "════════════════════════════════════════════════════════════"

cd "\$INSTALL_DIR"
START=\$(date +%s)

if npm start >> "\$LOG_FILE" 2>&1; then
    log "✅ Concluído com sucesso!"
    EXIT_CODE=0
else
    EXIT_CODE=\$?
    log "❌ Falhou (código: \$EXIT_CODE)"
fi

DURATION=\$(($(date +%s) - START))
log "⏱️ Duração: \$((DURATION/60))m \$((DURATION%60))s"
log "════════════════════════════════════════════════════════════"

if [ "\$AUTO_SHUTDOWN" = "true" ] && [ \$EXIT_CODE -eq 0 ]; then
    log "💤 Desligando em \${SHUTDOWN_DELAY} minuto(s)..."
    sleep "\${SHUTDOWN_DELAY}m"
    systemctl poweroff -i
elif [ "\$AUTO_SHUTDOWN" = "true" ] && [ \$EXIT_CODE -ne 0 ]; then
    log "⚠️ Não desligando devido a erro"
fi

exit \$EXIT_CODE
SCRIPT

    chmod +x "$HOME/rewards-run.sh"
    print_success "Scripts criados!"
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXECUTAR AGORA
# ═══════════════════════════════════════════════════════════════════════════════

run_now() {
    print_step "Executar agora?"

    if confirm "Executar teste agora?"; then
        mkdir -p "$HOME/rewards-logs"
        log "🚀 Iniciando execução..."

        cd "$INSTALL_DIR"
        START_TIME=$(date +%s)

        if npm start 2>&1 | tee -a "$HOME/rewards-logs/rewards-$(date +%Y-%m-%d).log"; then
            EXIT_CODE=0
            log "✅ Script concluído!"
        else
            EXIT_CODE=$?
            log "❌ Script falhou"
        fi

        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))

        echo ""
        log "⏱️ Duração total: $((DURATION/60))m $((DURATION%60))s"

        if [ "$AUTO_SHUTDOWN" = "true" ] && [ $EXIT_CODE -eq 0 ]; then
            echo ""
            log "💤 Desligando o PC em 1 minuto..."
            log "   (Para cancelar: sudo shutdown -c)"
            sleep 60
            systemctl poweroff -i
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# RESUMO
# ═══════════════════════════════════════════════════════════════════════════════

show_summary() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✅ INSTALAÇÃO CONCLUÍDA!                         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  📁 Diretório:   ${CYAN}$INSTALL_DIR${NC}"
    echo -e "  👥 Conta:       ${CYAN}$ACCOUNT_EMAIL${NC}"
    echo -e "  📱 Telegram:    ${CYAN}$( [ "$TELEGRAM_ENABLED" = "true" ] && echo "Habilitado" || echo "Desabilitado" )${NC}"
    echo -e "  🔌 Auto-off:    ${CYAN}$( [ "$AUTO_SHUTDOWN" = "true" ] && echo "Sim (${SHUTDOWN_DELAY}min)" || echo "Não" )${NC}"
    echo ""
    echo -e "${WHITE}Comandos futuros:${NC}"
    echo -e "  ${CYAN}Executar:${NC}    $HOME/rewards-run.sh"
    echo -e "  ${CYAN}Logs:${NC}       tail -f ~/rewards-logs/rewards-\$(date +%Y-%m-%d).log"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    print_header

    detect_system
    install_dependencies
    clone_project
    build_project
    configure_account
    configure_telegram
    create_accounts
    create_config
    create_scripts
    configure_schedule
    configure_shutdown
    show_summary
    run_now
}

main "$@"
