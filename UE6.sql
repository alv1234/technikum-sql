SET serveroutput ON;
--1.) Schreiben Sie einen Datenbanktrigger, der - im Falle des Löschens eines Passagiers - 
--garantiert, dass auch alle Gepäckstücke des Passagiers entfernt werden.

CREATE OR REPLACE TRIGGER gepaeck_check1 
BEFORE DELETE ON passagierliste
FOR EACH ROW

BEGIN

  DELETE FROM gepaeck
  WHERE personid =  :old.personid AND flugid = :old.flugid;

END;
/
--2.) Schreiben Sie einen Datenbanktrigger, der beim Hinzufügen von Personal zu 
--einem Flug überprüft, dass nicht mehr als 1 Pilot (oder Chefpilot), 2 Copiloten und 
--6 Stewarts/Stewardessen zugeteilt sind.

drop table copy_crew;
create table copy_crew as select * from crew;
/

CREATE OR REPLACE TRIGGER crew_check
BEFORE INSERT ON copy_crew
FOR EACH ROW
DECLARE --einzige Unterschied zu Prozeduren, dass man bei Trigger Declare explizit schreiben muss

  --variablen
  v_dienstrang dienstrang.dienstrangid%type;
  v_cnt_pilot int;
  v_cnt_copilot int;
  v_cnt_bordpers int;
  
  err_pilot exception;
  err_copilot exception;
  err_bordpers exception;
BEGIN
  --check dienstrang
  SELECT dienstrangid
  INTO v_dienstrang
  FROM dienstrang
    JOIN flugpersonal USING (dienstrangid)
  WHERE personid = :new.personid;
  --count piloten oder chefpiloten
  SELECT COUNT(*)
  INTO v_cnt_pilot
  FROM crew
    JOIN flugpersonal USING (personid)
    JOIN dienstrang USING (dienstrangid)
  WHERE flugid = :new.flugid 
  AND 
  --bezeichnung IN ('Pilot','Chefpilot'); 
  (bezeichnung = 'Chefpilot' OR bezeichnung = 'Pilot'); --Klammer zum Gruppieren, weil sonst ist das AND stärker als OR
  --count copiloten
  SELECT COUNT(*)
  INTO v_cnt_copilot
  FROM crew
    JOIN flugpersonal USING (personid)
    JOIN dienstrang USING (dienstrangid)
  WHERE flugid = :new.flugid 
  AND 
  bezeichnung IN ('Co-Pilot'); 
  --count bordpersonal
  SELECT COUNT(*)
  INTO v_cnt_bordpers
  FROM crew
    JOIN flugpersonal USING (personid)
    JOIN dienstrang USING (dienstrangid)
  WHERE flugid = :new.flugid 
  AND 
  bezeichnung IN ('Bordpersonal','Trainee'); 
  --Prüfung ob einfügen
  IF v_cnt_pilot > 0 AND (v_dienstrang = 'Pilot' OR v_dienstrang= 'Chefpilot') THEN
    RAISE err_pilot;
  END IF;
  IF v_cnt_copilot > 1 AND (v_dienstrang = 'Co-Pilot') THEN
    RAISE err_copilot;
  END IF;
  IF v_cnt_bordpers > 5 AND (v_dienstrang = 'Bordpersonal' OR v_dienstrang= 'Trainee') THEN
    RAISE err_bordpers;
  END IF;
  
  EXCEPTION
    WHEN err_pilot THEN
      raise_application_error(-20001,'Es ist/sind bereits' || v_cnt_pilot || '(Chef-)Pilot(en)');
      --Syntax des Raise_application... erfordert eine Zahl unter -200000 usw.
    WHEN err_copilot THEN
      raise_application_error(-20002,'Es ist/sind bereits' || v_cnt_copilot || 'Co-Pilot(en)');
    WHEN err_bordpers THEN
      raise_application_error(-20003,'Es ist/sind bereits' || v_cnt_bordpers || 'Bordpersonal');
    WHEN OTHERS THEN
      raise_application_error(SQLCODE, Substr(SQLERRM,1,200));
END;
/

--kontrolle
insert into copy_crew values (2,3);
select * from crew;

--3.) Schreiben Sie einen Datenbanktrigger, der alle Änderungen (auch versuchte) 
--an der Passagierliste in einer extra Tabelle (muss erst angelegt werden - 
--speichert den vollen Namen des Passagiers, flugID, Timestamp) mitloggt. Das 
--Logging darf nicht durch Fehler oder zurückggesetzte Transaktionen beeinflusst werden.
--D.h. wir brauchen ein Pragma...., damit wir ein Commit machen können

drop table copy_passagierliste;
create table copy_passagierliste as select * from passagierliste;
create table logtable (
  vorname varchar2(32),
  nachname varchar2(32),
  flugid number,
  zeit timestamp,
  aktion char(1)
  );
/

CREATE OR REPLACE TRIGGER log_passagier
BEFORE INSERT OR UPDATE OR DELETE
ON copy_passagierliste
FOR EACH ROW

DECLARE
  v_ChangeType CHAR(1);
  v_vorname person.vorname%type;
  v_nachname person.nachname%type;
  
  pragma autonomous_transaction;--damit immer ausgeführt wird, egal was passiert

BEGIN
  --check action
  IF INSERTING THEN
    v_ChangeType := 'I';
    --auslesen vorname,nachname bei :new.personid
    SELECT vorname, nachname
    INTO v_vorname,v_nachname
    FROM person
      WHERE personid = :new.personid; --:new weil Insert-Trigger!
    --daten in logtable schreiben
    INSERT INTO logtable
    VALUES (v_vorname,v_nachname,:new.flugid,systimestamp,v_ChangeType);
    
  ELSIF UPDATING THEN
    v_ChangeType := 'U';
    --auslesen vorname,nachname bei :new.personid
    SELECT vorname, nachname
    INTO v_vorname,v_nachname
    FROM person
      WHERE personid = :new.personid;
    --daten in logtable schreiben
    INSERT INTO logtable
    VALUES (v_vorname,v_nachname,:new.flugid,systimestamp,v_ChangeType);

  ELSIF DELETING THEN
    v_ChangeType := 'D';
    --auslesen vorname,nachname bei :new.personid
    SELECT vorname, nachname
    INTO v_vorname,v_nachname
    FROM person
      WHERE personid = :old.personid; --:old weil Delete-Trigger!
    --daten in logtable schreiben
    INSERT INTO logtable
    VALUES (v_vorname,v_nachname,:old.flugid,systimestamp,v_ChangeType);
 
  END IF;
  
  COMMIT;
END;
/

--kontrolle:
SELECT * FROM copy_passagierliste;
SELECT * FROM logtable;

DELETE FROM copy_passagierliste
  WHERE personid = 6;

UPDATE copy_passagierliste
SET flugid = 1
WHERE personid = 1;
