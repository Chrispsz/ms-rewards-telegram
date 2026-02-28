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

function formatMessage(content: string, level: LogLevel): string {
    const emoji = getLevelEmoji(level)
    const escaped = escapeHTML(content)
    return `${emoji} <pre>${escaped}</pre>`
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
