--Step 1.Підготовка користувачів (users):очищення даних та перетворення дат з різними форматами

WITH users_step_1 AS (
    -- 1. Вибираємо потрібні поля та прибираємо зайві пробіли
    SELECT
        user_id,
        full_name,
        LOWER(TRIM(email)) AS clean_email,
        country,
        signup_source,
        signup_device,
        promo_signup_flag,
        TRIM(signup_datetime) AS signup_datetime_trimmed
    FROM cohort_users_raw
),
users_step_2 AS (
--2. Видалити компонент часу, залишити лише дату
SELECT
        user_id,
        full_name,
        clean_email,
        country,
        signup_source,
        signup_device,
        promo_signup_flag,
        SPLIT_PART(signup_datetime_trimmed, ' ', 1) AS signup_date_raw
    FROM users_step_1
),
users_step_3 AS (
    -- 3. Уніфікуємо розділювачі: . / - -> -
    SELECT
        user_id,
        full_name,
        clean_email,
        country,
        signup_source,
        signup_device,
        promo_signup_flag,
        REPLACE(REPLACE(signup_date_raw, '.', '-'), '/', '-') AS signup_date_normalized
    FROM users_step_2
),
users_final AS (
    -- 4. Через CASE приводимо дату до формату DD-MM-YYYY
   SELECT
        user_id,
        full_name,
        clean_email,
        country,
        signup_source,
        signup_device,
        promo_signup_flag,
        TO_DATE(
         CASE
                -- DD-MM-YYYY
                WHEN signup_date_normalized ~ '^\d{2}-\d{2}-\d{4}$' THEN
                    signup_date_normalized
                -- D-M-YYYY
                when signup_date_normalized ~ '^\d{1}-\d{1}-\d{4}$' THEN
                    LPAD(SPLIT_PART(signup_date_normalized, '-', 1), 2, '0') || '-' ||
                    LPAD(SPLIT_PART(signup_date_normalized, '-', 2), 2, '0') || '-' ||
                    SPLIT_PART(signup_date_normalized, '-', 3)
                -- DD-M-YYYY
                when signup_date_normalized ~ '^\d{2}-\d{1}-\d{4}$' THEN
                    SPLIT_PART(signup_date_normalized, '-', 1) || '-' ||
                    LPAD(SPLIT_PART(signup_date_normalized, '-', 2), 2, '0') || '-' ||
                    SPLIT_PART(signup_date_normalized, '-', 3)
                -- D-MM-YYYY
                when signup_date_normalized ~ '^\d{1}-\d{2}-\d{4}$' THEN
                    LPAD(SPLIT_PART(signup_date_normalized, '-', 1), 2, '0') || '-' ||
                    SPLIT_PART(signup_date_normalized, '-', 2) || '-' ||
                    SPLIT_PART(signup_date_normalized, '-', 3)
                -- DD-MM-YY
                when signup_date_normalized ~ '^\d{2}-\d{2}-\d{2}$' THEN
                    SPLIT_PART(signup_date_normalized, '-', 1) || '-' ||
                    SPLIT_PART(signup_date_normalized, '-', 2) || '-20' ||
                    SPLIT_PART(signup_date_normalized, '-', 3)
                    -- D-M-YY
                WHEN signup_date_normalized ~ '^\d{1}-\d{1}-\d{2}$' THEN
                    LPAD(SPLIT_PART(signup_date_normalized, '-', 1), 2, '0') || '-' ||
                    LPAD(SPLIT_PART(signup_date_normalized, '-', 2), 2, '0') || '-20' ||
                    SPLIT_PART(signup_date_normalized, '-', 3)
                -- DD-M-YY
                when signup_date_normalized ~ '^\d{2}-\d{1}-\d{2}$' THEN
                    SPLIT_PART(signup_date_normalized, '-', 1) || '-' ||
                    LPAD(SPLIT_PART(signup_date_normalized, '-', 2), 2, '0') || '-20' ||
                    SPLIT_PART(signup_date_normalized, '-', 3)
                -- D-MM-YY
                when signup_date_normalized ~ '^\d{1}-\d{2}-\d{2}$' THEN
                    LPAD(SPLIT_PART(signup_date_normalized, '-', 1), 2, '0') || '-' ||
                    SPLIT_PART(signup_date_normalized, '-', 2) || '-20' ||
                    SPLIT_PART(signup_date_normalized, '-', 3)
                ELSE NULL
            END,
            'DD-MM-YYYY'
        )::timestamp AS signup_datetime_clean
    FROM users_step_3
),
--Step 2. Підготовка подій (events)
events_step_1 AS (
    -- 1. Вибираємо потрібні поля та прибираємо зайві пробіли
        SELECT
        event_id,
        user_id,
        event_type,
        revenue,
        TRIM(event_datetime) AS event_datetime_trimmed
    FROM cohort_events_raw
),
events_step_2 AS (
    -- 2. Прибираємо час, залишаємо тільки дату
    SELECT
        event_id,
        user_id,
        event_type,
        revenue,
        SPLIT_PART(event_datetime_trimmed, ' ', 1) AS event_date_raw
    FROM events_step_1
),
events_step_3 AS (
    -- 3. Уніфікуємо розділювачі: . / - -> -
    SELECT
        event_id,
        user_id,
        event_type,
        revenue,
        REPLACE(REPLACE(event_date_raw, '.', '-'), '/', '-') AS event_date_normalized
    FROM events_step_2
),
events_final AS(
    -- 4. Через CASE приводимо дату до формату DD-MM-YYYY
select 
event_id,
        user_id,
        event_type,
        revenue, 
        TO_DATE(
            CASE
            -- DD-MM-YYYY
                WHEN event_date_normalized ~ '^\d{2}-\d{2}-\d{4}$' THEN
                    event_date_normalized
                -- D-M-YYYY
                WHEN event_date_normalized ~ '^\d{1}-\d{1}-\d{4}$' THEN
                    LPAD(SPLIT_PART(event_date_normalized, '-', 1), 2, '0') || '-' ||
                    LPAD(SPLIT_PART(event_date_normalized, '-', 2), 2, '0') || '-' ||
                    SPLIT_PART(event_date_normalized, '-', 3)
                -- DD-M-YYYY
                WHEN event_date_normalized ~ '^\d{2}-\d{1}-\d{4}$' THEN
                    SPLIT_PART(event_date_normalized, '-', 1) || '-' ||
                    LPAD(SPLIT_PART(event_date_normalized, '-', 2), 2, '0') || '-' ||
                    SPLIT_PART(event_date_normalized, '-', 3)
                -- D-MM-YYYY
                WHEN event_date_normalized ~ '^\d{1}-\d{2}-\d{4}$' THEN
                    LPAD(SPLIT_PART(event_date_normalized, '-', 1), 2, '0') || '-' ||
                    SPLIT_PART(event_date_normalized, '-', 2) || '-' ||
                    SPLIT_PART(event_date_normalized, '-', 3)
                -- DD-MM-YY
                WHEN event_date_normalized ~ '^\d{2}-\d{2}-\d{2}$' THEN
                    SPLIT_PART(event_date_normalized, '-', 1) || '-' ||
                    SPLIT_PART(event_date_normalized, '-', 2) || '-20' ||
                    SPLIT_PART(event_date_normalized, '-', 3)
                    -- D-M-YY
                WHEN event_date_normalized ~ '^\d{1}-\d{1}-\d{2}$' THEN
                    LPAD(SPLIT_PART(event_date_normalized, '-', 1), 2, '0') || '-' ||
                    LPAD(SPLIT_PART(event_date_normalized, '-', 2), 2, '0') || '-20' ||
                    SPLIT_PART(event_date_normalized, '-', 3)
                -- DD-M-YY
                WHEN event_date_normalized ~ '^\d{2}-\d{1}-\d{2}$' THEN
                    SPLIT_PART(event_date_normalized, '-', 1) || '-' ||
                    LPAD(SPLIT_PART(event_date_normalized, '-', 2), 2, '0') || '-20' ||
                    SPLIT_PART(event_date_normalized, '-', 3)
                -- D-MM-YY
                when event_date_normalized ~ '^\d{1}-\d{2}-\d{2}$' THEN
                    LPAD(SPLIT_PART(event_date_normalized, '-', 1), 2, '0') || '-' ||
                    SPLIT_PART(event_date_normalized, '-', 2) || '-20' ||
                    SPLIT_PART(event_date_normalized, '-', 3)
             ELSE NULL
            END,
            'DD-MM-YYYY'
        )::timestamp AS event_datetime_clean
    FROM events_step_3
),
--Step 3. Об'єднання таблиць
user_activity AS (
    SELECT
        u.user_id,
        u.promo_signup_flag,
        TO_CHAR(u.signup_datetime_clean, 'YYYY-MM') AS cohort_month,
        TO_CHAR(e.event_datetime_clean, 'YYYY-MM') AS activity_month,
        (
            EXTRACT(YEAR FROM AGE(e.event_datetime_clean, u.signup_datetime_clean)) * 12 +
            EXTRACT(MONTH FROM AGE(e.event_datetime_clean, u.signup_datetime_clean))
        )::int AS month_offset
    FROM users_final u
    JOIN events_final e
        ON u.user_id = e.user_id
    WHERE u.signup_datetime_clean IS NOT NULL
      AND e.event_datetime_clean IS NOT NULL
      AND e.event_type IS NOT NULL
      AND e.event_type <> 'test_event'
)
--Step 4.Фінальна агрегація
SELECT
    promo_signup_flag,
    cohort_month,
    month_offset,
    COUNT(DISTINCT user_id) AS users_total
FROM user_activity
WHERE activity_month BETWEEN '2025-01' AND '2025-06'
GROUP BY
    promo_signup_flag,
    cohort_month,
    month_offset
ORDER BY
    promo_signup_flag,
    cohort_month,
    month_offset;