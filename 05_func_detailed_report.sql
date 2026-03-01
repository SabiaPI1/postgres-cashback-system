-- Функция для получения детализированного отчета по кешбэку
CREATE OR REPLACE FUNCTION get_cashback_detailed(
    start_date DATE,
    end_date DATE,
    p_client_code VARCHAR  
)
RETURNS TABLE (
    tran_datetime TIMESTAMP,
    client_code VARCHAR,
    card_number VARCHAR,
    amount NUMERIC,
    cashback_amount NUMERIC,
    cashback_running_total NUMERIC,
    increase_rate VARCHAR,
    is_plan VARCHAR
) AS $$
BEGIN
    -- Основной запрос для формирования детализированного отчета
    RETURN QUERY
    SELECT 
        t.trandatetime,
        a.instownerid AS client_code,
        CONCAT(SUBSTRING(c.number FROM 1 FOR 4), '****', SUBSTRING(c.number FROM 13 FOR 4)) AS card_number,
        t.amount,
        t.amount AS cashback_amount,
        SUM(t.amount) OVER (PARTITION BY a.instownerid ORDER BY t.trandatetime) AS cashback_running_total,
        CASE 
            WHEN LAG(SUM(t.amount) OVER (PARTITION BY a.instownerid ORDER BY t.trandatetime)) OVER (PARTITION BY a.instownerid ORDER BY t.trandatetime) IS NULL THEN '+0.00 %'
            ELSE 
                ROUND((SUM(t.amount) OVER (PARTITION BY a.instownerid ORDER BY t.trandatetime) - 
                LAG(SUM(t.amount) OVER (PARTITION BY a.instownerid ORDER BY t.trandatetime)) OVER (PARTITION BY a.instownerid ORDER BY t.trandatetime)) * 100.0 / 
                NULLIF(LAG(SUM(t.amount) OVER (PARTITION BY a.instownerid ORDER BY t.trandatetime)) OVER (PARTITION BY a.instownerid ORDER BY t.trandatetime), 0), 2) || ' %'
        END AS increase_rate,
        CASE WHEN t.is_plan THEN 'План' ELSE 'Факт' END AS is_plan
    FROM 
        Transactions t
    JOIN 
        Cards c ON t.operation_id = c.id
    JOIN 
        Accounts a ON c.instownerid = a.instownerid
    WHERE 
        t.trandatetime BETWEEN start_date AND end_date + interval '23 hours 59 minutes 59 seconds'
        AND a.instownerid = p_client_code;
END;
$$ LANGUAGE plpgsql;
