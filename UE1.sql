--TEIL1
insert into land select * from flughafenbase.land;

insert into ort select * from flughafenbase.ort;

insert into person select * from flughafenbase.person;

insert into reisepass select * from flughafenbase.reisepass;

insert into gehaltsstufe select * from flughafenbase.gehaltsstufe;

insert into personal select * from flughafenbase.personal;

insert into dienstrang select * from flughafenbase.dienstrang;

insert into flugpersonal select * from flughafenbase.flugpersonal;

insert into abteilung select * from flughafenbase.abteilung;

insert into bodenpersonal select * from flughafenbase.bodenpersonal;

insert into flughafen select * from flughafenbase.flughafen;

insert into gate select * from flughafenbase.gate;

insert into flugzeugtyp select * from flughafenbase.flugzeugtyp;

insert into fluglinie select * from flughafenbase.fluglinie;

insert into flugzeug select * from flughafenbase.flugzeug;

insert into flug select * from flughafenbase.flug;

insert into crew select * from flughafenbase.crew;

insert into passagierliste select * from flughafenbase.passagierliste;

insert into gepaeck select * from flughafenbase.gepaeck;

--TEIL 2
--Geben Sie jenes Flugzeug aus, dessen gesamte Flugstunden am weitesten
--vom Durchschnittswert über alle Flugzeuge abweicht  

select flugzeugid,abs(flugstunden_gesamt-average) max_diff 
  from flugzeug, (
    select avg(flugstunden_gesamt) average 
    from flugzeug
    )
  where abs(flugstunden_gesamt-average) >= (
    select max(abs(flugstunden_gesamt-average)) 
    from flugzeug, (
      select avg(flugstunden_gesamt) average 
      from flugzeug)
      );
--die Max() Funktion muss man als Condition angeben, und damit die flugid bekommen

--Sortieren Sie die Personen nach ihrem Nachnamen und geben sie aus dieser
--sortierten Tabelle jede 2. Person aus.

select nachname,vorname,personid 
  from (
    select rownum zeilenr,personid,vorname,nachname,geburtsdatum
    from (
      select *
      from person
      order by nachname
      )
  ) p
where mod(p.zeilenr,2) = 0;
--zweites subselect damit Zeilennr bei 1 anfängt und mit Nachnamen übereinstimmt 

--Geben Sie jene Personen und Ihr Monatsgehalt aus, die mehr verdienen als
--Nikolaus Luttkus. Lösen Sie dies mit einem Subselect.

select vorname,nachname,monatsgehalt from person 
  join personal using (personid) 
  join gehaltsstufe using (gehaltsstufeid)
  where monatsgehalt > (
    select monatsgehalt 
    from person 
    join personal using (personid) 
    join gehaltsstufe using (gehaltsstufeid)
    where vorname like 'Nikolaus' and nachname like 'Luttkus');
  
--Geben Sie alle Personen aus, die älter sind als das Durchschnittsalter ihrer
--Nationalitätsangehörigen.

select vorname,nachname,trunc((sysdate-geburtsdatum)/365) "ALTER"
from person
join reisepass R1 using (personid)
where trunc((sysdate-geburtsdatum)/365) > (
  select avg((sysdate-geburtsdatum)/365)
  from person
  join reisepass R2 using (personid)
  where R1.landid = R2.landid
  group by landid
  );
--trunc statt round, weil Alter immer abgerundet wird
  
--Geben Sie an, wie viel Geld pro Jahr dem Flugpersonal und wie viel dem
--Bodenpersonal bezahlt wird. Beachten Sie, dass alle Mitarbeiter 14
--Monatsgehälter bekommen abgesehen von: (Piloten 15 Gehälter,
--Gepäckcrew 12 Gehälter).

select Bodenpersonal+Gepäckscrew Bodenpersonal_gesamt,Flugpersonal+Pilot Flugpersonal_gesamt, 
  Bodenpersonal+Gepäckscrew+Flugpersonal+Pilot Personal_gesamt
from (
  select sum(monatsgehalt*14) Bodenpersonal
  from personal
  join bodenpersonal using (personid)
  left join gehaltsstufe using (gehaltsstufeid)
  where abteilungsid <> (
    select abteilungsid 
    from abteilung 
    where bezeichnung like 'Gepäck%'
    )
),(
  select sum(monatsgehalt*12) Gepäckscrew
  from personal
  join bodenpersonal using (personid)
  left join gehaltsstufe using (gehaltsstufeid)
  where abteilungsid = (
    select abteilungsid 
    from abteilung 
    where bezeichnung like 'Gepäck%'
    )
),(
  select sum(monatsgehalt*14) Flugpersonal
  from personal
  join flugpersonal using (personid)
  left join gehaltsstufe using (gehaltsstufeid)
  where dienstrangid not in (
    select dienstrangid 
    from dienstrang 
    where UPPER(bezeichnung) like '%PILOT%'
    )
),(
  select sum(monatsgehalt*15) Pilot
  from personal
  join flugpersonal using (personid)
  left join gehaltsstufe using (gehaltsstufeid)
  where dienstrangid in (
    select dienstrangid 
    from dienstrang 
    where UPPER(bezeichnung) like '%PILOT%'
    )
);
--aufpassen auf %Pilot% - case sensitive!

--Geben Sie eine Liste aller Passagiere aus, die entweder auf dem Flughafen
--„Palma de Mallorca“ oder aber in „Barcelona“ gelandet sind. Keinesfalls aber
--auf beiden.

select personid,vorname,nachname 
from passagierliste
left join person using (personid)
right join (
  select * 
  from flug 
  where flughafen_destination = (
    select flughafenid 
    from flughafen 
    where bezeichnung like 'Palma%'
  ) 
  or flughafen_destination = (
    select flughafenid 
    from flughafen 
    where bezeichnung like 'Barcelona'
    )
  ) using (flugid);
--normale joins, aufpassen auf Like Syntax und OR-Operator Syntax
