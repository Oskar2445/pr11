-- Практична робота 11. Комбіновані завдання з групуванням та відбором даних
-- Варіант: Бібліотека
-- Питання дослідження: які книги мають найбільший попит на бронювання
-- і можуть потребувати придбання додаткових примірників?
--
-- Скрипт розрахований на наявну базу бібліотеки з таблицями books і readers.
-- У SQLite зовнішні ключі вмикаються для поточного з'єднання.

PRAGMA foreign_keys = ON;

-- ============================================================
-- Завдання 1. Створення таблиці бронювань та тестові дані
-- ============================================================

CREATE TABLE reservations (
    id INTEGER PRIMARY KEY,
    book_id INTEGER NOT NULL,
    reader_id INTEGER NOT NULL,
    reservation_date TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'fulfilled', 'cancelled')),
    expiry_date TEXT NOT NULL,
    note TEXT,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY (reader_id) REFERENCES readers(id) ON DELETE CASCADE,
    UNIQUE (book_id, reader_id, reservation_date)
);

INSERT INTO reservations
    (id, book_id, reader_id, reservation_date, status, expiry_date, note)
VALUES
    (1, 1, 1, '2026-11-02', 'active',    '2026-11-12', 'Черга на популярний роман'),
    (2, 1, 2, '2026-11-03', 'active',    '2026-11-13', 'Очікує звільнення примірника'),
    (3, 1, 3, '2026-11-04', 'fulfilled', '2026-11-14', 'Бронювання виконано'),
    (4, 2, 4, '2026-11-05', 'active',    '2026-11-15', 'Попит на поетичну збірку'),
    (5, 2, 5, '2026-11-06', 'active',    '2026-11-16', 'Очікує підтвердження'),
    (6, 4, 1, '2026-11-07', 'active',    '2026-11-17', 'Нове бронювання'),
    (7, 6, 2, '2026-11-08', 'cancelled', '2026-11-18', 'Читач скасував бронювання'),
    (8, 6, 3, '2026-11-09', 'active',    '2026-11-19', 'Очікує видачі');

-- Книга з id=7 навмисно не має жодного бронювання.

-- ============================================================
-- Завдання 2. JOIN + GROUP BY: кількість бронювань кожної книги
-- ============================================================

SELECT
    b.id,
    b.title,
    b.author,
    COUNT(r.id) AS reservation_count
FROM books AS b
JOIN reservations AS r ON r.book_id = b.id
GROUP BY b.id, b.title, b.author
ORDER BY reservation_count DESC, b.id;

-- Очікуваний результат:
-- 1 | Тигролови       | Іван Багряний       | 3
-- 2 | Кобзар          | Тарас Шевченко      | 2
-- 6 | Чорна рада      | Пантелеймон Куліш   | 2
-- 4 | Місто           | Валер’ян Підмогильний | 1

-- ============================================================
-- Завдання 3. Додаємо HAVING: залишаємо книги з більш ніж
-- одним бронюванням
-- ============================================================

SELECT
    b.id,
    b.title,
    b.author,
    COUNT(r.id) AS reservation_count
FROM books AS b
JOIN reservations AS r ON r.book_id = b.id
GROUP BY b.id, b.title, b.author
HAVING COUNT(r.id) > 1
ORDER BY reservation_count DESC, b.id;

-- Очікуваний результат:
-- 1 | Тигролови  | Іван Багряний     | 3
-- 2 | Кобзар     | Тарас Шевченко    | 2
-- 6 | Чорна рада | Пантелеймон Куліш | 2

-- ============================================================
-- Завдання 4. WHERE + JOIN + GROUP BY + HAVING
-- Беремо бронювання, створені з 2026-11-01, зі статусом active.
-- ============================================================

SELECT
    b.id,
    b.title,
    b.author,
    COUNT(r.id) AS active_reservations
FROM books AS b
JOIN reservations AS r ON r.book_id = b.id
WHERE r.reservation_date >= '2026-11-01'
  AND r.status = 'active'
GROUP BY b.id, b.title, b.author
HAVING COUNT(r.id) > 1
ORDER BY active_reservations DESC, b.id;

-- Результат:
-- 1 | Тигролови | Іван Багряний  | 2
-- 2 | Кобзар    | Тарас Шевченко | 2

-- ============================================================
-- Завдання 5а. Пастка групування за текстом замість id
-- Створюємо книгу-двійника з тією самою назвою, але іншим автором.
-- ============================================================

INSERT INTO books (id, title, author, publication_year, genre, copies_count)
VALUES (8, 'Тигролови', 'Тестовий Автор', 2020, 'Роман', 1);

INSERT INTO reservations
    (id, book_id, reader_id, reservation_date, status, expiry_date, note)
VALUES
    (9, 8, 4, '2026-11-10', 'active', '2026-11-20', 'Бронювання книги-двійника');

-- Правильний варіант: групування за первинним ключем книги.
SELECT
    b.id,
    b.title,
    COUNT(r.id) AS reservation_count
FROM books AS b
JOIN reservations AS r ON r.book_id = b.id
GROUP BY b.id, b.title
HAVING COUNT(r.id) > 1
ORDER BY b.id;

-- Групування лише за текстовою назвою: дві різні книги об'єднаються.
SELECT
    b.title,
    COUNT(r.id) AS reservation_count
FROM books AS b
JOIN reservations AS r ON r.book_id = b.id
GROUP BY b.title
HAVING COUNT(r.id) > 1
ORDER BY b.title;

-- ============================================================
-- Завдання 5б. LEFT JOIN
-- Книга id=7 не має бронювань. Через умову WHERE на r.status
-- та дату вона все одно не потрапить до результату.
-- ============================================================

SELECT
    b.id,
    b.title,
    COUNT(r.id) AS active_reservations
FROM books AS b
LEFT JOIN reservations AS r ON r.book_id = b.id
WHERE r.reservation_date >= '2026-11-01'
  AND r.status = 'active'
GROUP BY b.id, b.title
HAVING COUNT(r.id) > 1
ORDER BY active_reservations DESC, b.id;

-- Щоб побачити книгу без бронювань, умови з правої таблиці
-- потрібно перенести в ON або дозволити NULL у WHERE.
SELECT
    b.id,
    b.title,
    COUNT(r.id) AS reservation_count
FROM books AS b
LEFT JOIN reservations AS r
    ON r.book_id = b.id
   AND r.reservation_date >= '2026-11-01'
   AND r.status = 'active'
GROUP BY b.id, b.title
ORDER BY b.id;

-- Кінець практичної роботи 11.
