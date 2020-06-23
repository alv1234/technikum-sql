set serveroutput on;
-- 1.) Schreiben Sie eine PL/SQL Prozedur mit einem Parameter (ganze Zahl v_i)
-- und mit einem Select-Statement Ihrer Wahl. Aufgabe der Prozedur ist es,
-- jeden v_i-ten Datensatz des Ergebnisse auszuschreiben. Verwenden Sie aber
-- keine rownum (wie in der ersten ‹bung), sondern einen Cursor.

create or replace procedure print_xter_flug(v_i int default 5)
  is
    cursor c_flug is select * from flug order by flugid;
    vresult c_flug%rowtype;
begin
  for vresult in c_flug
  loop
    if ( mod(c_flug%rowcount, v_i) = 0) then
      DBMS_OUTPUT.PUT_LINE(c_flug%rowcount || ' ' || vresult.flugid || ' ' || vresult.flugnummer);
    end if;
  end loop;
end;
/

exec print_xter_flug();
exec print_xter_flug(5);

-- 2.) Schreiben Sie eine PL/SQL Funktion, welche die Auslastung eines
-- angegebenen Fluges (Parameter flugID) zurück gibt. Die Auslastung
-- berechnet sich als die Prozent der bereits gebuchten Sitzpl‰tze.

create or replace function auslastung (i_flugid in flug.flugid%TYPE) 
  return number
is
  v_auslastung number;
begin
  select nvl(count(*), 0) into v_auslastung from flug where flugid = i_flugid;
  if v_auslastung = 0 then
    return -1;
  end if;
  select round((count(sitzplatznummer)/sitzplaetze * 100),2)
    into v_auslastung 
    from flug
    join flugzeug using (flugzeugid)
    join flugzeugtyp using (flugzeugtypid)
    join passagierliste using(flugid)
    where flugid = i_flugid
    group by sitzplaetze;
  return v_auslastung;
end;
/
--test
begin 
  DBMS_OUTPUT.PUT_LINE(auslastung(27));
  DBMS_OUTPUT.PUT_LINE(auslastung(38));
  DBMS_OUTPUT.PUT_LINE(auslastung(330));
end;
/
--kontrolle
select flugid, sitzplaetze gesamtsitze, count(sitzplatznummer) gebuchte_sitze, count(sitzplatznummer)/sitzplaetze * 100 Anteil_prozent
  from flug f
  join flugzeug using (flugzeugid)
  join flugzeugtyp using (flugzeugtypid)
  join passagierliste pl on f.flugid = pl.flugid
  group by sitzplaetze, flugid;
