-- Функция для получения агрегированного отчета по кешбэку
CREATE OR REPLACE FUNCTION get_cashback_agg(
    client_code VARCHAR,
    date_start DATE,
    date_end DATE,
    cashback_category_name VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    category_name VARCHAR,
    total_amount NUMERIC,
    total_cashback NUMERIC
) AS $$
BEGIN
    RETURN QUERY
	-- CTE для агрегации данных по кешбэку
    WITH cashback_data AS (
        SELECT 
            COALESCE(cc.name, 'Без категории') AS category_name,
            SUM(CASE WHEN t.is_plan = FALSE THEN t.amount ELSE 0 END) AS total_amount,
            SUM(CASE WHEN t.is_plan = FALSE THEN (t.amount * cc.ratio / 100) ELSE 0 END) AS total_cashback
        FROM 
            Transactions t
        LEFT JOIN 
            cashback_categories_mcc mcc ON t.operation_id = mcc.mcc_id
        LEFT JOIN 
            cashback_categories cc ON mcc.category_id = cc.id
        JOIN 
            Cards c ON t.operation_id = c.id
        JOIN 
            Accounts a ON c.instownerid = a.instownerid
        WHERE 
            (a.instownerid = client_code OR client_code IS NULL)
            AND t.trandatetime BETWEEN date_start AND date_end + INTERVAL '1 day' - INTERVAL '1 second'
            AND (cashback_category_name IS NULL OR cc.name = cashback_category_name)
        GROUP BY 
            category_name
    )
    SELECT 
        category_name,
        total_amount,
        total_cashback
    FROM 
        cashback_data;
END;
$$ LANGUAGE plpgsql;