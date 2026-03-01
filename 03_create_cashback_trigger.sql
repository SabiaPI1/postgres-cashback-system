-- Создание триггерной функции для расчета кешбэка
CREATE OR REPLACE FUNCTION create_cashback_tran_plan()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    tp_id bigint; 
    currency_id bigint;               
    sender_account_id bigint;           
    receiver_account_id bigint;       
    cashback_amount numeric(15,2);   
BEGIN
    -- Получаем ID аналитического признака проводки
    tp_id := (SELECT id FROM TransactionPortfolios WHERE name = 'Вознаграждение за операции');

    -- Получаем ID рублёвой валюты
    currency_id := (SELECT id FROM Currencies WHERE strcode ='RUB');

    -- Получение ID счета отправителя (банка) с рублёвым счетом
    sender_account_id := (
        SELECT MAX(inst_acc.id)
        FROM Institutions inst 
        JOIN Accounts inst_acc ON inst_acc.InstownerID = inst.id
        WHERE inst.Code = '**OURBANK**' AND inst_acc.AccType = 0 AND inst_acc.CurrencyID = currency_id
    );

    -- Получение ID счета получателя (клиента) с рублёвым счетом
    receiver_account_id := (
        SELECT MAX(card_acc.id)
        FROM Cards card 
        JOIN Accounts card_acc ON card_acc.InstownerID = card.InstOwnerID
        WHERE card.id = NEW.CardID AND card_acc.AccType = 1 AND card_acc.CurrencyID = currency_id
    );

    -- Расчет суммы кешбэка на основе категории MCC-кода операции
    cashback_amount := (
        SELECT cat.ratio * NEW.Amount / 100
        FROM cashback_categories_mcc mcc_cat 
        JOIN cashback_categories cat ON cat.id = mcc_cat.category_id
        WHERE mcc_cat.mcc_id = NEW.CardMccID
    );

    -- Проверка условий для создания плановой проводки по кешбэку
    IF (receiver_account_id IS NOT NULL AND sender_account_id IS NOT NULL AND currency_id IS NOT NULL AND tp_id IS NOT NULL AND cashback_amount > 0) THEN
        -- Вставка плановой проводки в таблицу Transactions
        INSERT INTO Transactions(receiverid, senderid, currencyid, amount, trandatetime, is_plan, transaction_portfolio_id)
        VALUES (receiver_account_id, sender_account_id, currency_id, cashback_amount, NOW(), true, tp_id);
    END IF;
    
    -- Возврат NEW (обязательно для триггерной функции)
    RETURN NEW;
END
$$;

-- Создание триггера для вызова функции create_cashback_tran_plan
CREATE TRIGGER cashback_trigger
AFTER INSERT ON "CardOperations"
FOR EACH ROW
EXECUTE FUNCTION create_cashback_tran_plan();
