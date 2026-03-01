-- Создание хранимой процедуры для перевода плановых проводок в фактические
CREATE OR REPLACE PROCEDURE process_cashback(calc_date DATE)
LANGUAGE plpgsql AS $$
DECLARE
    tp_id  bigint;
    currency_id bigint;
    contract_type_id bigint;
BEGIN
    -- Получаем ID аналитического признака проводки
    tp_id := (SELECT id FROM TransactionPortfolios WHERE name = 'Вознаграждение за операции');

    -- Получаем ID рублёвой валюты
    currency_id := (SELECT id FROM Currencies WHERE strcode = 'RUB');

    -- Получаем ID типа договора для стандартного банковского обслуживания
    contract_type_id := (SELECT id FROM ContractTypes WHERE ShortCode ='BANKING');

-- Обновление плановых проводок в фактические для клиентов с соответствующими условиями         
    UPDATE Transactions 
    SET is_plan = false
    FROM Contracts c
        JOIN Accounts a ON a.InstownerID = c.InstitutionID AND a.CurrencyID = currency_id AND a.AccType = 1
    WHERE 
        c.DateEnd IS NULL
        AND c.ContractTypeID = contract_type_id
        AND c.DateStart::date = calc_date
        AND Transactions.is_plan = true
        AND Transactions.transaction_portfolio_id = tp_id;

END;
$$;