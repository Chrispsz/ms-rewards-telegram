# Microsoft Rewards Script - Fork com Telegram

> Fork com **Telegram nativo** e **sem Discord**.

## Diferenças do Original

| Recurso | Original | Este Fork |
|---------|----------|-----------|
| Discord | ✅ | ❌ Removido |
| Telegram | ❌ | ✅ Nativo |
| GitHub Actions | ❌ | ✅ Incluído |
| Execução Paralela | ✅ | ✅ Otimizado |

## Instalação Local

### Método Rápido

```bash
git clone https://github.com/Chrispsz/ms-rewards-telegram.git
cd ms-rewards-telegram
nano setup-local.sh  # Edite suas contas
chmod +x setup-local.sh
./setup-local.sh
```

### Método Manual

```bash
git clone https://github.com/Chrispsz/ms-rewards-telegram.git
cd ms-rewards-telegram
npm install
npm run build
npx patchright install chromium
cp src/accounts.example.json src/accounts.json
cp src/config.example.json src/config.json
# Edite os arquivos e copie para dist/
cp src/accounts.json dist/
cp src/config.json dist/
npm start
```

## Execução Paralela

Configure `clusters` no config.json:

| Valor | Comportamento |
|-------|---------------|
| `1` | Sequencial |
| `2` | 2 contas em paralelo |

## GitHub Actions

1. Fork este repositório
2. Settings > Secrets > Actions:
   - `ACCOUNT_EMAIL`
   - `ACCOUNT_PASSWORD`
   - `ACCOUNT_TOTP` (opcional)
   - `TELEGRAM_BOT_TOKEN`
   - `TELEGRAM_CHAT_ID`
3. Habilite em Actions
4. Roda todo dia às 10:00 UTC (7:00 Brasília)

## Telegram

1. @BotFather > `/newbot` > copie o token
2. Acesse `https://api.telegram.org/bot<TOKEN>/getUpdates` para obter chat_id
3. Configure no config.json

## Workers

- `doDailySet` - Conjunto diário
- `doSpecialPromotions` - Promoções especiais
- `doMorePromotions` - Mais promoções
- `doPunchCards` - Punch cards
- `doDesktopSearch` - Pesquisas desktop
- `doMobileSearch` - Pesquisas mobile
- `doDailyCheckIn` - Check-in diário
- `doReadToEarn` - Ler para ganhar

## Troubleshooting

- **Login falha**: Delete `sessions/` e tente novamente
- **Browser não abre**: `npx patchright install chromium`
- **Conta travada EUA**: Use localmente ou VPS no Brasil

## Créditos

- [TheNetsky/Microsoft-Rewards-Script](https://github.com/TheNetsky/Microsoft-Rewards-Script)
