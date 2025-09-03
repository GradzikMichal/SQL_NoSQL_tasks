----------------------------zad 1-5-----------------------------
CREATE SEQUENCE book_book_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER TABLE  book_book_id_seq OWNER TO michal;

CREATE SEQUENCE reader_reader_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1; 
ALTER TABLE reader_reader_id_seq OWNER TO michal;

CREATE SEQUENCE borrow_borrow_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER TABLE borrow_borrow_id_seq OWNER TO michal;

CREATE SEQUENCE staff_staff_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER TABLE staff_staff_id_seq OWNER TO michal;

CREATE SEQUENCE store_store_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER TABLE store_store_id_seq OWNER TO michal;

CREATE SEQUENCE inventory_inventory_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER TABLE inventory_inventory_id_seq OWNER TO michal;

CREATE SEQUENCE publisher_publisher_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER TABLE publisher_publisher_id_seq OWNER TO michal;

CREATE DOMAIN year AS integer CONSTRAINT year_check CHECK ( VALUE >= 0 AND (VALUE <= 2025));
ALTER DOMAIN year OWNER TO michal;

CREATE TABLE Book (
  book_id integer DEFAULT nextval('book_book_id_seq' :: regclass) NOT NULL, 
  book_name text NOT NULL, 
  realese_year year NOT NULL, 
  publisher_id smallint not null
);
ALTER TABLE 
  Book OWNER TO michal;

CREATE TABLE Reader (
  reader_id integer DEFAULT nextval(
    'reader_reader_id_seq' :: regclass
  ) NOT NULL, 
  first_name text NOT NULL, 
  last_name text NOT NULL, 
  email text NOT NULL, 
  activebool boolean DEFAULT true NOT NULL, 
  create_date date DEFAULT ('now' :: text):: date NOT NULL
);

CREATE TABLE Borrowing (
  borrow_id integer DEFAULT nextval(
    'borrow_borrow_id_seq' :: regclass
  ) NOT NULL, 
  borrow_date timestamp with time zone NOT NULL, 
  inventory_id integer NOT NULL, 
  reader_id smallint NOT NULL, 
  return_date timestamp with time zone, 
  staff_id smallint NOT NULL, 
  last_update timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE Staff (
  staff_id integer DEFAULT nextval('staff_staff_id_seq' :: regclass) NOT NULL, 
  first_name text NOT NULL, 
  last_name text NOT NULL, 
  address text NOT NULL, 
  email text, 
  store_id smallint NOT NULL, 
  active boolean DEFAULT true NOT NULL
);

CREATE TABLE Store (
  store_id integer DEFAULT nextval('store_store_id_seq' :: regclass) NOT NULL, 
  manager_staff_id smallint NOT NULL, 
  address text NOT NULL
);

CREATE TABLE Inventory (
  inventory_id integer DEFAULT nextval(
    'inventory_inventory_id_seq' :: regclass
  ) NOT NULL, 
  book_id smallint NOT NULL, 
  store_id smallint NOT NULL
);

CREATE TABLE Publisher (
  publisher_id integer DEFAULT nextval(
    'publisher_publisher_id_seq' :: regclass
  ) NOT NULL, 
  first_name text NOT NULL, 
  last_name text NOT NULL
);

--------------------------------------------zad 5--------------------------------------
ALTER TABLE ONLY Book ADD CONSTRAINT book_pkey PRIMARY KEY (book_id);

ALTER TABLE ONLY Reader ADD CONSTRAINT reader_pkey PRIMARY KEY (reader_id);

ALTER TABLE ONLY Borrowing ADD CONSTRAINT borrow_pkey PRIMARY KEY (borrow_id);

ALTER TABLE ONLY Staff ADD CONSTRAINT staff_pkey PRIMARY KEY (staff_id);

ALTER TABLE ONLY Store ADD CONSTRAINT store_pkey PRIMARY KEY (store_id);

ALTER TABLE ONLY Inventory ADD CONSTRAINT inventory_pkey PRIMARY KEY (inventory_id);

ALTER TABLE ONLY Publisher ADD CONSTRAINT publisher_pkey PRIMARY KEY (publisher_id);

-----------------------------------zad 6-------------------------------------
ALTER TABLE 
  ONLY Book 
ADD 
  CONSTRAINT book_publisher_id_fkey FOREIGN KEY (publisher_id) REFERENCES Publisher(publisher_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE 
  ONLY Inventory 
ADD 
  CONSTRAINT inventory_book_id_fkey FOREIGN KEY (book_id) REFERENCES Book(book_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE 
  ONLY Inventory 
ADD 
  CONSTRAINT inventory_store_id_fkey FOREIGN KEY (store_id) REFERENCES Store(store_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE 
  ONLY Staff 
ADD 
  CONSTRAINT staff_store_id_fkey FOREIGN KEY (store_id) REFERENCES Store(store_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE 
  ONLY Borrowing 
ADD 
  CONSTRAINT borrow_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES Staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE 
  ONLY Borrowing 
ADD 
  CONSTRAINT borrow_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES Inventory(inventory_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE 
  ONLY Borrowing 
ADD 
  CONSTRAINT borrow_reader_id_fkey FOREIGN KEY (reader_id) REFERENCES Reader(reader_id) ON UPDATE CASCADE ON DELETE RESTRICT;

-------------------- zad 7------------------------------------
ALTER TABLE Borrowing ADD COLUMN expected_return_date TIMESTAMP;

alter table book add column realese_year year NOT null;

create 
or replace function return_date_func() returns trigger language plpgsql as
$$ begin if exists (
  select 
    b.borrow_id 
  from 
    borrowing b 
  where 
    b.inventory_id = new.inventory_id 
    and b.return_date is null
) then raise exception 'This book wasn`t returned! ';
end if;
new.expected_return_date = new.borrow_date + interval '1 month';
return new;
end;
$$;

create
or replace trigger return_date_trigger before insert on Borrowing for each row execute procedure return_date_func();
SELECT 
  EXISTS (
    SELECT 
      tgenabled 
    FROM 
      pg_trigger 
    WHERE 
      tgname = 'return_date_trigger' 
      AND tgenabled != 'D'
  );

----------------------------- zad 8 i 9 ----------------------------------
ALTER TABLE
  Reader 
ADD 
  UNIQUE (email);

------------------------------ zad 10 -------------------------------------
insert into publisher (first_name, last_name) 
values 
  ('Adam', 'Mickiewicz'), 
  ('Jan', 'Kochanowski'), 
  ('Juliusz', 'Slowacki'), 
  ('Dan', 'Brown'), 
  ('Jo', 'Nesbo'), 
  ('Juliusz', 'Cezar'), 
  ('Andrzej', 'Slowacki'), 
  ('Adam', 'Nowak'), 
  ('Ksiadz', 'Robak'), 
  ('Adam', 'Sandler');

insert into book (book_name, realese_year, publisher_id) values
  ('Ksiazka o romantyzmie', 1530, (select publisher_id from publisher where first_name = 'Adam' and last_name = 'Mickiewicz')),
  ('Ksiazka2', 2000, (select publisher_id from publisher where first_name = 'Jan' and last_name = 'Kochanowski')),
  ('Ksiazka3', 1230, (select publisher_id from publisher where first_name = 'Juliusz' and last_name = 'Slowacki')),
  ('Ksiazka4', 430, (select publisher_id from publisher where first_name = 'Dan' and last_name = 'Brown')),
  ('Przepisy kulinarne', 1453, (select publisher_id from publisher where first_name = 'Jo' and last_name = 'Nesbo')),
  ('Jak zbudowac dom', 324, (select publisher_id from publisher where first_name = 'Juliusz' and last_name = 'Cezar')),
  ('Skamieliny', 46, (select publisher_id from publisher where first_name = 'Andrzej' and last_name = 'Slowacki')),
  ('Ksiezyc', 678, (select publisher_id from publisher where first_name = 'Adam' and last_name = 'Nowak')),
  ('Fineasz i Ferb', 583, (select publisher_id from publisher where first_name = 'Ksiadz' and last_name = 'Robak')),
  ('Fretki', 905, (select publisher_id from publisher where first_name = 'Adam' and last_name = 'Sandler'));

INSERT INTO store (manager_staff_id, address) 
VALUES (1, 'Wroclaw');

INSERT INTO store (manager_staff_id, address) 
VALUES (2, 'Warszawa');

INSERT INTO store (manager_staff_id, address) 
VALUES (3, 'Poznan');

INSERT INTO store (manager_staff_id, address) 
VALUES (4, 'Opole');

INSERT INTO store (manager_staff_id, address) 
VALUES (5, 'Szczecin');

INSERT INTO store (manager_staff_id, address) 
VALUES (6, 'Berlin');

INSERT INTO store (manager_staff_id, address) 
VALUES (7, 'Lublin');

INSERT INTO store (manager_staff_id, address) 
VALUES (8, 'Bydgoszcz');

INSERT INTO store (manager_staff_id, address) 
VALUES (9, 'Torun');

INSERT INTO store (manager_staff_id, address) 
VALUES (10, 'Gdansk');

INSERT INTO staff (first_name, last_name, address, email, store_id, active) values
  ('Adam', 'Nowak', 'Warszawa', 'adam.nowak@gmail.com',
    (
      select 
        store_id 
      from 
        store 
      where 
        address = 'Warszawa'
    ), 
    true
  ), 
  ('Bogumil', 'Krzak', 'Poznan', 'krzak.bogumil@gmail.com',
    (
      select 
        store_id 
      from 
        store 
      where 
        address = 'Poznan'
    ), 
    true
  ), 
  ('Krzysztof', 'Was', 'Opole', 'krzys.was@gmail.com',
    (
      select 
        store_id 
      from 
        store 
      where 
        address = 'Opole'
    ), 
    true
  ), 
  ('Tomasz', 'Mak', 'Szczecin', 'tomek.mak@gmail.com',
    (
      select 
        store_id 
      from 
        store 
      where 
        address = 'Szczecin'
    ), 
    true
  ), 
  ('Michal', 'Maka', 'Berlin', 'michu.maka@gmail.com',
    (
      select 
        store_id 
      from 
        store 
      where 
        address = 'Berlin'
    ), 
    true
  ), 
  ('Kamila', 'kogut', 'Lublin', 'kamila.kogut@gmail.com',
    (
      select 
        store_id 
      from 
        store 
      where 
        address = 'Lublin'
    ), 
    true
  ), 
  ('Maria', 'Wlodarczyk', 'Bydgoszcz', 'maria.wl@gmail.com',
    (
      select 
        store_id 
      from 
        store 
      where 
        address = 'Bydgoszcz'
    ), 
    true
  ), 
  ('Janina', 'Przybysz', 'Torun', 'janina.przyb@gmail.com',
    (
      select 
        store_id 
      from 
        store 
      where 
        address = 'Torun'
    ), 
    true
  ), 
  ('Kornelia', 'Mika', 'Gdansk', 'krzys.was@gmail.com',
    (
      select 
        store_id 
      from 
        store 
      where 
        address = 'Gdansk'
    ), 
    true
  ), 
  ('Adam', 'Malysz', 'Wroclaw', 'malysz.adam@gmail.com',
    (
      select 
        store_id 
      from 
        store 
      where 
        address = 'Wroclaw'
    ), 
    true
  );

INSERT INTO inventory (book_id, store_id) 
values 
  (
    (select book_id from book where book_name = 'Ksiazka o romantyzmie'),
    (select store_id from store where address = 'Warszawa')
  ), 
  (
    (select book_id from book where book_name = 'Przepisy kulinarne'),
    (select store_id from store where address = 'Wroclaw')
  ), 
  (
   (select book_id from book where book_name = 'Skamieliny'),
    (select store_id from store where address = 'Torun')
  ), 
  (
    (select book_id from book where book_name = 'Ksiezyc'),
    (select store_id from store where address = 'Bydgoszcz')
  ), 
  (
    (select book_id from book where book_name = 'Fretki'),
    (select store_id from store where address = 'Opole')
  ), 
  (
    (select book_id from book where book_name = 'Ksiazka2'),
    (select store_id from store where address = 'Szczecin')
  ), 
  (
    (select book_id from book where book_name = 'Ksiazka3'),
    (select store_id from store where address = 'Lublin')
  ), 
  (
    (select book_id from book where book_name = 'Ksiazka4'),
    (select store_id from store where address = 'Gdansk')
  ), 
  (
    (select book_id from book where book_name = 'Fineasz i Ferb'),
    (select store_id from store where address = 'Berlin')
  ), 
  (
    (select book_id from book where book_name = 'Jak zbudowac dom'),
    (select store_id from store where address = 'Poznan')
  );

INSERT INTO reader (
    first_name, last_name, email, activebool, create_date
) 
values 
  ('Adam', 'Nowak', 'adam.nowak@gmail.com', true, now()),
  ('Michal', 'Krzyzak', 'michu.krzyz@gmail.com', true, now()),
  ('Alex', 'Morze', 'alex.morze@gmail.com', true, now()),
  ('Karolina', 'Krzeslo', 'karo.krzeslo@gmail.com', true, now()),
  ('Mikolaj', 'Kot', 'miki.kot@gmail.com', true, now()),
  ('Kasia', 'Pedrak', 'kasia.pedrak@gmail.com', true, now()),
  ('Monika', 'Ibisz', 'moniak@gmail.com', true, now()),
  ('Marcin', 'Nikij', 'marcin.nikij@gmail.com', true, now()),
  ('Karolina', 'Wyszydlo', 'karo.wyszydlo@gmail.com', true, now()),
  ('Asia', 'Czystek', 'asia.czystek@gmail.com', true, now());

insert into borrowing (borrow_date, inventory_id, reader_id, staff_id)
values ('2017-11-14 13:44:29.996577', 1, 30, 2);

insert into borrowing ( borrow_date, inventory_id, reader_id, staff_id)
values ('2017-05-14 13:44:29.996577', 2, 31, 2);

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id)
values ('2016-01-23 13:44:29.996577', 3, 32, 2);

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id)
values ('2020-04-16 13:44:29.996577', 4, 33, 2);

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id)
values ('2010-02-14 13:44:29.996577', 5, 34, 2);

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id)
values ('2011-09-28 13:44:29.996577', 6, 35, 2);

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id)
values ('2017-10-11 13:44:29.996577', 7, 36, 2);

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id, expected_return_date)
values ('2001-03-01 13:44:29.996577', 8, 37, 2, null);

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id)
values ('2002-01-06 13:44:29.996577', 9, 38, 2);

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id, expected_return_date)
values ('2017-07-09 13:44:29.996577', 10, 39, 2, null);

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id)
values ('2018-10-11 13:44:29.996577', 7, 36, 2);

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id)
values ('2018-03-11 13:44:29.996577', 7, 36, 2);

----------------------------------------- zad 11 ------------------------------------
create function user_current_borrows(id int) returns table (
  book_name text, expected_return_date timestamp
) immutable strict as $function$ 
select 
  b.book_name, 
  bw.expected_return_date 
from 
  book b 
  inner join inventory i on b.book_id = i.book_id 
  inner join borrowing bw on i.inventory_id = bw.inventory_id 
where 
  bw.reader_id = id 
  and bw.return_date is null;
$function$ language sql;

select * from user_current_borrows(39);

------------------------------------------ zad 12 -------------------------------
create function extend_borrows(reader_id int, arg_book_id int) returns void as $function$ 
update 
  borrowing bw 
set 
  expected_return_date = expected_return_date + interval '1 month' 
from 
  inventory i 
  inner join book b on b.book_id = i.book_id 
where 
  bw.inventory_id = i.inventory_id 
  and bw.reader_id = reader_id 
  and b.book_id = arg_book_id;
$function$ language sql;

select * from extend_borrows(39, 26);

select * from user_current_borrows(39);

----------------------------------------- zad 13 -------------------------------
create 
or replace function top_borrows(miesiac numeric) returns table (
  book_name text, autor text, Number_of_borrows int, 
  year_of_borrow numeric
) immutable strict as $function$ 
select 
  b.book_name, 
  concat(p.first_name, ' ', p.last_name), 
  count(i.inventory_id), 
  extract(
    year 
    from 
      bw.borrow_date
  ) 
from 
  book b 
  inner join publisher p on b.publisher_id = p.publisher_id 
  inner join inventory i on i.book_id = b.book_id 
  inner join borrowing bw on bw.inventory_id = i.inventory_id 
where 
  (
    extract(
      month 
      from 
        bw.borrow_date
    )
  )= miesiac 
group by 
  b.book_name, 
  concat(p.first_name, ' ', p.last_name), 
  extract(
    year 
    from 
      bw.borrow_date
  ) 
order by 
  count(i.inventory_id) desc 
limit 
  5;
$function$ language sql;

select * from top_borrows(10);

-------------------------------------------- zad 14 ------------------------------------
create 
or replace view books_in_library as 
select 
  kw.book_name, 
  (bw.return_date is not null) as avaibility 
from 
  (
    select 
      b.book_name as book_name, 
      bw.inventory_id as inv_id_top_borrow, 
      max(bw.borrow_date) as dat_top_borrow_id 
    from 
      book b 
      inner join publisher p on b.publisher_id = p.publisher_id 
      inner join inventory i on i.book_id = b.book_id 
      inner join borrowing bw on bw.inventory_id = i.inventory_id 
    group by 
      b.book_name, 
      bw.inventory_id
  ) kw 
  inner join borrowing bw on bw.inventory_id = kw.inv_id_top_borrow 
where 
  kw.dat_top_borrow_id = bw.borrow_date;
select 
  * 
from 
  books_in_library;

----------------------------------------- zad 15 ----------------------------------------
create role reader LOGIN;

revoke all on all tables in schema library from reader;

GRANT USAGE ON SCHEMA library TO reader;

grant select on books_in_library to reader;

set role reader;

set role michal;

-- for testing roles
select * from borrowing b;

select * from books_in_library;

-------------------------------------- zad 16 ---------------------------------------
create role administrator LOGIN;

revoke all on all tables in schema library from administrator;
GRANT USAGE ON SCHEMA library TO administrator;

grant
select,
  insert, 
  update, 
  delete, 
  trigger on all tables in schema "library" to administrator;

GRANT USAGE ON SCHEMA library TO administrator;

--------------------------------------- zad dodatkowe -------------------------------
CREATE TABLE penalties (
  penalty_id SERIAL primary key, inventory_id integer NOT NULL, 
  book_name text not null, reader_id smallint NOT NULL, 
  reader_name text not null, days_over_limit integer not null, 
  cost_per_day integer default 2 not null, 
  total_cost integer not null
);

create table genre (genre_id serial primary key, genre_name text not null unique);

alter table book add   column genre_id integer;

alter table borrowing add column is_payment_done boolean default false;

insert into genre (genre_name) 
values 
  ('Mystery'), 
  ('Western'), 
  ('Romance'), 
  ('Sci-Fi'), 
  ('Fantasy'), 
  ('Horror'), 
  ('Adventure'), 
  ('Historical');

select 
  * 
from 
  genre;

ALTER TABLE 
  ONLY book 
ADD 
  CONSTRAINT genre_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES genre(genre_id) ON UPDATE CASCADE ON DELETE RESTRICT;

create 
or replace function update_payments() returns void as $function$ 
truncate table penalties;
insert into penalties (
  inventory_id, book_name, reader_id, 
  reader_name, days_over_limit, total_cost
) 
select 
  bw.inventory_id, 
  b.book_name, 
  bw.reader_id, 
  concat(r.first_name, ' ', r.last_name), 
  extract(day from (bw.return_date - bw.expected_return_date)),
  2 * extract(day from (bw.return_date - bw.expected_return_date)) 
from 
  borrowing bw 
  inner join inventory i on bw.inventory_id = i.inventory_id 
  inner join book b on b.book_id = i.book_id 
  inner join reader r on r.reader_id = bw.reader_id 
where 
  bw.return_date is not null 
  and bw.is_payment_done = false 
  and extract( day from (bw.return_date - bw.expected_return_date)) > 0;
$function$ language sql volatile;

select * from update_payments();

select * from penalties;

create 
or replace function return_date_check_payment_func() 
returns trigger language plpgsql as $$ 
begin 
	perform (
  select 
    * 
  from 
    update_payments()
);
if exists (
  select 
    p.total_cost 
  from 
    penalties p 
  where 
    p.reader_id = new.reader_id
) then raise exception 'Firstly you need to pay: %', 
(
  select 
    p.total_cost 
  from 
    penalties p 
  where 
    p.reader_id = new.reader_id
);
end if;
if exists (
  select 
    b.borrow_id 
  from 
    borrowing b 
  where 
    b.inventory_id = new.inventory_id 
    and b.return_date is null
) then raise exception 'This book wasn`t returned! ';
end if;
new.expected_return_date = new.borrow_date + interval '1 month';
return new;
end;
$$;

create
or replace trigger return_date_trigger before insert on Borrowing for each row execute procedure return_date_check_payment_func();

insert into Borrowing (borrow_date, inventory_id, reader_id, staff_id, expected_return_date)
values ('2017-07-09 13:44:29.996577', 10, 39, 2, null);
