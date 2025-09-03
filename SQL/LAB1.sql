----------------------------------zad 1-----------------------------------------------
select 
  * 
from 
  film f 
  left join film_category fc on f.film_id = fc.film_id 
  inner join category c on c.category_id = fc.category_id 
where 
  c.name = 'Action' 
  and f.release_year between 2001 
  and 2003 
order by 
  f.title asc;
 
----------------------------------zad 2-----------------------------------------------
select 
  a.actor_id, 
  a.first_name, 
  a.last_name, 
  count(fa.film_id) 
from 
  actor a 
  left join film_actor fa on fa.actor_id = a.actor_id 
group by 
  a.actor_id 
order by 
  count(fa.film_id) desc 
limit 
  3;
 
----------------------------------zad 3-----------------------------------------------
select 
  r.rental_id, 
  f.title, 
  c.first_name, 
  r.rental_date 
from 
  rental r 
  inner join inventory i ON r.rental_id = i.inventory_id 
  inner join customer c on c.customer_id = r.customer_id 
  inner join film f on f.film_id = i.film_id 
order by 
  r.rental_date desc 
limit 
  1;
 
----------------------------------zad 4-----------------------------------------------
select 
  s.store_id, 
  concat(a.address, ' ', c.city), 
  sum(p.amount) 
from 
  store s 
  inner join inventory i on s.store_id = i.store_id 
  inner join rental r on r.inventory_id = i.inventory_id 
  inner join payment p on p.rental_id = r.rental_id 
  inner join address a on a.address_id = s.address_id 
  inner join city c ON c.city_id = a.city_id 
group by 
  s.store_id, 
  a.address, 
  c.city;
 
-----------------------------------zad 5-----------------------------------------------
select 
  f.title, 
  count(r.rental_id) 
from 
  film f 
  inner join inventory i on f.film_id = i.film_id 
  inner join rental r on r.inventory_id = i.inventory_id 
  inner join film_category fc on fc.film_id = f.film_id 
  inner join category c on c.category_id = fc.category_id 
where 
  c.name = 'Documentary' 
group by 
  f.title 
order by 
  count(r.rental_id) desc 
limit 
  10;
 
----------------------------------zad 6-----------------------------------------------
select 
  r.rental_id, 
  r.rental_date, 
  r.return_date, 
  c.customer_id, 
  c.first_name, 
  (r.return_date - r.rental_date) 
from 
  rental r 
  inner join customer c on c.customer_id = r.customer_id 
where 
  DATE(r.return_date) - Date(r.rental_date) = '1';
 
----------------------------------zad 7-----------------------------------------------
select 
  c.customer_id, 
  c.first_name, 
  sum(p.amount) as spent 
from 
  customer c 
  inner join rental r on r.customer_id = c.customer_id 
  inner join payment p on p.rental_id = r.rental_id 
group by 
  c.customer_id 
having 
  sum(p.amount)> 500 
order by 
  sum(p.amount) desc;
 
----------------------------------zad 8-----------------------------------------------
select 
  c.customer_id, 
  c.first_name, 
  sum(p.amount) as spent, 
  (
    (
      select 
        sum(p.amount) 
      from 
        payment p
    )/(
      select 
        count(distinct c.customer_id) 
      from 
        customer c
    )
  ) as avg_spent 
from 
  customer c 
  inner join rental r on r.customer_id = c.customer_id 
  inner join payment p on p.rental_id = r.rental_id 
group by 
  c.customer_id 
having 
  sum(p.amount) > (
    select 
      sum(p.amount) 
    from 
      payment p
  )/(
    select 
      count(distinct c.customer_id) 
    from 
      customer c
  ) 
order by 
  sum(p.amount) desc;
 
----------------------------------zad 9-----------------------------------------------
 select 
  c.customer_id, 
  concat(c.first_name, ' ', c.last_name), 
  sum(p.amount), 
  string_agg(distinct f.title, ', ') 
from 
  customer c 
  join payment p on p.customer_id  = c.customer_id  
  join rental r on p.rental_id  = r.rental_id
  join inventory i on r.inventory_id = i.inventory_id 
  join film f on f.film_id = i.film_id 
  join film_category fc on fc.film_id = f.film_id 
  join category cat on cat.category_id = fc.category_id 
where 
  cat.name = 'Horror' 
group by 
  c.customer_id;
 
----------------------------------zad 10-----------------------------------------------
(
  select 
    f.title, 
    concat(
      extract(year from (r.rental_date)),
      '-', 
      extract(month from (r.rental_date))
    ), 
    count(r.rental_id) 
  from 
    rental r 
    inner join inventory i on i.inventory_id = r.inventory_id 
    inner join film f on f.film_id = i.film_id 
  where 
    concat(
      extract(year from (r.rental_date)),
      '-', 
      extract(month from (r.rental_date))
    ) = '2005-6' 
  group by 
    f.title, 
    concat(
      extract(year from (r.rental_date)),
      '-', 
      extract(month from (r.rental_date))
    ) 
  order by 
    count(r.rental_id) desc 
  limit 
    1
) 
union all 
  (
    select 
      f.title, 
      concat(
        extract(year from (r.rental_date)),
        '-', 
        extract(month from (r.rental_date))
      ), 
      count(r.rental_id) 
    from 
      rental r 
      inner join inventory i on i.inventory_id = r.inventory_id 
      inner join film f on f.film_id = i.film_id 
    where 
      concat(
        extract(year from (r.rental_date)),
        '-', 
        extract(month from (r.rental_date))
      ) = '2005-7' 
    group by 
      f.title, 
      concat(
        extract(year from (r.rental_date)),
        '-', 
        extract(month from (r.rental_date))
      ) 
    order by 
      count(r.rental_id) desc 
    limit 
      1
  ) 
union all 
  (
    select 
      f.title, 
      concat(
        extract(year from (r.rental_date)),
        '-', 
        extract(month from (r.rental_date))
      ), 
      count(r.rental_id) 
    from 
      rental r 
      inner join inventory i on i.inventory_id = r.inventory_id 
      inner join film f on f.film_id = i.film_id 
    where 
      concat(
        extract(year from (r.rental_date)),
        '-', 
        extract(month from (r.rental_date))
      ) = '2005-8' 
    group by 
      f.title, 
      concat(
        extract(year from (r.rental_date)),
        '-', 
        extract(month from (r.rental_date))
      ) 
    order by 
      count(r.rental_id) desc 
    limit 
      1
  );
 
----------------------------------zad 11-----------------------------------------------
select 
  c."name", 
  count(r.rental_id), 
  sum(p.amount) 
from 
  category c 
  inner join film_category fc on fc.category_id = c.category_id 
  inner join film f on f.film_id = fc.film_id 
  inner join inventory i on f.film_id = i.film_id 
  inner join rental r on r.inventory_id = i.inventory_id 
  inner join payment p on p.rental_id = r.rental_id 
  inner join customer c4 on c4.customer_id = r.customer_id 
  inner join address a on a.address_id = c4.address_id 
  inner join city c2 on c2.city_id = a.city_id 
  inner join country c3 on c2.country_id = c3.country_id 
where 
  c3.country = 'United States' 
group by 
  c."name", 
  a.address 
order by 
  count(r.rental_id) desc 
limit 
  3;
 
----------------------------------zad 12-----------------------------------------------
(
  select 
    s.staff_id, 
    concat(s.first_name, ' ', s.last_name), 
    a.address, 
    sum(p.amount) 
  from 
    staff s 
    inner join payment p on p.staff_id = s.staff_id 
    inner join store s2 on s2.store_id = s.store_id 
    inner join address a on s2.address_id = a.address_id 
  where 
    extract(year from (p.payment_date)) = '2017'
    and
      a.address = '28 MySQL Boulevard'
  group by 
    s.staff_id, 
    concat(s.first_name, ' ', s.last_name), 
    a.address 
  order by 
    sum(p.amount) desc 
  limit 
    1
) 
union all 
  (
    select 
      s.staff_id, 
      concat(s.first_name, ' ', s.last_name), 
      a.address, 
      sum(p.amount) 
    from 
      staff s 
      inner join payment p on p.staff_id = s.staff_id 
      inner join store s2 on s2.store_id = s.store_id 
      inner join address a on s2.address_id = a.address_id 
    where 
      extract(
        year 
        from 
          (p.payment_date)
      ) = '2017' 
      and a.address = '47 MySakila Drive' 
    group by 
      s.staff_id, 
      concat(s.first_name, ' ', s.last_name), 
      a.address 
    order by 
      sum(p.amount) desc 
    limit 
      1
  );
 
----------------------------------zad 13-----------------------------------------------
select 
  f.title, 
  count(r.rental_id) 
from 
  film_category fc 
  inner join category c on fc.category_id = c.category_id 
  inner join film f on f.film_id = fc.film_id 
  inner join inventory i on f.film_id = i.film_id 
  inner join rental r on r.inventory_id = i.inventory_id 
  inner join payment p on p.rental_id = r.rental_id 
  inner join customer c4 on c4.customer_id = r.customer_id 
  inner join address a on a.address_id = c4.address_id 
  inner join city c2 on c2.city_id = a.city_id 
  inner join country c3 on c2.country_id = c3.country_id 
where 
  c3.country = 'Poland' 
group by 
  f.title 
order by 
  count(r.rental_id) desc fetch first 1 rows with ties;
 
----------------------------------zad 14-----------------------------------------------
with tmp(cout) as (
  select 
    count(r.rental_id) 
  from 
    film_category fc 
    inner join category c on fc.category_id = c.category_id 
    inner join film f on f.film_id = fc.film_id 
    inner join inventory i on f.film_id = i.film_id 
    inner join rental r on r.inventory_id = i.inventory_id 
    inner join payment p on p.rental_id = r.rental_id 
    inner join customer c4 on c4.customer_id = r.customer_id 
    inner join address a on a.address_id = c4.address_id 
    inner join city c2 on c2.city_id = a.city_id 
    inner join country c3 on c2.country_id = c3.country_id 
  where 
    c3.country = 'Poland'
)

select 
  c3.country, 
  count(r.rental_id) 
from 
  tmp, 
  film_category fc 
  inner join category c on fc.category_id = c.category_id 
  inner join film f on f.film_id = fc.film_id 
  inner join inventory i on f.film_id = i.film_id 
  inner join rental r on r.inventory_id = i.inventory_id 
  inner join payment p on p.rental_id = r.rental_id 
  inner join customer c4 on c4.customer_id = r.customer_id 
  inner join address a on a.address_id = c4.address_id 
  inner join city c2 on c2.city_id = a.city_id 
  inner join country c3 on c2.country_id = c3.country_id 
group by 
  c3.country, 
  tmp.cout 
having 
  count(r.rental_id) > tmp.cout 
order by 
  count(r.rental_id) desc;
 
----------------------------------zad 15-----------------------------------------------
with data_ins as(
  select 
    'The Da Vinci Code' as title, 
    'Dan Brown' as description, 
    2006 as release_year, 
    1 as language_id, 
    4 as rental_duration, 
    0.99 as rental_rate, 
    149 as length, 
    9.99 as replacement_cost, 
    'asdaasd' :: tsvector as fulltext 
  union all 
  select 
    'A Beutiful Mind' as title, 
    'Yes' as description, 
    2001 as release_year, 
    1 as language_id, 
    4 as rental_duration, 
    1.99 as rental_rate, 
    135 as length, 
    9.99 as replacement_cost, 
    'asdaasd' :: tsvector as fulltext 
  union all 
  select 
    'Angels & Demons' as title, 
    'Dan Brown' as description, 
    2009 as release_year, 
    1 as language_id, 
    4 as rental_duration, 
    2.99 as rental_rate, 
    138 as length, 
    9.99 as replacement_cost, 
    'asdaasd' :: tsvector as fulltext
) INSERT INTO film (
  title, description, release_year, 
  language_id, rental_duration, rental_rate, 
  length, replacement_cost, fulltext
)

select * from data_ins di where not exists (
    select 
      * 
    from 
      film f 
    where 
      f.title = di.title
  ) returning *;
 
----------------------------------zad 16-----------------------------------------------
with data_ins as(
  select 
    'Tom' as first_name, 
    'Hanks' as last_name 
  union all 
  select 
    'RUSSEL' as first_name, 
    'CROWE' as last_name
) INSERT INTO actor (first_name, last_name) 
select 
  * 
from 
  data_ins di 
where 
  not exists (
    select 
      * 
    from 
      actor a 
    where 
      a.first_name = di.first_name 
      and a.last_name = di.last_name
  ) returning *;
with d_ins as (
  select 
    (
      select 
        a.actor_id 
      from 
        actor a 
      where 
        a.first_name = 'Tom' 
        and a.last_name = 'Hanks'
    ) as actor_id, 
    (
      select 
        f.film_id 
      from 
        film f 
      where 
        f.title = 'The Da Vinci Code'
    ) as film_id 
  union all 
  select 
    (
      select 
        a.actor_id 
      from 
        actor a 
      where 
        a.first_name = 'RUSSEL' 
        and a.last_name = 'CROWE'
    ) as actor_id, 
    (
      select 
        f.film_id 
      from 
        film f 
      where 
        f.title = 'A Beutiful Mind'
    ) as film_id 
  union all 
  select 
    (
      select 
        a.actor_id 
      from 
        actor a 
      where 
        a.first_name = 'Tom' 
        and a.last_name = 'Hanks'
    ) as actor_id, 
    (
      select 
        f.film_id 
      from 
        film f 
      where 
        f.title = 'Angels & Demons'
    ) as film_id
) INSERT INTO film_actor (actor_id, film_id) 
select 
  * 
from 
  d_ins d 
where 
  not exists (
    select 
      * 
    from 
      film_actor fa 
    where 
      fa.actor_id = d.actor_id 
      and fa.film_id = d.film_id
  ) returning *;
 
----------------------------------zad 17-----------------------------------------------
with dat as (
  select 
    1 as store_id, 
    (
      select 
        f.film_id 
      from 
        film f 
      where 
        f.title = 'The Da Vinci Code'
    ) as film_id 
  union all 
  select 
    2 as store_id, 
    (
      select 
        f.film_id 
      from 
        film f 
      where 
        f.title = 'A Beutiful Mind'
    ) as film_id 
  union all 
  select 
    2 as store_id, 
    (
      select 
        f.film_id 
      from 
        film f 
      where 
        f.title = 'Angels & Demons'
    ) as film_id
) insert into inventory (store_id, film_id) 
select 
  * 
from 
  dat d 
where 
  not exists (
    select 
      * 
    from 
      inventory i 
    where 
      i.film_id = d.film_id 
      and i.store_id = d.store_id
  ) returning *;
 
----------------------------------zad 18-----------------------------------------------
update 
  customer 
set 
  last_name = 'ADAMS' 
where 
  last_name = 'ADAM';
 
----------------------------------zad 19-----------------------------------------------
update 
  rental 
set 
  return_date = '2017-02-15 15:50:00.000 +0200' 
where 
  rental_id = (
    select 
      r.rental_id 
    from 
      rental r 
    order by 
      r.rental_date desc 
    limit 
      1
  );
 
----------------------------------zad 20-----------------------------------------------
delete from 
  payment 
where 
  payment_id in (
    select 
      p.payment_id 
    from 
      payment p 
    where 
      p.payment_date between '2017-01-26 13:00:00.000 +0100' 
      and '2017-01-26 15:30:00.000 +0100'
  );
