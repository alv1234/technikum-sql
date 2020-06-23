set serveroutput on;
--1.) Gegeben sei das folgendes Select-Statement: 
--Select * from person where lower(nachname) = nname;
--Schreiben Sie eine PL/SQL Prozedur mit einem Parameter nname (Nachname
--einer Person), welche das Ergebnis des Select-Statements ausdruckt (mit
--PUT_LINE). Verwenden Sie aber keinen Cursor (im Falle, dass es mehrere
--Ergebnisse zu einem Nachnamen gibt). Reagieren Sie stattdessen auf alle
--möglichen Fehler, die auftreten können und verwenden Sie diesmal explizites
--Exception Handling. Finden Sie eine Situation (nach Ihrer Wahl) für welche
--Sie einen eigenen Fehler (unter Verwendung von RAISE) definieren. Leiten
--Sie auch alle Fehler (mit entsprechender Fehlernummer und Meldung) nach
--außen weiter. Erklären Sie weiters, wann RAISE_APPLICATION_ERROR
--verwendet werden kann.

CREATE OR REPLACE PROCEDURE print_name (
  nname person.nachname%type
)
AS
  v_pid person.personid%type;
  v_vname person.vorname%type;
  v_nname person.nachname%type;
  v_geb person.geburtsdatum%type;
  exc_uppercase EXCEPTION;
  exc_empty EXCEPTION;
BEGIN
  IF REGEXP_LIKE (nname, '[A-Z]+') THEN
    RAISE exc_uppercase;
  ELSIF nname like ' ' THEN
    RAISE exc_empty;
  ELSE
    SELECT *
    INTO v_pid,v_vname,v_nname,v_geb
    FROM person
    WHERE LOWER(nachname) = nname;
    DBMS_OUTPUT.PUT_LINE(v_pid || ' ' || v_vname ||  ' ' || v_nname ||  ' ' || v_geb);
  END IF;
  
EXCEPTION
  WHEN exc_uppercase THEN
    DBMS_OUTPUT.PUT_LINE('Parameter enthält Großbuchstaben!');
  WHEN exc_empty THEN
    DBMS_OUTPUT.PUT_LINE('Parameter ist leer!');
  WHEN too_many_rows THEN
    DBMS_OUTPUT.PUT_LINE('Es gibt mehr als einen Eintrag mit diesem Nachnamen!');
    DBMS_OUTPUT.PUT_LINE('ORA' || SQLCODE || ': exact fetch returns more than requested number of rows');
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Es gibt keinen Eintrag mit diesem Nachnamen!');
    DBMS_OUTPUT.PUT_LINE('ORA' || SQLCODE || ': no data found');
  WHEN others THEN
    DBMS_OUTPUT.PUT_LINE('Unbekannter Fehler!');
    DBMS_OUTPUT.PUT_LINE('ORA' || SQLCODE || ': OTHER ERROR');
END;
/

exec print_name(' ');
exec print_name('Wahl');
exec print_name('bauer');
exec print_name('casd');
exec print_name('wahl');

-- The procedure RAISE_APPLICATION_ERROR lets you issue user-defined ORA- error messages 
--from stored subprograms. That way, you can report errors to your application and avoid returning unhandled exceptions.
-- To call RAISE_APPLICATION_ERROR, use the syntax
-- raise_application_error(
--       error_number, message[, {TRUE | FALSE}]);
-- where error_number is a negative integer in the range -20000 .. -20999 and message is a character string up to 
--2048 bytes long. If the optional third parameter is TRUE, the error is placed on the stack of previous errors. 
--If the parameter is FALSE (the default), the error replaces all previous errors. RAISE_APPLICATION_ERROR is part 
--of package DBMS_STANDARD, and as with package STANDARD, you do not need to qualify references to it.
-- An application can call raise_application_error only from an executing stored subprogram (or method). 
--When called, raise_application_error ends the subprogram and returns a user-defined error number and message 
--to the application. The error number and message can be trapped like any Oracle error.

--2.) Schreiben Sie eine PL/SQL Prozedur, welche hintereinander (z.B. durch explizite Angabe von personIDs) 
--Personen aus der Passagierliste löscht. Zumindest 2 delete Statements hintereinander sollen funktionieren, 
--ein weiteres delete Statement gibt einen Fehler zurück (z.B. durch Angabe einer personID, welche nicht existiert). 
--Reagieren Sie auf den Fehler im Exception- Bereich, geben Sie eine entsprechende Fehlermeldung aus und machen Sie 
--alle vorhergehenden Deletes rückgängig.
CREATE OR REPLACE PROCEDURE passagier_loeschen(
  pid1 passagierliste.personID%type,
  pid2 passagierliste.personID%type,
  pid3 passagierliste.personID%type
) 
IS
  v_result passagierliste%rowtype;
BEGIN
  SAVEPOINT startProc;
--überprüfen, ob es die personids überhaupt gibt  
  SELECT * 
    INTO v_result 
    FROM passagierliste 
    WHERE personid = pid1
    AND ROWNUM = 1;
  SELECT * 
    INTO v_result 
    FROM passagierliste 
    WHERE personid = pid2
    AND ROWNUM = 1;
  SELECT * 
    INTO v_result 
    FROM passagierliste 
    WHERE personid = pid3
    AND ROWNUM = 1;
--wegen constraints muss zuerst eintrag im gepäck gelöscht werden  
  DELETE FROM gepaeck
    WHERE personid = pid1;
  DELETE FROM gepaeck
    WHERE personid = pid2;
  DELETE FROM gepaeck
    WHERE personid = pid3;
--löschen aus passagierliste
  DELETE FROM passagierliste 
    WHERE personid = pid1;
  DELETE FROM passagierliste 
    WHERE personid = pid2;
  DELETE FROM passagierliste 
    WHERE personid = pid3;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('personID nicht vorhanden');
    ROLLBACK TO startProc;
   WHEN OTHERS THEN
    IF SQLCODE = -2292 THEN 
      DBMS_OUTPUT.PUT_LINE('Gepäck muss zuerst gelöscht werden'); 
      ROLLBACK TO startProc;
    ELSE
      DBMS_OUTPUT.PUT_LINE('Fehler!');
      ROLLBACK TO startProc;
    END IF; 
END;
/

exec passagier_loeschen(5,6,1222);

SELECT * 
    FROM passagierliste;

--3.) Erweitern Sie die Package aus Übung 4 um ein Exception Handling, wobei wirklich alle möglichen Fehler 
--in irgendeiner Form behandelt werden sollen.
CREATE OR REPLACE PACKAGE flug_admin AS
  v_flugid flug.flugid%type default 0;
  PROCEDURE list_passagiere (f gepaeck.flugid%type
                          default v_flugid);
END flug_admin;
/

CREATE OR REPLACE PACKAGE BODY flug_admin AS
  v_flugid flug.flugid%type default 0;
  
  PROCEDURE list_gepäck_detail (
    p_personid gepaeck.personid%type,
    p_flugid gepaeck.flugid%type
  )
  IS
    CURSOR c_gepäck is
      SELECT *
      FROM gepaeck
      WHERE personid = p_personid
      AND flugid = p_flugid;
    v_result c_gepäck%rowtype;
    v_cnt int;
   BEGIN
    v_cnt := 0;
    OPEN c_gepäck;
    LOOP
      FETCH c_gepäck INTO v_result;
      EXIT WHEN c_gepäck%notfound;
      v_cnt := v_cnt + 1;
      DBMS_OUTPUT.PUT_LINE('Gepäck ' || v_cnt || ': ' || v_result.gewicht || 'kg');
    END LOOP;
    CLOSE c_gepäck;
   END list_gepäck_detail;

  PROCEDURE list_passagiere (f gepaeck.flugid%type) IS
  v_flugnummer flug.flugnummer%type;
  v_counter number;
  exc_flugid_nicht_übergeben exception;
  exc_flugid_nicht_vorhanden exception;
  CURSOR c_passagierliste is
    SELECT personid,vorname,nachname,count(gepaeckid) anzahl,sum(gewicht) gewicht
    FROM gepaeck
    JOIN person using (personid)
    WHERE flugid = f
    GROUP BY vorname,nachname,personid;
  v_result c_passagierliste%rowtype;
  v_cnt int;
  
  BEGIN
    IF f IS NULL THEN
      RAISE exc_flugid_nicht_übergeben;
    END IF;
    SELECT COUNT(*)
      INTO v_counter
      FROM flug
      WHERE flugid = f;
    IF v_counter = 0 THEN
      RAISE exc_flugid_nicht_vorhanden;
    END IF;
    SELECT flugnummer
     INTO v_flugnummer
       FROM flug
       WHERE flugid = f;
      DBMS_OUTPUT.PUT_LINE('Flug: ' || v_flugnummer);
      v_cnt := 0;
      OPEN c_passagierliste;
      LOOP
        FETCH c_passagierliste INTO v_result;
        EXIT WHEN c_passagierliste%notfound;
        v_cnt := v_cnt + 1;
        DBMS_OUTPUT.PUT_LINE( v_cnt || ' ' || v_result.vorname || ' ' || v_result.nachname || ': <Gepäcksstücke: ' || v_result.anzahl || 
                              ' - Gesamtgewicht: ' || v_result.gewicht || 'kg>');
        list_gepäck_detail(v_result.personid, f);
        END LOOP;
        CLOSE c_passagierliste;
  EXCEPTION
    WHEN exc_flugid_nicht_übergeben THEN
      DBMS_OUTPUT.PUT_LINE('FlugID muss angegeben werden!');
    WHEN exc_flugid_nicht_vorhanden THEN
      DBMS_OUTPUT.PUT_LINE('Kein Flug unter dieser Nummer gefunden!'); 
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Fehler!');
      RAISE;
  END list_passagiere;
  
  FUNCTION flug
    RETURN flug.flugid%type
  AS
    exc_flugid_nicht_übergeben EXCEPTION;
   
END flug_admin;
/

exec flight_admin.list_passagiere(452);

--4.) Schreiben Sie eine PL/SQL Prozedur, welche einen ganzen Flug cancelt, so dass alle Passagiere und ihr 
--Gepäck auf einen anderen Flug umgebucht werden. Als einziger Parameter wird die flugID übergeben. Innerhalb 
--der Prozedur soll ein neuer Flug mit demselben Abflug- und Zielflughafen angelegt werden und derselbe Flugzeugtyp 
--soll verwendet werden.
CREATE OR REPLACE PROCEDURE cancel_flight (
  f flug.flugid%type
)
