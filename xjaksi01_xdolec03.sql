/**
 *      Databazove systemy
 *          Projekt druha cast
 *
 *      Ales Jaksik         xjaksi01
 *      Vaclav Dolecek      xdolec03
 */


------------- CISTKA -------------------------
DROP TABLE  hvezda CASCADE CONSTRAINTS;
DROP TABLE  planetarni_system CASCADE CONSTRAINTS;
DROP TABLE  obiha CASCADE CONSTRAINTS;
DROP TABLE  planeta CASCADE CONSTRAINTS;
DROP TABLE  prvky CASCADE CONSTRAINTS;
DROP TABLE  hvezda_obsahuje CASCADE CONSTRAINTS;
DROP TABLE  atmosfera CASCADE CONSTRAINTS;
DROP TABLE  osoba CASCADE CONSTRAINTS;
DROP TABLE  jedi CASCADE CONSTRAINTS;
DROP TABLE  studuje CASCADE CONSTRAINTS;
DROP TABLE  lod CASCADE CONSTRAINTS;
DROP TABLE  flotila CASCADE CONSTRAINTS;
DROP TABLE  flotila_sestava CASCADE CONSTRAINTS;
DROP SEQUENCE id_planet;
DROP MATERIALIZED VIEW pohled_systemy_a_hvezdy;


------------ TVORBA -----------------------------------------------------------
CREATE TABLE planetarni_system
(
    id_system   INT             GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    jmeno       VARCHAR(127)
);

CREATE TABLE hvezda
(
    id_hvezda   INT             GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    typ         VARCHAR(127)    NOT NULL,
    id_system   INT             NOT NULL,
    CONSTRAINT hvezda_system FOREIGN KEY (id_system)
        REFERENCES planetarni_system(id_system)
);

CREATE TABLE planeta
(
    id_planeta              INT             DEFAULT NULL PRIMARY KEY,
    jmeno                   VARCHAR(127)    NOT NULL,
    vzdalenost_od_slunce    INT             NOT NULL,
    hmotnost                INT             NOT NULL,
    pocet_obyvatel          INT             NOT NULL,
    druh                    VARCHAR(127)    NOT NULL
);

CREATE TABLE obiha
(
    id_hvezda   INT     NOT NULL,
    id_planeta  INT     NOT NULL,
    PRIMARY KEY (id_hvezda, id_planeta),
    CONSTRAINT obiha_hvezda FOREIGN KEY (id_hvezda)
        REFERENCES hvezda(id_hvezda),
    CONSTRAINT obiha_planeta FOREIGN KEY (id_planeta)
        REFERENCES planeta(id_planeta)
);

CREATE TABLE prvky
(
    id_prvku                    INT             GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    oznaceni_prvku              VARCHAR(127)    NOT NULL,
    procentualni_zastoupeni     INT             NULL
);

CREATE TABLE hvezda_obsahuje
(
    id_hvezda       INT     NOT NULL,
    id_prvku        INT     NOT NULL,
    PRIMARY KEY (id_hvezda, id_prvku),
    CONSTRAINT obsahuje_hvezda FOREIGN KEY (id_hvezda)
        REFERENCES hvezda(id_hvezda),
    CONSTRAINT obsahuje_prvku FOREIGN KEY (id_prvku)
        REFERENCES prvky(id_prvku)
);

CREATE TABLE atmosfera
(
    id_planeta      INT     NOT NULL,
    id_prvku        INT     NOT NULL,
    PRIMARY KEY (id_planeta, id_prvku),
    CONSTRAINT atmosfera_planeta FOREIGN KEY (id_planeta)
        REFERENCES planeta(id_planeta),
    CONSTRAINT atmosfera_prvku FOREIGN KEY (id_prvku)
        REFERENCES prvky(id_prvku)
);

CREATE TABLE osoba
(
    id_osoba            INT             GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    jmeno               varchar(127)    NOT NULL,
    rasa                varchar(127)    NOT NULL,
    datum_narozeni      varchar(127)    NOT NULL,
    id_planeta          INT             NOT NULL,
    CONSTRAINT osoba_pochazi FOREIGN KEY (id_planeta)
        REFERENCES planeta(id_planeta)
);

CREATE TABLE jedi
(
    id_jedi                 INT             GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    jmeno                   varchar(127)    NOT NULL,
    rasa                    varchar(127)    NOT NULL,
    datum_narozeni          varchar(127)    NOT NULL,
        CHECK ( REGEXP_LIKE(datum_narozeni, '^[0-3][0-9].[01][0-9].[0-9]+$')),
    mnozstvi_midichloriamu  INT             NOT NULL,
    barva_mece              VARCHAR(63)     NOT NULL,
    hodnost                 VARCHAR(127)    NULL,
    id_planeta              INT             NOT NULL,
    CONSTRAINT pochazi FOREIGN KEY (id_planeta)
        REFERENCES planeta(id_planeta)
);

CREATE TABLE studuje
(
    mistr       INT     NOT NULL,
    padavan     INT     NOT NULL,
    PRIMARY KEY (mistr, padavan),
    CONSTRAINT mistr_uci FOREIGN KEY (mistr)
        REFERENCES jedi(id_jedi),
    CONSTRAINT padavan_studuje FOREIGN KEY (padavan)
        REFERENCES jedi(id_jedi)
);

CREATE TABLE lod
(
    vyrobni_cislo   VARCHAR(127)    NOT NULL PRIMARY KEY,
        CHECK ( REGEXP_LIKE(vyrobni_cislo, '^([0-9]|[a-zA-Z]){4}-([0-9]|[a-zA-Z]){4}-([0-9]|[a-zA-Z]){4}-([0-9]|[a-zA-Z]){4}$')),
    trida           varchar(127)    NOT NULL,
    id_planeta      INT             NOT NULL,
    CONSTRAINT vyrobeno_na FOREIGN KEY (id_planeta)
        REFERENCES planeta(id_planeta)
);

CREATE TABLE flotila
(
    id_flotila      INT             GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    id_jedi         INT             NOT NULL,
    id_planeta      INT             NULL,
    CONSTRAINT flotile_veli FOREIGN KEY (id_jedi)
        REFERENCES jedi(id_jedi),
    CONSTRAINT flotila_se_nachazi FOREIGN KEY (id_planeta)
        REFERENCES planeta(id_planeta)
);

CREATE TABLE flotila_sestava
(
    vyrobni_cislo   VARCHAR(127)     NOT NULL,
        CHECK ( REGEXP_LIKE(vyrobni_cislo, '^([0-9]|[a-zA-Z]){4}-([0-9]|[a-zA-Z]){4}-([0-9]|[a-zA-Z]){4}-([0-9]|[a-zA-Z]){4}$')),
    id_flotila      INT              NOT NULL,
    PRIMARY KEY (vyrobni_cislo, id_flotila),
     CONSTRAINT sestava_z_lodi FOREIGN KEY (vyrobni_cislo)
        REFERENCES lod(vyrobni_cislo),
     CONSTRAINT sestava_flotila FOREIGN KEY (id_flotila)
        REFERENCES flotila(id_flotila)
);

------------ TRIGGERS ----------------------------------------------------------------

-- 1. trigger pro generování id jediho
CREATE SEQUENCE id_planet;
CREATE OR REPLACE TRIGGER id_planet
    BEFORE INSERT ON planeta
    FOR EACH ROW
BEGIN
    IF :NEW.id_planeta IS NULL THEN
        :NEW.id_planeta := id_planet.NEXTVAL;
    END IF;
END;

-- 2. trigger pro kontrulu data narozeni u osoby
CREATE OR REPLACE TRIGGER osoba_narozeni
    BEFORE INSERT OR UPDATE OF datum_narozeni ON osoba
    FOR EACH ROW
BEGIN
    IF NOT (LENGTH(:NEW.datum_narozeni) > 9) THEN
        RAISE_APPLICATION_ERROR(-20000, 'Formát čísla neodpovídá požadavkům');
    END IF;
    IF NOT (SUBSTR(:NEW.datum_narozeni, 1, 2) IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31')) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Chyba na místě dnů');
    end if;
    IF NOT (SUBSTR(:NEW.datum_narozeni, 4, 2) IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12')) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Chyba na místě měsíců');
    end if;
END;


------------ TESTOVACÍ DATA -----------------------------------------------------------
INSERT INTO planetarni_system (jmeno)
VAlUES ('Korunské utočiště');
INSERT INTO planetarni_system (jmeno)
VAlUES('stopařova zhouba');

INSERT INTO hvezda (typ, id_system)
VALUES ('pod trpaslík', 1);
INSERT INTO hvezda (typ, id_system)
VALUES ('červený trpaslík', 2);
INSERT INTO hvezda (typ, id_system)
VALUES ('vele obr', 2);

INSERT INTO planeta (jmeno, vzdalenost_od_slunce, hmotnost, pocet_obyvatel, druh)
VALUES ('Tindra', 8, 2304, 20000000000, 'super země');
INSERT INTO planeta (jmeno, vzdalenost_od_slunce, hmotnost, pocet_obyvatel, druh)
VALUES ('Khe-atu-miean', 15, 3657, 30500, 'Ledový Obr');
INSERT INTO planeta (jmeno, vzdalenost_od_slunce, hmotnost, pocet_obyvatel, druh)
VALUES ('Sloiseiho pustina', 6, 4236, 30000000, 'pouštní svět');


INSERT INTO obiha (id_hvezda, id_planeta)
VALUES (1, 1);
INSERT INTO obiha (id_hvezda, id_planeta)
VALUES (1, 2);
INSERT INTO obiha (id_hvezda, id_planeta)
VALUES (2, 3);


INSERT INTO prvky (oznaceni_prvku, procentualni_zastoupeni)
VALUES ('kyslík', 30);
INSERT INTO prvky (oznaceni_prvku, procentualni_zastoupeni)
VALUES ('oxid uhličitý', 63);
INSERT INTO prvky (oznaceni_prvku, procentualni_zastoupeni)
VALUES ('otravovač gorgunonsoský', 42);


INSERT INTO hvezda_obsahuje (id_hvezda, id_prvku)
VALUES (1, 1);
INSERT INTO hvezda_obsahuje (id_hvezda, id_prvku)
VALUES (2, 1);
INSERT INTO hvezda_obsahuje (id_hvezda, id_prvku)
VALUES (2, 3);


INSERT INTO atmosfera (id_planeta, id_prvku)
VALUES (1,1);
INSERT INTO atmosfera (id_planeta, id_prvku)
VALUES (2,1);
INSERT INTO atmosfera (id_planeta, id_prvku)
VALUES (2,2);


INSERT INTO osoba (jmeno, rasa, datum_narozeni, id_planeta)
VALUES ('Khe-podt-urxiugantud', 'Khe-kuok', '20.12.6584', 1);
INSERT INTO osoba (jmeno, rasa, datum_narozeni, id_planeta)
VALUES ('Pepa Hententon', 'člověk', '29.02.6658', 2);
INSERT INTO osoba (jmeno, rasa, datum_narozeni, id_planeta)
VALUES ('Rteahaerw', 'Gorgunonsoskuj', '30.04.6998', 2);


INSERT INTO jedi (jmeno, rasa, datum_narozeni, mnozstvi_midichloriamu, barva_mece, hodnost, id_planeta)
VALUES ('Stavoslav Hententon', 'člověk', '15.11.6655', 420, 'indigová', 'super commander', 2);
INSERT INTO jedi (jmeno, rasa, datum_narozeni, mnozstvi_midichloriamu, barva_mece, id_planeta)
VALUES ('Drah_bla', 'les', '15.11.6665', 430, 'zelená', 1);
INSERT INTO jedi (jmeno, rasa, datum_narozeni, mnozstvi_midichloriamu, barva_mece, hodnost, id_planeta)
VALUES ('Ardin Dee', 'Sith', '15.01.6654', 436, 'červená', 'commander', 2);
INSERT INTO jedi (jmeno, rasa, datum_narozeni, mnozstvi_midichloriamu, barva_mece, hodnost, id_planeta)
VALUES ('Raz Dorah', 'Ewoc', '15.01.6654', 436, 'žlutá', 'commander', 1);


INSERT INTO studuje (mistr, padavan)
VALUES (1,3);
INSERT INTO studuje (mistr, padavan)
VALUES (2,1);


INSERT INTO lod (vyrobni_cislo, trida, id_planeta)
VALUES ('5486-5s8s-f45d-s4sd', 'Křižník', 1);
INSERT INTO lod (vyrobni_cislo, trida, id_planeta)
VALUES ('d5ds-5sd5-f5es-fdfe', 'Galaktický Dominátor', 2);
INSERT INTO lod (vyrobni_cislo, trida, id_planeta)
VALUES ('f48e-f56e-6e5f-s46f', 'Planetární Devastátor', 2);


INSERT INTO flotila (id_jedi, id_planeta)
VALUES (1,1);
INSERT INTO flotila (id_jedi)
VALUES (2);

INSERT INTO flotila_sestava (vyrobni_cislo, id_flotila)
VALUES ('5486-5s8s-f45d-s4sd', 1);
INSERT INTO flotila_sestava (vyrobni_cislo, id_flotila)
VALUES ('d5ds-5sd5-f5es-fdfe', 1);
INSERT INTO flotila_sestava (vyrobni_cislo, id_flotila)
VALUES ('f48e-f56e-6e5f-s46f', 2);


-- SELECT * FROM hvezda;
-- SELECT * FROM planetarni_system;
-- SELECT * FROM obiha;
-- SELECT * FROM planeta;
-- SELECT * FROM prvky;
-- SELECT * FROM hvezda_obsahuje;
-- SELECT * FROM atmosfera;
-- SELECT * FROM osoba;
-- SELECT * FROM jedi;
-- SELECT * FROM studuje;
-- SELECT * FROM lod;
-- SELECT * FROM flotila;
-- SELECT * FROM flotila_sestava;

----------------- SELECT ------------------------------------------------------

-- SELECT dvou tabulek
-- Ktere obycejne osoby (ne jedi) pochazi z planety Khe-atu-miean
-- Vypise id, jmeno, datum narozeni
SELECT o.id_osoba, o.jmeno, o.datum_narozeni
FROM osoba o, planeta p
WHERE o.id_planeta = p.id_planeta AND p.jmeno = 'Khe-atu-miean' ;

-- SELECT dvou tabulek
-- Ktere hvezdy jsou soucasti planetarniho systemu Stopařova zhouba
-- vypise id hvezdy
SELECT h.id_hvezda
FROM hvezda h, planetarni_system p
WHERE h.id_system = p.id_system AND p.jmeno = 'Stopařova zhouba';

-- SELECT tri tabulek
-- Ktere planety obyhaji kolem jednotlivych hvezd
-- vypise id hvezdy, id planety a jeji jmeno
SELECT h.id_hvezda, p.id_planeta, p.jmeno
FROM hvezda h, planeta p, obiha o
WHERE h.id_hvezda = o.id_hvezda AND o.id_planeta = p.id_planeta;

-- GROUP BY
-- Planeta a nejvetsi pocet midi-ch
SELECT p.id_planeta, p.jmeno, MAX(j.mnozstvi_midichloriamu)
FROM jedi j, planeta p
GROUP BY p.id_planeta, p.jmeno;

-- GROUP BY
-- Planeta a pocet lodi, ktere na ni byly vyrobeny
SELECT p.id_planeta, p.jmeno, COUNT(l.vyrobni_cislo)
FROM planeta p, lod l
GROUP BY p.id_planeta, l.id_planeta, p.jmeno
HAVING l.id_planeta = p.id_planeta;

-- EXIST
-- Jedi, ktery veli flotile
SELECT j.id_jedi, j.jmeno
FROM jedi j
WHERE EXISTS
    (
        SELECT f.id_flotila
        FROM flotila f
        WHERE f.id_jedi = j.id_jedi
    );

-- IN
-- ID mistru , kteri maji vice nez 400 midi-ch.
SELECT s.mistr
FROM studuje s
WHERE s.mistr
IN  (
        SELECT j.id_jedi
        FROM jedi j
        WHERE j.mnozstvi_midichloriamu > 400
    );


------------ TRIGGERS TRIGGERED -----------------------------------------------------------

-- 1. generování id planet
SELECT *
FROM planeta
ORDER BY id_planeta;

-- 2. konrola datumu narozeni
SELECT *
FROM osoba
ORDER BY jmeno;



------------ PROCEDURE -----------------------------------------------------------

-- procedura vypíše pocet známých planet a pocet obyvatel celkem
CREATE OR REPLACE PROCEDURE vypis_planet_tvoru_lodi_pocet
AS
    cel_planet_pocet NUMBER;
    cel_osob_pocet NUMBER;
    cel_tvoru_pocet NUMBER;
    cel_lodi_pocet NUMBER;
    cel_jedi_pocet NUMBER;
    cel_flotil_pocet NUMBER;
    prum_pocet_lodi_na_flotilu NUMBER;
    prum_pocet_jedi_na_osobu NUMBER;

BEGIN
    SELECT COUNT(*) INTO cel_planet_pocet FROM planeta;
    SELECT COUNT(*) INTO cel_osob_pocet FROM osoba;
    SELECT COUNT(*) INTO cel_jedi_pocet FROM jedi;
    SELECT COUNT(*) INTO cel_flotil_pocet FROM flotila;
    SELECT COUNT(*) INTO cel_lodi_pocet FROM lod;

    cel_tvoru_pocet := cel_jedi_pocet + cel_osob_pocet;
    prum_pocet_jedi_na_osobu := cel_osob_pocet / cel_jedi_pocet;
    prum_pocet_lodi_na_flotilu := cel_lodi_pocet / cel_flotil_pocet;


    DBMS_OUTPUT.put_line(
        'Celkem je '
        || cel_planet_pocet || ' planet, '
        || cel_lodi_pocet || ' lodi, '
        || cel_osob_pocet || ' osob v evidovanych v systemu.'
    );
    DBMS_OUTPUT.put_line(
        'Statistiky: Poměr normálních osob k Jedi: ' || prum_pocet_jedi_na_osobu ||
        '. Průměrný počet lodí ve flotile: ' || prum_pocet_lodi_na_flotilu || '.'
    );


    EXCEPTION
        WHEN ZERO_DIVIDE THEN
            BEGIN
                IF cel_jedi_pocet = 0 THEN
                    DBMS_OUTPUT.put_line('neni zadny jedi');
                END IF;

                IF cel_flotil_pocet = 0 THEN
                    DBMS_OUTPUT.put_line('neni zadna flotila');
                END IF;
            END;
END;

-- příklad spuštění

BEGIN vypis_planet_tvoru_lodi_pocet; END;

-- počítá kolik celkem flotil je na dané planetě

CREATE OR REPLACE PROCEDURE vypis_flotil_na_planete
    (planety_jmeno IN VARCHAR)
AS
    vsechny_flotily NUMBER;
    cilene_flotily NUMBER;
    planeta_id planeta.id_planeta%TYPE;
    cilena_planeta_id planeta.id_planeta%TYPE;
    CURSOR cursor_planeta IS SELECT planeta_id FROM planeta;
BEGIN
    SELECT COUNT(*) INTO vsechny_flotily FROM flotila;

    cilene_flotily := 0;

    SELECT id_planeta INTO cilena_planeta_id
    FROM planeta
    WHERE jmeno = planety_jmeno;

    OPEN cursor_planeta;
    LOOP
        FETCH cursor_planeta INTO planeta_id;
        EXIT WHEN cursor_planeta%NOTFOUND;
        IF planeta_id = cilena_planeta_id THEN cilene_flotily := cilene_flotily + 1; END IF;
    END LOOP;
    CLOSE cursor_planeta;

    DBMS_OUTPUT.put_line(
        'u planety ' ||planety_jmeno||' je '||cilene_flotily||' flotil z celkovych '||vsechny_flotily||' flotil galaktickeho Imperia.'
    );

    EXCEPTION WHEN NO_DATA_FOUND THEN
    BEGIN
        DBMS_OUTPUT.put_line(
            'Planeta nebyla nalezena.'
        );
    END;
END;

-- Vypis flotil na planete
BEGIN vypis_flotil_na_planete('Khe-atu-miean'); END;




------------ EXPLAIN PLAN -----------------------------------------------------------

-- Vypise flotilu s kriznikem
EXPLAIN PLAN FOR
SELECT f.id_flotila
FROM flotila f, lod l, flotila_sestava fs
GROUP BY f.id_flotila, fs.vyrobni_cislo, fs.id_flotila, l.vyrobni_cislo, l.trida
HAVING f.id_flotila = fs.id_flotila AND l.vyrobni_cislo = fs.vyrobni_cislo AND l.trida = 'Křižník';

-- vypsani plan for flotila s kriznikem
SELECT * FROM TABLE (DBMS_XPLAN.DISPLAY);

-- vytvoření indexu pro vyrobni cislo lodi
CREATE INDEX indx_cislo ON lod (vyrobni_cislo, trida);

-- opetovne vytvoreni planu
EXPLAIN PLAN FOR
SELECT f.id_flotila
FROM flotila f, lod l, flotila_sestava fs
GROUP BY f.id_flotila, fs.vyrobni_cislo, fs.id_flotila, l.vyrobni_cislo, l.trida
HAVING f.id_flotila = fs.id_flotila AND l.vyrobni_cislo = fs.vyrobni_cislo AND l.trida = 'Křižník';

-- vypsani plan for flotila s kriznikem po indexovani
SELECT * FROM TABLE (DBMS_XPLAN.DISPLAY);


------------ MATERIALIZED VIEW -----------------------------------------------------------
CREATE MATERIALIZED VIEW pohled_systemy_a_hvezdy
AS
SELECT
    ps.jmeno,
    ps.id_system,
    COUNT(h.id_system) AS pocet_hvezd
FROM planetarni_system ps
LEFT JOIN hvezda h ON h.id_system = ps.id_system
GROUP BY ps.jmeno, ps.id_system;

-- System a pocet hvezd
SELECT * FROM pohled_systemy_a_hvezdy;

-- aktualizace dat
UPDATE hvezda SET id_system = 2 WHERE id_hvezda = 1;

-- System a pocet hvezd po aktualizaci
SELECT * FROM pohled_systemy_a_hvezdy;



------------ PRIVILEGES -----------------------------------------------------------
GRANT ALL ON planetarni_system TO xdolec03;
GRANT ALL ON hvezda TO xdolec03;
GRANT ALL ON planeta TO xdolec03;
GRANT ALL ON obiha TO xdolec03;
GRANT ALL ON prvky TO xdolec03;
GRANT ALL ON hvezda_obsahuje TO xdolec03;
GRANT ALL ON atmosfera TO xdolec03;
GRANT ALL ON osoba TO xdolec03;
GRANT ALL ON jedi TO xdolec03;
GRANT ALL ON studuje TO xdolec03;
GRANT ALL ON lod TO xdolec03;
GRANT ALL ON flotila TO xdolec03;
GRANT ALL ON flotila_sestava TO xdolec03;

-- provadeni jinde
GRANT EXECUTE ON vypis_planet_tvoru_lodi_pocet TO xdolec03;
GRANT EXECUTE ON vypis_flotil_na_planete TO xdolec03;
GRANT ALL ON pohled_systemy_a_hvezdy TO xdolec03;



