--1.1: Erstellen Sie eine View, welche Vorname, Nachname und Geburtsdatum
--aller Piloten (nicht Co-Piloten und Chefpiloten) anzeigt.

create view pilots
as
select vorname,nachname,geburtsdatum
  from person
  join personal using (personid)
  join flugpersonal using (personid)
  join dienstrang using (dienstrangid)
  where bezeichnung =  'Pilot';

--1.2: Erstellen Sie eine View “Personal_view”, welche für jedes Mitglied 
--aus dem Personal (personID, Vorname, Nachname, monatliches Gehalt) den Rang
--(Bezeichnung) im Falle von Flugpersonal bzw. den Abteilungsnamen (Bezeichnung)
--im Falle von Bodenpersonal angibt.
create view personal_view
as
select personid,vorname,nachname,dienstrang.bezeichnung "RANG/ABTEILUNG",monatsgehalt
  from person
  join personal using(personid)
  join gehaltsstufe using(gehaltsstufeid)
  join flugpersonal using(personid)
  join dienstrang using(dienstrangid)
union
select personid,vorname,nachname,abteilung.bezeichnung bezeichnung,monatsgehalt
  from person
  join personal using(personid)
  join gehaltsstufe using(gehaltsstufeid)
  join bodenpersonal using(personid)
  join abteilung using(abteilungsid);

--1.3: Versuchen Sie auf der View “Personal_view” 
--zu selecten, inserten, updaten, deleten. Protokollieren Sie, was passiert.
select * 
  from personal_view;
--ungewöhnlich, alles ok
insert into personal_view
  values (400,'Maximilian','Muster','Pilot',100);
--funktioniert nicht, view besteht aus joins, wo soll der Rang (dessen Spalte ja kombiniert ist) abgelegt werden?
update personal_view
  set vorname = 'Harry'
  where personid = 1;
--funktioniert nicht, "not legal on this view"
delete from personal_view
  where personid = 1;
--funktioniert nicht, "not legal on this view"

--1.4: Welche Indexes müssen gesetzt werden (auf den Originaltabellen !!!) um die 
--Performance möglichst weit zu erhöhen. Geben Sie SQL-Anweisungen zum Erstellen der 
--Indexes an und geben Sie Argumente für jeden Index an.

SELECT *
         FROM personal_view
         WHERE monatsgehalt > 3000 AND
               "RANG/ABTEILUNG"='Chefpilot' AND
               UPPER(nachname) < 'G'
         ORDER BY nachname, vorname;
         
--in der View hat die Spalte Nachname bestimmt am meisten verschiedene Einträge, 
--würde Sinn machen hier Index zu setzen. query time: 0.05s-0.06s before indexing vs 0.03s-0.04s after indexing
create index idx_nachname
on person(nachname);

--1.5: Im Bereich der Flüge sind eine Reihe sinnvoller Abfragen denkbar 
--(z.B. die Anzeige der aktuellen Füge an den Terminals oder Sitzplatzbuchungen etc.). 
--Überlegen Sie sich mind. 4 verschiedene Indexes, die in diesem Zusammenhang sinnvoll 
--sein könnten. Geben Sie für jeden Index eine (frei formulierte) Begründung an, warum 
--der Index Ihrer Meinung nach wichtig ist.
--idx auf Passagierliste.Sitzplatznummer: es gibt viele verschiedene Sitzplätze, würde Sinn machen
--idx auf flug.flughafen_destination: ist als FK nicht unique, hat aber viele Einträge
--idx auf flug.flughafen_abflug: ist als FK nicht unique, hat aber viele Einträge
--idx auf flug.gateid: ist FK und hat viele Einträge

--2.1: Finden Sie heraus, welche Rechte Sie mit Ihrem eigenen Account haben und 
--listen Sie diese auf (SQL-statement)
select * from USER_SYS_PRIVS;
--Privileges: no Admin rights, CREATE VIEW, CREATE SYNONYM, UNLIMITED TABLESPACE, CREATE TRIGGER

--2.2: Use 3 tables of your choice and the 2 views from part 1 (all objects from your own account). 
--Assign different rights to those database objects (just read, read and write, ...). Switch to 
--the above given user and check if everything works as planned. How can you access these tables and 
--views? Document what you do and what you observe.
--Views: personal_view(select), pilots(select); Tables: gate(select&update), reisepass(select&delete), ort(insert)

grant select on personal_view to s17dbsbb_bwi;
grant select on pilots to s17dbsbb_bwi;
grant select,update on gate to s17dbsbb_bwi;
grant select,delete on reisepass to s17dbsbb_bwi;
grant insert on ort to s17dbsbb_bwi;
--select usw. funktioniert nicht... schreibt "table or view does not exist", was Blödsinn ist (laut Database explorer)
select * from personal_view;

--2.3: Schreiben Sie ein select-Statement, das alle Tabellen auflistet, welche Sie selbst besitzen.
select * from user_tables;

--2.4: Schreiben Sie ein select-Statement, das alle Datenbankobjekte auflistet, zu denen Sie 
--Zugang haben (nicht nur solche, die Sie selbst besitzen).
select * from all_objects;

--2.5: Geben Sie für eine Tabelle Ihrer Wahl, welche Sie selbst besitzen, den Tabellennamen, die zugehörigen 
--Attribute mit ihren Namen und Datentypen, sowie eventuell bestehende Constraintnamen dazu aus.
select ucc.table_name,ucc.column_name,ucc.constraint_name,utc.data_type 
  from USER_CONS_COLUMNS ucc, USER_TAB_COLUMNS utc
  where ucc.table_name = 'PERSONAL' and
  utc.table_name = 'PERSONAL';
--Schwierigkeit besteht hier nur im joinen der versch. data dictionary objects

--2.6: Wenn Sie einen neuen User anlegen müssten (Sie haben nicht die entsprechenden 
--Rechte dazu !) mit Login-Rechten und grundlegenden Berechtigungen (hinzufügen, ändern, 
--löschen von Tabellen und Daten), welche Rechtevergabe wäre dafür notwendig?
create user userXY identified by pwd;
grant connect to userXY;
grant resource to userXY;
  
--2.7:  Sie eine größere Anzahl neuer User anlegen müssten, alle mit denselben 
--Berechtigungen, was wäre die beste Methode dazu? Welche SQL Statements sind dafür 
--notwendig? Zeigen Sie das anhand von Beispiel 6.

create role myrole;
grant connect to myrole;
grant resource to myrole;

create user user123 identified by 123;
grant myrole to user123;
--Rollenkonzept nutzen anstatt individueller Rechtevergabe

--2.8: Geben Sie für alle eigenen Tabellen und Views den Namen und die 
--Länge aus (= Summe aller DATA_LENGTH Einträge für jede Tabelle bzw. View).
select table_name, sum(DATA_LENGTH)
from USER_TAB_COLUMNS
group by table_name;

--2.9: Geben Sie alle Sequences, Synonyms, Tabellen und Views (auf 
--die Sie Zugriff haben) die Namen aus, sortiert nach Kategorie und 
--innerhalb davon nach Namen (möglicherweise sind nicht alle Kategorien vorhanden).
select * from user_objects
where object_type in ('SYNONYM','SEQUENCE','TABLE','VIEW')
order by object_type, object_name asc;
