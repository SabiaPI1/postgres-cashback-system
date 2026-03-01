-- Вставка категорий кешбэка в таблицу cashback_categories
INSERT INTO cashback_categories (name, ratio) 
VALUES 
    ('Авиабилеты', 10.5),
    ('Аптеки', 4.5),
    ('Продукты', 3.0)
;

-- Вставка связей MCC-кодов с категорией "Авиабилеты"
INSERT INTO cashback_categories_mcc (mcc_id, category_id)
SELECT m.id, c.id
FROM "CardMCC" m
JOIN cashback_categories c ON lower(c.name) = 'авиабилеты'
WHERE lower(m."Name") LIKE '%авиакомпании%'
;

-- Вставка связей MCC-кодов с категорией "Аптеки"
INSERT INTO cashback_categories_mcc (mcc_id, category_id)
SELECT m.id, c.id
FROM "CardMCC" m
JOIN cashback_categories c ON lower(c.name) = 'аптеки'
WHERE lower(m."Name") LIKE '%аптека%'
;

-- Вставка связей MCC-кодов с категорией "Продукты"
INSERT INTO cashback_categories_mcc (mcc_id, category_id)
SELECT m.id, c.id
FROM "CardMCC" m
JOIN cashback_categories c ON lower(c.name) = 'продукты'
WHERE lower(m."Name") LIKE '%бакалейные магазины%' OR lower(m."Name") LIKE '%супермаркеты%'
;