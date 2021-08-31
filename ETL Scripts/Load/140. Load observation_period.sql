INSERT INTO [omop].OBSERVATION_PERIOD
(
    OBSERVATION_PERIOD_ID,
    PERSON_ID,
    OBSERVATION_PERIOD_START_DATE,
    OBSERVATION_PERIOD_END_DATE,
    PERIOD_TYPE_CONCEPT_ID
)
SELECT ROW_NUMBER() OVER (ORDER BY PERSON_ID),
       PERSON_ID,
       start_date,
       end_date,
       44814724 period_type_concept_id
FROM
(
    SELECT p.PERSON_ID,
           MIN(e.start) start_date,
           MAX(e.stop) end_date
    FROM [omop].PERSON p
        JOIN [synthea].encounters e
            ON p.PERSON_SOURCE_VALUE = e.patient
    GROUP BY p.PERSON_ID
) tmp;
