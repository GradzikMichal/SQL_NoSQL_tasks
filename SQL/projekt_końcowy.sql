CREATE DOMAIN polish_pesel AS VARCHAR(13) CONSTRAINT pesel_check CHECK (
  VALUE ~* '^[0-9]{13}'
);
ALTER DOMAIN polish_pesel SET NOT null;
------------------------------------------------------------------------------
create DOMAIN e_mail AS varchar(50) CONSTRAINT e_mail_check CHECK (
  VALUE ~* '^\S+\.?\S+@[a-zA-Z]+?\.[a-zA-Z]{2,3}$'
);
ALTER DOMAIN e_mail SET NOT null;
------------------------------------------------------------------------------
CREATE DOMAIN phone AS VARCHAR(13) CONSTRAINT phone_check CHECK (
  VALUE ~* '^[0-9]{9,12}'
);
ALTER DOMAIN phone SET NOT null;
------------------------------------------------------------------------------
CREATE DOMAIN game_points AS integer
	CONSTRAINT points_check CHECK (((VALUE >= 0) AND (VALUE <= 10)));
------------------------------------------------------------------------------
CREATE TYPE diet_type AS ENUM (
    'meat',
    'vegeterian',
    'vegan',
    'special'
);
------------------------------------------------------------------------------
CREATE TYPE partner_type AS ENUM (
    'partner',
    'organizer',
    'sponsor'
);
------------------------------------------------------------------------------
CREATE TYPE participant_types AS ENUM (
    'participant',
    'cadre',
    'staff'
);

ALTER DOMAIN polish_pesel OWNER TO michal;
ALTER DOMAIN email OWNER TO michal;
ALTER DOMAIN phone OWNER TO michal;
ALTER DOMAIN game_points OWNER TO michal;
ALTER TYPE diet_type OWNER TO michal;
ALTER TYPE partner_type OWNER TO michal;
ALTER TYPE participant_types OWNER TO michal;


CREATE TABLE registration (
  registration_id SERIAL primary key,
  Imie text NOT NULL, 
  Nazwisko text not null,
  pesel polish_pesel NOT null UNIQUE, 
  e_mail dbproject.e_mail not null unique,
  birthday date not null, 
  phone_number phone not null unique , 
  address text not null,
  transport boolean not null,
  diet diet_type not null,
  contact_person text not null,
  contact_person_phone phone not null,
  payment boolean,
  registration_date timestamp not null
);

ALTER TABLE registration ALTER COLUMN registration_date SET DEFAULT now();


CREATE TABLE partners (
  partner_id SERIAL primary key,
  partner_name text NOT null unique, 
  partner_web_page text not null unique,
  type_partner partner_type not null
);
ALTER TABLE partners ALTER COLUMN type_partner SET DEFAULT CAST ('partner' AS partner_type);

CREATE TABLE participant (
  participant_id SERIAL primary key,
  participant_name text NOT NULL,
  participant_type participant_types not null,
  squad_id int not null,
  registration_id int not null
);

ALTER TABLE participant ALTER COLUMN squad_id SET DEFAULT 1;
ALTER TABLE participant ALTER COLUMN participant_type SET DEFAULT CAST ('participant' AS participant_types);


CREATE TABLE squads (
  squad_id SERIAL primary key,
  squad_name text NOT NULL
);

ALTER TABLE dbproject.squads ADD CONSTRAINT squad_name_unique UNIQUE (squad_name);

CREATE TABLE login_table (
  e_mail dbproject.e_mail not null unique,
  user_password text NOT null unique,
  participant_id int not null primary key
);

CREATE EXTENSION pgcrypto;

create 
or replace function create_password_func() returns trigger language plpgsql as $$ begin 
if exists (
  select 
     lt.e_mail
  from 
    login_table lt 
  where 
    lt."e_mail" = new.e_mail 
) then raise exception 'Email exists in database';
end if;
new.user_password = crypt(new.user_password, gen_salt('md5'));
return new;
end;
$$ 

create 
or replace trigger create_password_trigger before insert on login_table 
for each row execute procedure create_password_func();

create 
or replace function update_password_func() returns trigger language plpgsql as $$ begin 
if not exists (
  select 
     lt.e_mail
  from 
    login_table lt 
  where 
    lt.e_mail = new.e_mail 
) then raise exception 'Email does not exists in database';
end if;
new.user_password = crypt(new.user_password, gen_salt('md5'));
return new;
end;
$$ 

create 
or replace trigger update_password_trigger before update on login_table 
for each row execute procedure update_password_func();


CREATE TABLE workshop (
  workshop_id serial primary key,
  participant_limit int NOT null,
  number_of_participants int not null,
  workshop_leader_id int not null
);

ALTER TABLE workshop  ALTER COLUMN number_of_participants SET DEFAULT 0;


create table workshop_participants (
	participant_id int not null,
	workshop_id int not null
);

create table game_teams (
	game_team_id serial primary key,
	game_team_name text not null
);

ALTER TABLE dbproject.game_teams ADD CONSTRAINT game_team_name_unique UNIQUE (game_team_name);

create table point_team_station_night_game (
	station_id int not null,
	station_guardian_id int not null,
	team_id int not null,
	normal_points game_points not null,
	extra_points game_points not null,
	insert_date timestamp not null
)

create 
or replace function points_date_func() returns trigger language plpgsql as $$ begin 
if exists (
  select 
     p.station_id,
     p.station_guardian_id,
     p.team_id
  from 
    point_team_station_night_game p
  where 
    p.station_id = new.station_id and 
    p.station_guardian_id = new.station_guardian_id and 
    p.team_id = new.team_id
) then raise exception 'Team have points from this station';
end if;
new.insert_date = now();
return new;
end;
$$ 

create 
or replace trigger insert_date_trigger before insert on point_team_station_night_game for each row execute procedure points_date_func();

create table night_game (
	night_game_id serial primary key,
	teams_limit int not null,
	teams_registrated int not null
);

create table night_game_stations (
	station_id serial primary key,
	night_game_id int not null,
	station_title text not null,
	station_desc text not null
);

create table places (
	place_id serial primary key,
	place_name text not null,
	place_geopoint text not null,
	place_address text not null,
	place_photo text not null
);

create table schedule (
	schedule_id serial primary key,
	schedule_title text not null,
	schedule_description text not null,
	schedule_start_date timestamp unique not null,
	schedule_end_date timestamp unique not null,
	place_id int not null
);

create table night_game_in_schedule (
	schedule_id int not null unique,
	night_game_id int not null unique
);

create table workshop_in_schedule (
	schedule_id int not null unique,
	workshop_id int not null unique
);

create table participant_in_game_team (
	participant_id int not null,
	game_team_id int not null 
);

create table game_team_in_night_game (
	game_team_id int not null,
	night_game_id int not null
);

create 
or replace function check_night_game_limit_func() returns trigger language plpgsql as $$ begin 
if not exists (
  select 
     *
  from 
    night_game ng
  where 
	ng.night_game_id = new.night_game_id and 
	((
	select 
    	ng1.teams_limit
  	from 
    	night_game ng1
  	where 
		ng1.night_game_id = new.night_game_id
		)
		>
		(
	select 
    	ng2.teams_registrated
  	from 
    	night_game ng2
  	where 
		ng2.night_game_id = new.night_game_id
		))
) then raise exception 'The team cannot join to the night game';
end if;
update night_game set teams_registrated = teams_registrated + 1 where night_game_id = new.night_game_id;
return new;
end;
$$ 

create 
or replace trigger check_night_game_limit_trigger 
before insert on game_team_in_night_game 
for each row execute procedure check_night_game_limit_func();
-----------------
create 
or replace function check_workshop_limit_func() returns trigger language plpgsql as $$ begin 
if not exists (
  select 
     *
  from 
    workshop w
  where 
	w.workshop_id = new.workshop_id and 
	((
	select 
    	w1.participant_limit
  	from 
    	workshop w1
  	where 
		w1.workshop_id = new.workshop_id
		)
		>
		(
	select 
    	w1.number_of_participants
  	from 
    	workshop w1
  	where 
		w1.workshop_id = new.workshop_id
		))
) then raise exception 'The participant cannot be added to workshop';
end if;
update workshop set number_of_participants = number_of_participants + 1 where workshop_id = new.workshop_id;
return new;
end;
$$ 

create 
or replace trigger check_workshop_limit_trigger 
before insert on workshop_participants 
for each row execute procedure check_workshop_limit_func();


--##########################################################################################################################

ALTER TABLE ONLY login_table
    ADD CONSTRAINT login_table_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY participant
    ADD CONSTRAINT participant_registration_id_fkey FOREIGN KEY (registration_id) REFERENCES registration(registration_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY participant
    ADD CONSTRAINT participant_squad_id_fkey FOREIGN KEY (squad_id) REFERENCES squads(squad_id) ON UPDATE CASCADE ON DELETE RESTRICT;
   
ALTER TABLE ONLY participant_in_game_team
    ADD CONSTRAINT game_team_id_fkey FOREIGN KEY (game_team_id) REFERENCES game_teams(game_team_id) ON UPDATE CASCADE ON DELETE RESTRICT;   

ALTER TABLE ONLY participant_in_game_team
    ADD CONSTRAINT participant_id_fkey FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY game_team_in_night_game
    ADD CONSTRAINT game_team_id_fkey FOREIGN KEY (game_team_id) REFERENCES game_teams(game_team_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY game_team_in_night_game
    ADD CONSTRAINT night_game_id_fkey FOREIGN KEY (night_game_id) REFERENCES night_game(night_game_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY night_game_in_schedule
    ADD CONSTRAINT night_game_id_fkey FOREIGN KEY (night_game_id) REFERENCES night_game(night_game_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY night_game_in_schedule
    ADD CONSTRAINT schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES schedule(schedule_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY schedule
    ADD CONSTRAINT place_id_fkey FOREIGN KEY (place_id) REFERENCES places(place_id) ON UPDATE CASCADE ON DELETE RESTRICT;   
   
ALTER TABLE ONLY workshop_in_schedule
    ADD CONSTRAINT schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES schedule(schedule_id) ON UPDATE CASCADE ON DELETE RESTRICT;
   
ALTER TABLE ONLY workshop_in_schedule
    ADD CONSTRAINT workshop_id_fkey FOREIGN KEY (workshop_id) REFERENCES workshop(workshop_id) ON UPDATE CASCADE ON DELETE RESTRICT;
   
ALTER TABLE ONLY workshop_participants
    ADD CONSTRAINT workshop_id_fkey FOREIGN KEY (workshop_id) REFERENCES workshop(workshop_id) ON UPDATE CASCADE ON DELETE RESTRICT;
   
ALTER TABLE ONLY workshop_participants
    ADD CONSTRAINT participant_id_fkey FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY night_game_stations
    ADD CONSTRAINT night_game_id_fkey FOREIGN KEY (night_game_id) REFERENCES night_game(night_game_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY point_team_station_night_game
    ADD CONSTRAINT station_id_fkey FOREIGN KEY (station_id) REFERENCES night_game_stations(station_id) ON UPDATE CASCADE ON DELETE RESTRICT;    

ALTER TABLE ONLY point_team_station_night_game
    ADD CONSTRAINT station_guardion_id_fkey FOREIGN KEY (station_guardian_id) REFERENCES participant(participant_id) ON UPDATE CASCADE ON DELETE RESTRICT;    

ALTER TABLE ONLY point_team_station_night_game
    ADD CONSTRAINT team_id_fkey FOREIGN KEY (team_id) REFERENCES game_teams(game_team_id) ON UPDATE CASCADE ON DELETE RESTRICT;    

ALTER TABLE ONLY workshop
    ADD CONSTRAINT workshop_leader_id_fkey FOREIGN KEY (workshop_leader_id) REFERENCES participant(participant_id) ON UPDATE CASCADE ON DELETE RESTRICT;    
   
--###########################################################################################################################
INSERT 
INTO squads
(
squad_name
) 
VALUES 
  (
'No squad'
);
   
INSERT 
INTO registration 
(
imie, nazwisko, pesel, e_mail, birthday, phone_number, 
address, transport, diet, contact_person, contact_person_phone, payment, registration_date
) 
VALUES 
  (
'Michal', 'Gradzik', '9901231234567', 'test.test@gmail.com', '1999-01-23',
'123456789', 'ulica 12', true, 'meat', 'xyz zxc', '987654321', false, null
);

INSERT 
INTO registration 
(
imie, nazwisko, pesel, e_mail, birthday, phone_number, 
address, transport, diet, contact_person, contact_person_phone, payment
) 
VALUES 
  (
'sdfas', 'qewrre', '8972314791321', 'jknvd.poisdf@xyz.com', '1934-10-15',
'048123456789', 'adfsa 435', false, 'vegan', 'pokoadf', '082987654321', true
);

INSERT 
INTO registration 
(
imie, nazwisko, pesel, e_mail, birthday, phone_number, 
address, transport, diet, contact_person, contact_person_phone, payment
) 
VALUES 
  (
'kljzxlc', 'iopiaer', '7613478681089', 'jlasdu.wqeqeq@xyz.com', '1998-06-24',
'9890724123', 'hjafsasfwerq 435', true, 'vegeterian', 'qwrwadfzxc', '143214974', true
);

INSERT 
INTO registration 
(
imie, nazwisko, pesel, e_mail, birthday, phone_number, 
address, transport, diet, contact_person, contact_person_phone, payment
) 
VALUES 
  (
'jlafsdaf', 'zxcvmkm', '0987134623464', 'afdbbqmer@xc.sd', '1943-10-30',
'123123456', 'mlkcdaserwqr 435', true, 'special', 'erqwedsfcv', '993241343', true
);

INSERT 
INTO registration 
(
imie, nazwisko, pesel, e_mail, birthday, phone_number, 
address, transport, diet, contact_person, contact_person_phone, payment
) 
VALUES 
  (
'William', 'Shakespeare', '9214623408324', 'will.shak@xc.sd', '1233-03-17',
'903421443', 'Londonisle 1', false, 'meat', 'poewrasdfx', '239013464', true
);

INSERT 
INTO registration 
(
imie, nazwisko, pesel, e_mail, birthday, phone_number, 
address, transport, diet, contact_person, contact_person_phone, payment
) 
VALUES 
  (
'Bob', 'Cage', '0823148453432', 'bobc@xc.sds', '2020-06-27',
'923418543', 'Schoolish 1', false, 'special', 'Nicolas Cage', '423479032', true
);

INSERT 
INTO registration 
(
imie, nazwisko, pesel, e_mail, birthday, phone_number, 
address, transport, diet, contact_person, contact_person_phone, payment
) 
VALUES 
  (
'Name', 'Surname', '1340743257832', 'name@dsad.cxz', '2000-06-27',
'421478453', 'Street 1', true, 'meat', 'Surname Name', '894324675', true
);

-------------------------------------------------------------------------------------------------------------------

create or replace FUNCTION make_participants(limit_number int) RETURNS void 
    LANGUAGE sql
    AS $_$
    TRUNCATE participant cascade;
    ALTER SEQUENCE participant_participant_id_seq RESTART WITH 1;
    insert into participant(participant_name, registration_id) 
	select concat(r.imie, ' ', r.nazwisko), r.registration_id 
	from registration r where r.payment is true order by r.registration_date 
	asc limit limit_number;
$_$;

select make_participants(300);

---------------------------------------------------------------------------------------

create or replace FUNCTION user_login(login_email e_mail, login_password text) RETURNS int4 
    LANGUAGE plpgsql
    AS $_$ begin
    if not exists(
    	select lt.participant_id from login_table lt 
    	where lt.e_mail = login_email and lt.user_password = crypt(login_password, lt.user_password)
    ) then raise exception 'Login or password is wrong!';
   end if;
   	 return (select lt.participant_id from login_table lt 
   	where lt.e_mail = login_email and lt.user_password = crypt(login_password, lt.user_password));
    end;
   	$_$;

create or replace FUNCTION create_user_login(login_email e_mail, login_password text) RETURNS void 
    LANGUAGE plpgsql
    AS $_$ begin
    if not exists(
    	select p.participant_id from participant p inner join
    	registration r on r.registration_id = p.registration_id 
    	where r."e_mail" =login_email
    ) then raise exception 'User cannot be created!';
   end if;
  	INSERT 
		INTO login_table 
		(
		"e_mail", user_password, participant_id
		) 
		VALUES 
		  (
		login_email,
		login_password,
		(select p.participant_id from participant p inner join
		registration r on r.registration_id = p.registration_id 
		where r."e_mail" =login_email)
		);
	raise notice 'User created!';
    end;
$_$;


select create_user_login('bobc@xc.sds', 'strongPassword');
select create_user_login('will.shak@xc.sd', 'evenStrongerPassword');
select create_user_login('afdbbqmer@xc.sd', 'evenStrongerPassword');
select create_user_login('jlasdu.wqeqeq@xyz.com', '12345');
select create_user_login('jknvd.poisdf@xyz.com', 'zxvklasdwe');
select create_user_login('name@dsad.cxz', 'veryStrongPassword123');


--checking if login works
select user_login('afdbbqmer@xc.sd', 'evenStrongerPassword');
select user_login('will.shak@xc.sd', 'evenStrongerPassword');

-- test for login or creating with wrong email
select create_user_login('test@sd.zxc', 'strongPassword');

---------------------------------------------------------------------------------------------

INSERT 
INTO squads 
(
squad_name
) 
VALUES 
  (
'squad1'
);

INSERT 
INTO squads 
(
squad_name
) 
VALUES 
  (
'squad2'
);

INSERT 
INTO squads 
(
squad_name
) 
VALUES 
  (
'squad3'
);

INSERT 
INTO squads 
(
squad_name
) 
VALUES 
  (
'squad4'
);

INSERT 
INTO squads 
(
squad_name
) 
VALUES 
  (
'squad5'
);

-----------------------------------------------------------------------------------------

INSERT 
INTO dbproject.partners
(
partner_name, partner_web_page
) 
VALUES 
  (
'partner1', 'partner1.com'
);

INSERT 
INTO dbproject.partners
(
partner_name, partner_web_page
) 
VALUES 
  (
'partner2', 'partner2.com'
);

INSERT 
INTO dbproject.partners
(
partner_name, partner_web_page
) 
VALUES 
  (
'partner3', 'partner3.com'
);

INSERT 
INTO dbproject.partners
(
partner_name, partner_web_page
) 
VALUES 
  (
'partner4', 'partner4.com'
);

INSERT 
INTO dbproject.partners
(
partner_name, partner_web_page
) 
VALUES 
  (
'partner5', 'partner5.com'
);

INSERT 
INTO dbproject.partners
(
partner_name, partner_web_page
) 
VALUES 
  (
'partner6', 'partner6.com'
);

----------------------------------------------------------------------------------

INSERT 
INTO dbproject.places
(
place_name, place_geopoint, place_address, place_photo
) 
VALUES 
  (
'place1', '1.0, 1.0', 'place_adress1', 'place_photo1'
);

INSERT 
INTO dbproject.places
(
place_name, place_geopoint, place_address, place_photo
) 
VALUES 
  (
'place2', '2.0, 2.0', 'place_adress2', 'place_photo2'
);

INSERT 
INTO dbproject.places
(
place_name, place_geopoint, place_address, place_photo
) 
VALUES 
  (
'place3', '3.0, 3.0', 'place_adress3', 'place_photo3'
);

INSERT 
INTO dbproject.places
(
place_name, place_geopoint, place_address, place_photo
) 
VALUES 
  (
'place4', '4.0, 4.0', 'place_adress4', 'place_photo4'
);

INSERT 
INTO dbproject.places
(
place_name, place_geopoint, place_address, place_photo
) 
VALUES 
  (
'place5', '5.0, 5.0', 'place_adress5', 'place_photo5'
);

INSERT 
INTO dbproject.places
(
place_name, place_geopoint, place_address, place_photo
) 
VALUES 
  (
'place6', '6.0, 6.0', 'place_adress6', 'place_photo6'
);

------------------------------------------------------------------------------------------

INSERT 
INTO dbproject.schedule
(
schedule_title, schedule_description, schedule_start_date, schedule_end_date, place_id
) 
VALUES 
  (
'schedule_title1', 'have fun etc', '2024-07-08 12:30:00', '2024-07-08 13:30:00', 1
);

INSERT 
INTO dbproject.schedule
(
schedule_title, schedule_description, schedule_start_date, schedule_end_date, place_id
) 
VALUES 
  (
'schedule_title2', 'have fun etc', '2024-07-08 13:30:00', '2024-07-08 14:30:00', 2
),
  (
'schedule_title3', 'have fun etc', '2024-07-08 14:30:00', '2024-07-08 15:30:00', 1
),
  (
'schedule_title4', 'have fun etc', '2024-07-08 15:30:00', '2024-07-08 16:30:00', 4
),
  (
'schedule_title5', 'have fun etc', '2024-07-08 16:30:00', '2024-07-08 17:30:00', 1
),
  (
'schedule_title6', 'have fun etc', '2024-07-08 17:30:00', '2024-07-08 18:30:00', 1
);

INSERT 
INTO dbproject.schedule
(
schedule_title, schedule_description, schedule_start_date, schedule_end_date, place_id
) 
VALUES 
  (
'schedule_title7', 'have fun etc', '2024-07-09 12:30:00', '2024-07-09 13:30:00', 1
),
  (
'schedule_title8', 'have fun etc', '2024-07-09 14:30:00', '2024-07-09 15:30:00', 1
),
  (
'schedule_title9', 'have fun etc', '2024-07-09 15:30:00', '2024-07-09 16:30:00', 4
),
  (
'schedule_title10', 'have fun etc', '2024-07-09 16:30:00', '2024-07-09 17:30:00', 1
),
  (
'schedule_title11', 'have fun etc', '2024-07-09 17:30:00', '2024-07-09 18:30:00', 1
);

INSERT 
INTO dbproject.schedule
(
schedule_title, schedule_description, schedule_start_date, schedule_end_date, place_id
) 
VALUES 
  (
'schedule_title12', 'have fun etc', '2024-07-09 18:30:00', '2024-07-09 19:30:00', 5
);

----------------------------------------------------------------------------------------
INSERT 
INTO dbproject.workshop
(
participant_limit, workshop_leader_id
) 
VALUES 
  (
	10,
	(select p.participant_id from dbproject.participant p where p.participant_name='jlafsdaf zxcvmkm')
),
  (
	15,
	(select p.participant_id from dbproject.participant p where p.participant_name='kljzxlc iopiaer')

),
  (
	15,
	(select p.participant_id from dbproject.participant p where p.participant_name='sdfas qewrre')

),
  (
	50,
	(select p.participant_id from dbproject.participant p where p.participant_name='jlafsdaf zxcvmkm')

),
  (
	15,
	(select p.participant_id from dbproject.participant p where p.participant_name='Bob Cage')

),
(
	10,
	(select p.participant_id from dbproject.participant p where p.participant_name='William Shakespeare')

)
;

INSERT 
INTO dbproject.workshop
(
participant_limit, workshop_leader_id
) 
VALUES 
  (
	11,
	(select p.participant_id from dbproject.participant p where p.participant_name='jlafsdaf zxcvmkm')
);

------------------------------------------------------------------------------------------

INSERT 
INTO dbproject.workshop_in_schedule
(
workshop_id, schedule_id
) 
VALUES 
  (
  	(select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='kljzxlc iopiaer'),
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title1')
),
  (
  	(select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='jlafsdaf zxcvmkm'),
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title2')
),
  (
  	(select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='sdfas qewrre'),
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title3')
),
  (
  	(select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='jlafsdaf zxcvmkm'),
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title4')
),
  (
  	(select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='Bob Cage'),
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title5')  
),
(
  	(select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='William Shakespeare'),
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title6')  
);

---------------------------------------------------------------------------

INSERT 
INTO dbproject.workshop_participants
(
participant_id, workshop_id
) 
VALUES 
  (
	(select p.participant_id from dbproject.participant p where p.participant_name='sdfas qewrre'),
    (select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='kljzxlc iopiaer')
);
-- because users will be adding themselfs to the workshop using their id, this shows how it works
INSERT 
INTO dbproject.workshop_participants
(
participant_id, workshop_id
) 
VALUES 
  (
	2,
    (select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='jlafsdaf zxcvmkm')
),
(
	3,
	(select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='sdfas qewrre')
),
(
	4,
	(select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='jlafsdaf zxcvmkm')
),
(
	3,
	(select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='William Shakespeare')
),
(
	5,
	(select w.workshop_id from dbproject.workshop w inner join dbproject.participant p on p.participant_id = w.workshop_leader_id where p.participant_name='Bob Cage')
);

--------------------------------------------------------------------------
-- firstly we create night game (id + limit) then we connect them to schedule and in most cases there is only one night game at the event
INSERT 
INTO dbproject.night_game
(
teams_limit
) 
VALUES 
  (
	10
),
(
	15
),
(
	5
),
(
	8
),
(
	7
),
(
	9
);

------------------------------------------------------------------
-- admin will be connecting this two and as I said previously mostly there will be one night game
INSERT 
INTO dbproject.night_game_in_schedule 
(
schedule_id, night_game_id
) 
VALUES 
  (
  	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title7'),
  	1
),
(
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title8'),
	2
),
(
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title9'),
	3
),
(
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title10'),
	4
),
(
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title11'),
	5
),
(
	(select s.schedule_id from dbproject.schedule s where s.schedule_title='schedule_title12'),
	6
);

-------------------------------------------------------------

INSERT 
INTO dbproject.game_teams  
(
game_team_name
) 
VALUES 
  (
	'team1'
),
(
	'team2'
),
(
	'team3'
),
(
	'team4'
),
(
	'team5'
),
(
	'team6'
);

-----------------------------------------------------------------------------------
-- participants will be adding themself to teams by participant_id so this correctly simulates usage
INSERT 
INTO dbproject.participant_in_game_team  
(
participant_id, game_team_id
) 
VALUES 
  (
  	1,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team1' )
),
(
  	2,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team1' )
),
(
  	3,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team1' )
),
(
  	4,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team1' )
),
(
  	5,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team1' )
),
(
  	6,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team1' )
);

-------------------------------------------------------------------------------

INSERT 
INTO dbproject.game_team_in_night_game  
(
night_game_id, game_team_id
) 
VALUES 
  (
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team1' )
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team2' )
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team3' )
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team4' )
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team5' )
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team6' )
);

-- checking if trigger constrain works 
INSERT 
INTO dbproject.game_team_in_night_game  
(
night_game_id, game_team_id
) 
VALUES 
  (
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title9'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team1' )
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title9'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team2' )
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title9'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team3' )
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title9'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team4' )
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title9'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team5' )
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title9'),
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team6' )
);

----------------------------------------------------------------------------------------------------------

INSERT 
INTO dbproject.night_game_stations  
(
night_game_id, station_title, station_desc
) 
VALUES 
  (
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	'station1',
	'station1_desc'
  	),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	'station2',
	'station2_desc'
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	'station3',
	'station3_desc'
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	'station4',
	'station4_desc'
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	'station5',
	'station5_desc'
),
(
  	(select ng.night_game_id from dbproject.night_game ng inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'),
	'station6',
	'station6_desc'
);

-------------------------------------------------------------------------------------
-- users will be adding those points so the system will be know station_guardian_id
INSERT 
INTO dbproject.point_team_station_night_game 
(
station_id, station_guardian_id, team_id, normal_points, extra_points
) 
VALUES 
  (
  	(select ngst.station_id from dbproject.night_game_stations ngst inner join dbproject.night_game ng on ngst.night_game_id = ng.night_game_id inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7' and ngst.station_title = 'station1'),
	4,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team1' ),
	5, 
	3
),
(
  	(select ngst.station_id from dbproject.night_game_stations ngst inner join dbproject.night_game ng on ngst.night_game_id = ng.night_game_id inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'and ngst.station_title = 'station1'),
	4,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team2' ),
	5, 
	3
),
(
  	(select ngst.station_id from dbproject.night_game_stations ngst inner join dbproject.night_game ng on ngst.night_game_id = ng.night_game_id inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'and ngst.station_title = 'station1'),
	4,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team3' ),
	8, 
	2
),
(
  	(select ngst.station_id from dbproject.night_game_stations ngst inner join dbproject.night_game ng on ngst.night_game_id = ng.night_game_id inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'and ngst.station_title = 'station1'),
	4,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team4' ),
	2, 
	1
),
(
  	(select ngst.station_id from dbproject.night_game_stations ngst inner join dbproject.night_game ng on ngst.night_game_id = ng.night_game_id inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'and ngst.station_title = 'station1'),
	4,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team5' ),
	9, 
	1
),
(
  	(select ngst.station_id from dbproject.night_game_stations ngst inner join dbproject.night_game ng on ngst.night_game_id = ng.night_game_id inner join night_game_in_schedule ngs on ngs.night_game_id = ng.night_game_id inner join schedule s on s.schedule_id = ngs.schedule_id where s.schedule_title = 'schedule_title7'and ngst.station_title = 'station1'),
	4,
	(select gt.game_team_id from dbproject.game_teams gt where gt.game_team_name = 'team6' ),
	10, 
	5
);

--------------------------------------------------------
create or replace FUNCTION update_data(id_of_participant int, col_name text, value_to_change anyelement) RETURNS void 
    LANGUAGE plpgsql
    AS $_$ begin
    if not exists(
    	select p.participant_id from dbproject.participant p where p.participant_id =id_of_participant
    ) then raise exception 'User doesnt exist!';
   end if;
  	execute format('update dbproject.participant set %I = $1 where participant_id = $2', col_name)
  	using value_to_change, id_of_participant;
	raise notice 'User created!';
	end;
$_$;

select update_data(1, 'participant_type', CAST ('staff' AS participant_types));
select update_data(1, 'squad_id', 2);


---------------------------------------------------------------------------
create or replace view allData as
select r.imie, r.nazwisko, r.pesel, r."e_mail", r.birthday, r.phone_number, r.address,
p.participant_type, s.schedule_title, s.schedule_description, s.schedule_start_date, s.schedule_end_date,
pl.place_name, pl.place_geopoint, pl.place_address from dbproject.registration r 
inner join dbproject.participant p on r.registration_id = p.registration_id
inner join dbproject.workshop w on w.workshop_leader_id = p.participant_id
inner join dbproject.workshop_in_schedule wis on wis.workshop_id = w.workshop_id
inner join dbproject.schedule s on s.schedule_id = wis.schedule_id
inner join dbproject.places pl on s.place_id = pl.place_id ;

select * from allData;

---------------------------------------------------------------------------
CREATE ROLE U880 WITH LOGIN;
GRANT CONNECT ON DATABASE postgres TO U880;
GRANT USAGE ON SCHEMA dbproject TO U880;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA dbproject FROM U880;
GRANT select, update, insert ON ALL TABLES IN SCHEMA dbproject TO U880;

CREATE ROLE DBAdmin WITH LOGIN;
GRANT CONNECT ON DATABASE postgres TO DBAdmin;
GRANT USAGE ON SCHEMA dbproject TO DBAdmin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dbproject TO DBAdmin;

CREATE ROLE Manager WITH LOGIN;
GRANT CONNECT ON DATABASE postgres TO Manager;
GRANT USAGE ON SCHEMA dbproject TO Manager;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA dbproject FROM Manager;
GRANT select ON ALL TABLES IN SCHEMA dbproject TO Manager;


