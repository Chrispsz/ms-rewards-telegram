# Microsoft Rewards Script - Fork Otimizado

> Fork do [Microsoft-Rewards-Script](https://github.com/TheNetsky/Microsoft-Rewards-Script) com **Telegram** nativo e **Discord removido**.

## 🚀 Diferenças do Original

| Recurso | Original | Este Fork |
|---------|----------|-----------|
| Notificações Discord | ✅ | ❌ Removido |
| Notificações Telegram | ❌ | ✅ Nativo |
| Ntfy | ✅ | ✅ Mantido |
| GitHub Actions | ❌ | ✅ Incluído |
| Setup automático | ❌ | ✅ Script incluído |

## ⚠️ Aviso Importante

> Este script automatiza tarefas do Microsoft Rewards. Use por sua conta e risco.
> A Microsoft pode banir contas por automação. Recomenda-se **1 conta por IP**.

## 📋 Requisitos

- Node.js >= 24
- npm ou bun
- Conta Microsoft

## 🔧 Instalação Rápida

### Linux/Mac

```bash
# Clone
git clone https://github.com/Chrispsz/ms-rewards-telegram.git
cd ms-rewards-telegram

# Instale e rode
npm run pre-build
npm run build

# Configure
cp src/accounts.example.json src/accounts.json
cp src/config.example.json src/config.json

# Edite com suas credenciais
nano src/accounts.json
nano src/config.json

# Rode
npm start
```

### Usando Script de Setup

```bash
chmod +x setup-rewards.sh
./setup-rewards.sh
```

## 📱 Configuração do Telegram

### 1. Criar Bot

1. Abra o Telegram
2. Busque por **@BotFather**
3. Envie `/newbot`
4. Siga as instruções
5. Copie o **botToken** (formato: `123456789:ABC...`)

### 2. Obter Chat ID

1. Inicie conversa com seu bot
2. Acesse no navegador:
   ```
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
3. Procure por `"chat":{"id":NUMERO`

### 3. Configurar

```json
{
    "webhook": {
        "telegram": {
            "enabled": true,
            "botToken": "123456789:ABC...",
            "chatId": "123456789",
            "parseMode": "HTML",
            "silent": false
        },
        "webhookLogFilter": {
            "enabled": true,
            "mode": "whitelist",
            "keywords": ["starting account", "collected", "ACCOUNT-END"]
        }
    }
}
```

## 🔄 GitHub Actions

### Setup

1. **Fork** este repositório

2. Vá em **Settings > Secrets and variables > Actions**

3. Adicione os secrets:

| Secret | Descrição |
|--------|-----------|
| `ACCOUNT_EMAIL` | Email da conta Microsoft |
| `ACCOUNT_PASSWORD` | Senha da conta |
| `ACCOUNT_TOTP_SECRET` | Secret 2FA (opcional) |
| `ACCOUNT_RECOVERY_EMAIL` | Email de recuperação (opcional) |
| `ACCOUNT_GEO_LOCALE` | Código do país (ex: br, us) |
| `ACCOUNT_LANG_CODE` | Código do idioma (ex: pt, en) |
| `TELEGRAM_ENABLED` | `true` para habilitar |
| `TELEGRAM_BOT_TOKEN` | Token do bot Telegram |
| `TELEGRAM_CHAT_ID` | ID do chat/grupo |

4. Habilite o workflow em **Actions**

5. O script roda automaticamente todo dia às 7:00 UTC

### ⚠️ Riscos do GitHub Actions

- IPs dos runners são dos **EUA**
- Sua conta pode ficar "travada" na região americana
- Use **no máximo 1 conta** por repositório
- Para múltiplas contas, use servidores diferentes

## 📁 Estrutura de Arquivos

```
├── src/
│   ├── accounts.json      # Suas contas (criar)
│   ├── config.json        # Configuração (criar)
│   ├── index.ts           # Entrada principal
│   ├── browser/           # Automação do browser
│   ├── functions/         # Workers e atividades
│   ├── logging/           # Sistema de logs
│   │   ├── Telegram.ts    # Webhook Telegram ✨
│   │   ├── Ntfy.ts        # Webhook Ntfy
│   │   └── Logger.ts      # Sistema de logs
│   └── interface/         # Tipos TypeScript
├── .github/workflows/
│   └── rewards.yml        # GitHub Actions
└── setup-rewards.sh       # Script de setup
```

## ⚙️ Configuração de Conta

```json
[
    {
        "email": "seu@email.com",
        "password": "sua_senha",
        "totpSecret": "",
        "recoveryEmail": "",
        "geoLocale": "auto",
        "langCode": "pt",
        "proxy": {
            "proxyAxios": false,
            "url": "",
            "port": 0,
            "username": "",
            "password": ""
        }
    }
]
```

## 🔐 2FA (TOTP)

Se você usa Microsoft Authenticator:

1. Vá em https://account.microsoft.com/security
2. Métodos de entrada > App autenticador
3. **Adicionar novo app**
4. Quando mostrar o QR, clique em **"Não consigo escanear"**
5. Copie o código secreto
6. Cole no `totpSecret` do accounts.json

## 📊 Workers Disponíveis

| Worker | Descrição |
|--------|-----------|
| `doDailySet` | Conjunto diário de atividades |
| `doSpecialPromotions` | Promoções especiais |
| `doMorePromotions` | Mais promoções |
| `doPunchCards` | Punch cards |
| `doAppPromotions` | Promoções do app mobile |
| `doDesktopSearch` | Pesquisas desktop |
| `doMobileSearch` | Pesquisas mobile |
| `doDailyCheckIn` | Check-in diário |
| `doReadToEarn` | Ler para ganhar |

## 🛠️ Comandos

```bash
# Instalar dependências
npm install

# Build do TypeScript
npm run build

# Rodar o script
npm start

# Modo desenvolvimento
npm run dev

# Limpar sessões
npm run clear-sessions

# Abrir sessão no browser
npm run open-session -- -email seu@email.com
```

## 📝 Logs

- Logs salvos em `~/rewards-logs/`
- Nome do arquivo: `rewards-YYYY-MM-DD.log`
- Para ver em tempo real:
  ```bash
  tail -f ~/rewards-logs/rewards-$(date +%Y-%m-%d).log
  ```

## 🔌 Desligamento Automático

O script de setup inclui opção de desligar o PC após completar:

```bash
# Configurado em ~/.rewards.conf
AUTO_SHUTDOWN=true
SHUTDOWN_DELAY=1  # minutos
```

Para cancelar o desligamento:
```bash
sudo shutdown -c
```

## ❓ Troubleshooting

### Login falha
- Delete a pasta `sessions/` e tente novamente
- Verifique se a senha está correta
- Se usar 2FA, configure o `totpSecret`

### Script não abre o browser
- Instale o Chromium: `npx patchright install chromium`
- Verifique se tem Node.js >= 24

### Não recebe pontos de pesquisa
- A v3.x não suporta totalmente a nova interface do Bing
- Tente rodar em horários diferentes

### Conta travada nos EUA
- Ocorre quando roda via GitHub Actions
- Use um servidor local ou VPS no Brasil

## 📜 Licença

GPL-3.0-or-later - Veja [LICENSE](LICENSE)

## 🙏 Créditos

- [TheNetsky/Microsoft-Rewards-Script](https://github.com/TheNetsky/Microsoft-Rewards-Script) - Projeto original
