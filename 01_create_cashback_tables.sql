-- Создание таблицы cashback_categories для хранения категорий кешбэка и процентов начисления
CREATE TABLE IF NOT EXISTS cashback_categories (
    id int8 NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(150) NOT NULL,
    ratio numeric(5,2) NOT NULL

	CONSTRAINT chk_ratio CHECK (ratio >= 0 AND ratio <= 100)
);

-- Создание таблицы cashback_categories_mcc для связи MCC-кодов с категориями кешбэка и хранения времени последнего обновления
CREATE TABLE IF NOT EXISTS cashback_categories_mcc (
    mcc_id int8 NOT NULL,
    category_id int8 NOT NULL,
    updated_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_cashback_categories_mcc PRIMARY KEY (mcc_id, category_id),
    CONSTRAINT fk_mcc_id FOREIGN KEY (mcc_id) REFERENCES "CardMCC"(id),
    CONSTRAINT fk_category_id FOREIGN KEY (category_id) REFERENCES cashback_categories(id)
);