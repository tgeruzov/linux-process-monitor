#!/bin/bash

# --- Конфигурация ---
PROCESS_NAME="test"
LOG_FILE="/var/log/monitoring.log"
API_URL="https://test.com/monitoring/test/api"
CHECK_INTERVAL=60

# Переменная для хранения PID с предыдущей проверки
LAST_PID=""

# Функция логирования с текущей датой
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Бесконечный цикл проверки
while true; do
    # Получаем PID процесса (берем старейший, если их несколько, флаг -o)
    CURRENT_PID=$(pgrep -x -o "$PROCESS_NAME")

    # Если процесс запущен (PID не пустой)
    if [[ -n "$CURRENT_PID" ]]; then
        
        # --- Требование 3: Стучаться по HTTPS ---
        # -s: silent (без прогресс-бара)
        # -f: fail (возвращает код ошибки при HTTP 4xx/5xx)
        # -o /dev/null: не выводить тело ответа в консоль
        # --connect-timeout 10: тайм-аут, чтобы скрипт не вис
        if ! curl -s -f -o /dev/null --connect-timeout 10 "$API_URL"; then
             # --- Требование 5: Если сервер недоступен, писать в лог ---
             log_message "ERROR: Monitoring server $API_URL is unreachable or returned error."
        fi

        # --- Требование 4: Проверка на перезапуск ---
        # Если у нас есть сохраненный PID и он не совпадает с текущим -> был перезапуск
        if [[ -n "$LAST_PID" && "$LAST_PID" != "$CURRENT_PID" ]]; then
            log_message "WARNING: Process '$PROCESS_NAME' was restarted. Old PID: $LAST_PID, New PID: $CURRENT_PID"
        fi

        # Обновляем запомненный PID
        LAST_PID=$CURRENT_PID

    else
        # Если процесс не запущен, сбрасываем LAST_PID, 
        # чтобы при следующем его запуске не сработало ложное "Process restarted"
        LAST_PID=""
    fi

    # --- Требование 2: Отрабатывать каждую минуту ---
    sleep "$CHECK_INTERVAL"
done
