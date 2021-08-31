INSERT INTO [omop].PERSON
(
    PERSON_ID,
    GENDER_CONCEPT_ID,
    YEAR_OF_BIRTH,
    MONTH_OF_BIRTH,
    DAY_OF_BIRTH,
    BIRTH_DATETIME,
    RACE_CONCEPT_ID,
    ETHNICITY_CONCEPT_ID,
    LOCATION_ID,
    PROVIDER_ID,
    CARE_SITE_ID,
    PERSON_SOURCE_VALUE,
    GENDER_SOURCE_VALUE,
    GENDER_SOURCE_CONCEPT_ID,
    RACE_SOURCE_VALUE,
    RACE_SOURCE_CONCEPT_ID,
    ETHNICITY_SOURCE_VALUE,
    ETHNICITY_SOURCE_CONCEPT_ID
)
SELECT ROW_NUMBER() OVER (ORDER BY p.id),
       CASE UPPER(p.gender)
           WHEN 'M' THEN
               8507
           WHEN 'F' THEN
               8532
       END,
       YEAR(p.birthdate),
       MONTH(p.birthdate),
       DAY(p.birthdate),
       p.birthdate,
       CASE UPPER(p.race)
           WHEN 'WHITE' THEN
               8527
           WHEN 'BLACK' THEN
               8516
           WHEN 'ASIAN' THEN
               8515
           ELSE
               0
       END,
       CASE
           WHEN UPPER(p.race) = 'HISPANIC' THEN
               38003563
           ELSE
               0
       END,
       NULL,
       NULL,
       NULL,
       p.id,
       p.gender,
       0,
       p.race,
       0,
       p.ethnicity,
       0
FROM [synthea].patients p
WHERE p.gender IS NOT NULL;
