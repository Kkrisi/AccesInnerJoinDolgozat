
-- rendel�sek teljes�t�se A verzi�ban:
-- a rendel�s �sszes t�tel�t egy csomagban k�ldik ki, ha mindenb�l van el�g a k�szleten
-- a csomag t�telei teh�t a rendel�s azon sorai, ahol a csomag ki van t�ltve 
-- (a konkr�t becsomagolt cikkek a rend_t�telben vannak, amelyeknek a rend.sz�m�hoz kit�lt�tt csomag tart.)
-- persze t�bb rendel�s�nek a t�teleit is megkaphatja a vev� 1 csomagban
-- a cikkekb�l n dobozzal lehet rendelni a vev�knek (itt nincs m�rt�kegys�g)

create database csomagkuldoA
go

use csomagkuldoA

-- adatt�bl�k �s kapcsolataik a mez�kre vonatk. egyszer� korl�toz�sokkal (check felt�tel)

create table cikk
(
cikksz�m char(10),
elnev varchar(30) not null,
akt_k�szlet smallint check (akt_k�szlet>=0), 
egys_�r money check (egys_�r>0),
primary key (cikksz�m)
)

CREATE TABLE vev�
(
vk�d int,
n�v varchar(20) not null,
c�m varchar(40) not null,
tel int
PRIMARY KEY (vk�d)
)

create table csomag
(
csomag char(12),
feladva date,
primary key (csomag)
)

create table rendel�s
(
rend_sz�m char(12),
kelt date not null, 
vk�d int not null, 
csomag char(12),
primary key (rend_sz�m)
)

create table rend_t�tel
(
rend_sz�m char(12),
cikksz�m char(10),
menny smallint not null check (menny>0),
primary key (rend_sz�m, cikksz�m)
)

alter table rendel�s
add foreign key (vk�d) references Vev� (vk�d)

alter table rendel�s
add foreign key (csomag) references Csomag (csomag)

alter table rend_t�tel
add foreign key (rend_sz�m) references Rendel�s (rend_sz�m)

alter table rend_t�tel
add foreign key (cikksz�m) references Cikk (cikksz�m)


--- tesztadatok

insert into cikk values 
('c0001', '�s�', 17, 1000),
('c0002', 'locsol�', 196, 1200),
('c0003', 'szalmakalap', 0, 2000),
('c11', 's�rol�', 118, 780),
('c12', 'konyhai polc', 0, 3000),
('c13', 'nyug�gy', 1, 5500),
('c44', 'naperny�', 8, 2000)

insert into vev� values 
(1, '�', 'P�cs...', null),
(5, 'M�s', 'Budapest...', null),
(23, 'Valaki', 'Budapest...', null),
(55, 'Kov�cs...', 'P�cs...', null),
(56, 'Szab�...', 'Szeged...', null)

insert into csomag values 
('cs55', '20080522'),
('cs66', '20080522'),
('cs79', '20080528')

insert into rendel�s values 
('2008/001', '20080423', 5, 'cs55'),
('2008/002', '20080423', 1, 'cs66'),
('2008/123', '20080412', 55, null),
('2008/129', '20080414', 55, null),
('2008/321', '20080514', 5, 'cs55'),
('2008/456', '20080514', 55, null),
('2008/457', '20080514', 56, null),
('2008/601', '20080311', 5, null),
('2008/777', '20080411', 55, 'cs79'),
('2008/779', '20080527', 55, 'cs79')


insert into rend_t�tel values 
('2008/001', 'c0001', 2),
('2008/001', 'c0002', 3),
('2008/002', 'c0002', 1),
('2008/002', 'c0003', 5),
('2008/123', 'c11', 2),
('2008/123', 'c12', 1),
('2008/129', 'c13', 2),
('2008/321', 'c12', 1),
('2008/456', 'c44', 1),
('2008/457', 'c44', 1),
('2008/601', 'c0001', 1),
('2008/601', 'c11', 5),
('2008/777', 'c13', 2),
('2008/777', 'c44', 1),
('2008/779', 'c13', 2),
('2008/779', 'c44', 1)



--select * from cikk
--select * from vev�
--select * from csomag
--select * from rendel�s
--select * from rend_t�tel


-- Melyik teljes�tetlen rendel�s csomagolhat� az akt. k�szletek alapj�n?

-- melynek minden t�tel�b�l van el�g, azaz nincs azok k�z�tt, amelynek el�fordul legal�bb egy, kev�s k�szlettel rendelkez� t�tele:

SELECT *
FROM rendel�s
WHERE csomag is null
and rend_sz�m NOT IN (
	SELECT rt.rend_sz�m 
	from rendel�s r, rend_t�tel rt, cikk c
	where csomag is null
	and r.rend_sz�m=rt.rend_sz�m and c.cikksz�m=rt.cikksz�m
	and menny>akt_k�szlet);

-- vagy
SELECT *
FROM rendel�s
WHERE csomag is null
and rend_sz�m NOT IN (
	SELECT rt.rend_sz�m 
	from rendel�s r 
		inner join rend_t�tel rt on r.rend_sz�m=rt.rend_sz�m
		inner join cikk c on c.cikksz�m=rt.cikksz�m
	where csomag is null
	and menny>akt_k�szlet);

-- vagy
SELECT *
FROM rendel�s K
WHERE csomag is null
and NOT EXISTS (
	SELECT rt.rend_sz�m 
	from rendel�s r 
		inner join rend_t�tel rt on r.rend_sz�m=rt.rend_sz�m
		inner join cikk c on c.cikksz�m=rt.cikksz�m
	where csomag is null
	and menny>akt_k�szlet
	and rt.rend_sz�m=K.rend_sz�m);

-- figyelem: ett�l m�g nem cs�kkentek az akt_k�szletek (ahhoz trigger kell, ill. egy szab�lyozott �gymenet)
-- ezen E-t�bla kelt szerinti rendez�se pl. seg�ti a teljes�t�s menet�t (de ez nem dinamikus lista, vagyis minden csomagol�s ut�n �jra futtatand�)

-- Ellen�rizz�k, el�fordult-e olyan csomag, amely nem egyetlen vev� rendel�si t�teleit tartalmazta!

select csomag, count(distinct vk�d) as ennyi_vev�nek --, count(vk�d) as val�j�ban_ennyi_rendt�telt
from rendel�s
where csomag is not null
group by csomag
having count(distinct vk�d)>1

-- Annak ut�lagos ellen�rz�se, h a csomagol�s pillanat�ban elegek voltak_e a k�szletek, nem egyszer�, 
-- de a nyit�k�szletek �s a beszerz�sek k�l�n t�bl�ban vezetett nyt. n�lk�l nem is lenne megoldhat�.



-- Mennyi naperny�t rendeltek eddig �s mennyit sz�ll�tottak m�r ki?

select sum(menny), '�ssz_rend' as megj
from rend_t�tel rt inner join cikk c on rt.cikksz�m=c.cikksz�m
where elnev like '%naperny�%'
UNION
select sum(menny), '�ssz_sz�ll'
from rend_t�tel rt inner join cikk c on rt.cikksz�m=c.cikksz�m inner join rendel�s r on rt.rend_sz�m=r.rend_sz�m
where elnev like '%naperny�%' and csomag is not null

-- esetleg 

select sum(menny) as �ssz_rend
	, (select sum(menny) 
		from rend_t�tel szt 
		inner join rendel�s r on szt.rend_sz�m=r.rend_sz�m and csomag is not null
		inner join cikk on cikk.cikksz�m=szt.cikksz�m and elnev like '%naperny�%' ) as �ssz_sz�ll
from rend_t�tel rt inner join cikk c on rt.cikksz�m=c.cikksz�m
where elnev like '%naperny�%'


-- H�ny nap alatt teljes�tett�k az egyes rendel�seket? 

select r. rend_sz�m, datediff(day, kelt, feladva) as nap_m�lva
-- select feladva-kelt
from rendel�s r inner join csomag cs on r.csomag=cs.csomag
-- a csomag t�rzzsel val� bels� �kapcsol�skor elt�nnek az �rva gyerek-sorok (itt rendel�s-sorok)




