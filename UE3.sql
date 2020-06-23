set serveroutput on;
--1: Schreiben Sie einen anonymen Block, welcher eine Variable „v_personID“ 
--deklariert, diese mit dem höchsten Eintrag der personID aus der Tabelle 
--person befüllt und ausgibt.

declare
  v_personID int;
begin
  select max(personid) into v_personID from person;
  dbms_output.put_line(v_personID);
end;
/

--2: Schreiben Sie einen anonymen Block, welcher das Verhältnis zwischen Flugpersonal 
--und Bodenpersonal ausgibt (z.B.: “flugpersonal : bodenpersonal = 10:24”). Verwenden 
--Sie dafür mindestens 2 verschiedene Select Statements.
declare
  v_flugpersonal int;
  v_bodenpersonal int;
begin
  select count(personid) 
  into v_bodenpersonal
  from bodenpersonal
  ;
  select count(personid) 
  into v_flugpersonal
  from flugpersonal
  ;
dbms_output.put_line('flugpersonal : bodenpersonal = '||v_flugpersonal||' : '||v_bodenpersonal);
end;
/

--3: Schreiben Sie eine Datenbankprozedur, welche die Daten eines Passagiers auf einem bestimmten 
--Sitzplatz eines Fluges ausgibt. Deklarieren Sie dazu mindestens die beiden Variablen v_flugnummer 
--und v_sitzplatz und weisen Sie diesen Werte zu. Ausgegeben werden sollen die Flugnummer, der Passagiername, 
--sein Sitzplatz, seine Landeszugehörigkeit (sofern vorhanden), seine Reisepassnummer und das Gesamtgewicht seines Gepäcks.
--Ist der Platz noch frei, geben Sie 0 aus. Überlegen Sie sich wo und wie es zu Fehlerfällen kommen kann 
--(z.B. mehrere Reisepassnummern).
--Überprüfen Sie auf diese Fehlerfälle und geben, wenn einer Eintritt, -1 aus. Verwenden Sie noch kein 
--explizites Exception Handling!
create or replace procedure passenger1
is 
  v_flugnr varchar2(20);
  v_sitznr int;
  v_vorname varchar2(20);
  v_nachname varchar2(20);
  v_land varchar2(20);
  v_reisepass int;
  v_gewicht int;
begin
  v_flugnr := 'AF3012';
  v_sitznr := 22;
select flugnummer,vorname,nachname,sitzplatznummer,land.bezeichnung,reisepass.reisepassnr,sum(gewicht) gewicht
into v_flugnr,v_vorname,v_nachname,v_sitznr,v_land,v_reisepass,v_gewicht
from flug
 join passagierliste using(flugid)
 join gepaeck using (flugid)
 join person on passagierliste.personid=person.personid
 join reisepass on person.personid = reisepass.personid
 join land on reisepass.landid=land.landid
 where flugnummer = v_flugnr AND sitzplatznummer = v_sitznr
 group by flugnummer,vorname,nachname,sitzplatznummer,bezeichnung,reisepassnr
;
dbms_output.put_line(v_flugnr||' vs '||v_sitznr);
end;
/

exec passenger1;

--Schreiben Sie eine Datenbankfunktion, welche die Anzahl der verschiedenen Ortsnamen 
--zurück gibt. Sollten keine Namen verfügbar sein, dann soll -1 zurück gegeben werden.
create or replace function ortsname
	return int
	is
	v_anzahl int;
begin
	select count(bezeichnung) into v_anzahl
	from ort;
if v_anzahl>0 THEN
	return v_anzahl;
else
  	return -1;
end if;
end;
/

exec ortsname;
