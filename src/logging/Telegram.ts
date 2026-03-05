import axios, { AxiosRequestConfig } from 'axios'
import PQueue from 'p-queue'
import type { LogLevel } from './Logger'

export interface WebhookTelegramConfig {
    enabled?: boolean
    botToken: string
    chatId: string
    parseMode?: 'HTML' | 'Markdown' | 'MarkdownV2'
    silent?: boolean
}

const telegramQueue = new PQueue({
    interval: 1000,
    intervalCap: 5,
    carryoverConcurrencyCount: true
})

function escapeHTML(text: string): string {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
}

function getLevelEmoji(level: LogLevel): string {
    const emojis: Record<LogLevel, string> = {
        error: '❌',
        warn: '⚠️',
        info: '✅',
        debug: '🔍'
    }
    return emojis[level] || 'ℹ️'
}

// Extrair nome curto do email
function getShortName(email: string): string {
    if (!email) return 'unknown'
    const name = email.split('@')[0] || 'unknown'
    // Pegar primeiro nome se for nome completo
    const shortName = name.split('.')[0]?.split('_')[0] || name
    return shortName.substring(0, 15)
}

// Formatar mensagem de forma limpa
function formatMessage(content: string, level: LogLevel): string {
    const emoji = getLevelEmoji(level)

    // ACCOUNT-END: Extrair info e formatar limpo
    if (content.includes('ACCOUNT-END')) {
        const emailMatch = content.match(/Completed account: ([^\s]+)/)
        const totalMatch = content.match(/Total: \+(\d+)/)
        const oldMatch = content.match(/Old: (\d+)/)
        const newMatch = content.match(/New: (\d+)/)

        if (emailMatch && totalMatch && emailMatch[1] && totalMatch[1]) {
            const name = getShortName(emailMatch[1])
            const total = totalMatch[1]
            const oldPts = oldMatch?.[1] ?? '?'
            const newPts = newMatch?.[1] ?? '?'

            return `${emoji} <b>${name}</b>: <code>+${total}</code> pts <i>(${oldPts} → ${newPts})</i>`
        }
    }

    // RUN-END: Resumo final consolidado
    if (content.includes('RUN-END')) {
        const accountsMatch = content.match(/Accounts processed: (\d+)/)
        const totalMatch = content.match(/Total points collected: \+(\d+)/)
        const oldMatch = content.match(/Old total: (\d+)/)
        const newMatch = content.match(/New total: (\d+)/)
        const timeMatch = content.match(/Total runtime: ([\d.]+)min/)

        if (totalMatch) {
            const accounts = accountsMatch ? accountsMatch[1] : '?'
            const total = totalMatch[1]
            const oldPts = oldMatch ? oldMatch[1] : '?'
            const newPts = newMatch ? newMatch[1] : '?'
            const time = timeMatch ? timeMatch[1] : '?'

            return `📊 <b>RESUMO</b>: <code>+${total}</code> pts em ${accounts} conta(s) | <i>${oldPts} → ${newPts}</i> | ⏱️ ${time}min`
        }
    }

    // ACCOUNT-ERROR: Erro de conta
    if (content.includes('ACCOUNT-ERROR')) {
        const emailMatch = content.match(/\[ACCOUNT-ERROR\] ([^\s:]+):?(.*)/)
        if (emailMatch && emailMatch[1]) {
            const name = getShortName(emailMatch[1])
            const error = emailMatch[2] ? emailMatch[2].trim().substring(0, 50) : 'Erro desconhecido'
            return `❌ <b>${name}</b>: ${escapeHTML(error)}`
        }
    }

    // Fallback para mensagens não reconhecidas
    return `${emoji} <pre>${escapeHTML(content)}</pre>`
}

export async function sendTelegram(
    config: WebhookTelegramConfig,
    content: string,
    level: LogLevel
): Promise<void> {
    if (!config?.botToken || !config?.chatId) return

    const url = `https://api.telegram.org/bot${config.botToken}/sendMessage`

    const request: AxiosRequestConfig = {
        method: 'POST',
        url,
        headers: { 'Content-Type': 'application/json' },
        data: {
            chat_id: config.chatId,
            text: formatMessage(content, level),
            parse_mode: config.parseMode || 'HTML',
            disable_notification: config.silent || false
        },
        timeout: 10000
    }

    await telegramQueue.add(async () => {
        try {
            await axios(request)
        } catch (err: any) {
            const status = err?.response?.status
            if (status === 429) return
            console.error('[Telegram] Error:', err?.message)
        }
    })
}

export async function flushTelegramQueue(timeoutMs = 5000): Promise<void> {
    await Promise.race([
        telegramQueue.onIdle(),
        new Promise<void>((_, reject) =>
            setTimeout(() => reject(new Error('telegram flush timeout')), timeoutMs)
        )
    ]).catch(() => {})
}
