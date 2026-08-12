---
name: z-claw-provider-setup
description: Use when configuring the AutoClaw Z.AI (Z-Claw) provider in OpenCode, refreshing its JWT token, or troubleshooting Z-Claw authentication and model setup.
---

# OpenCode Z-Claw Provider Setup

Пошаговая инструкция по добавлению провайдера AutoClaw Z.AI (Z-Claw) в OpenCode.

## Предварительные условия

- Установленный OpenCode (проверен на v1.17.20)
- Работающий AutoClaw Gateway с локальным API на `127.0.0.1:18432`
- Установленный `curl`

## Шаг 1: Получить JWT-токен

AutoClaw предоставляет JWT-токен через локальный API:

```bash
curl -s http://127.0.0.1:18432/get_token
```

Ответ — строка вида `Bearer eyJhbG…NiIs...` (~400 символов).

**Важно:** Токен живёт ~24 часа. При истечении API вернёт ошибку `token expired or incorrect`.

## Шаг 2: Настроить провайдера в конфиге OpenCode

Редактируем `~/.config/opencode/opencode.json`. Добавляем в секцию `provider`:

```json
"z-claw": {
  "name": "Z-Claw",
  "npm": "@ai-sdk/openai-compatible",
  "options": {
    "baseURL": "https://autoglm-api.autoglm.ai/autoclaw-proxy/proxy/autoclaw/v1",
    "apiKey": "autoclaw-internal-proxy",
    "headers": {
      "X-Authorization": "Bearer <JWT_TOKEN_FROM_STEP_1>",
      "X-Request-Model": "zaicoding_glm-5.2",
      "X-Tm": "mac",
      "X-Version": "1.12.0",
      "X-Product": "autoclaw",
      "X-Channel": "zai",
      "X-Lang": "ru"
    }
  },
  "models": {
    "glm-5.2": {
      "name": "GLM-5.2",
      "limit": { "context": 1048576, "output": 307200 }
    },
    "glm-5-turbo": {
      "name": "GLM-5 Turbo",
      "limit": { "context": 204800, "output": 131072 }
    },
    "glm-auto": {
      "name": "GLM Auto",
      "limit": { "context": 1048576, "output": 393216 }
    }
  }
}
```

**Ключевые моменты:**

- Поле `npm`: `"@ai-sdk/openai-compatible"` — обязательно, OpenCode использует ai-sdk.
- Поле `apiKey`: статический ключ `"autoclaw-internal-proxy"`. **Без него API вернёт 401.**
- `X-Authorization`: JWT-токен из шага 1. **Без него тоже 401.**
- **Нужны оба заголовка одновременно.**

## Шаг 3: Добавить креды в auth.json

`~/.config/opencode/auth.json`:

```json
{
  "z-claw": {
    "key": "autoclaw-internal-proxy",
    "type": "api"
  }
}
```

## Шаг 4: Проверить

```bash
opencode providers list
opencode run --model z-claw/glm-5.2 "Привет"
```

## Доступные модели

| ID модели | Контекст | Max токенов |
|---|---|---|
| `z-claw/glm-5.2` | 1M | 307 200 |
| `z-claw/glm-5-turbo` | 200K | 131 072 |
| `z-claw/glm-auto` | 1M | 393 216 |

## Автоматическое обновление токена

Скрипт (токен живёт 24ч, обновляем каждые 20ч):

```bash
#!/bin/bash
# update-z-claw-token.sh
JWT=$(curl -s http://127.0.0.1:18432/get_token)
python3 -c "
import json
with open('$HOME/.config/opencode/opencode.json') as f:
    c = json.load(f)
c['provider']['z-claw']['options']['headers']['X-Authorization'] = '$JWT'
with open('$HOME/.config/opencode/opencode.json', 'w') as f:
    json.dump(c, f, indent=2)
"
```

Cron:

```bash
0 */20 * * * /path/to/update-z-claw-token.sh
```

## Архитектура запроса

```
OpenCode → ai-sdk → POST .../autoclaw-proxy/proxy/autoclaw/v1/chat/completions
  Headers:
    Authorization: Bearer autocl…roxy
    X-Authorization: Bearer <JWT>
    X-Request-Model: zaicoding_glm-5.2
    X-Tm: mac / X-Product: autoclaw
```

Без кастомного baseURL и заголовков OpenCode уходит на официальный `api.z.ai`, где JWT невалиден — поэтому нужен именно кастомный провайдер, а не встроенный Z.AI.
