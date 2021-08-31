IF OBJECT_ID('[omop].IP_VISITS', 'U') IS NOT NULL
    DROP TABLE [omop].IP_VISITS;
IF OBJECT_ID('[omop].ER_VISITS', 'U') IS NOT NULL
    DROP TABLE [omop].ER_VISITS;
IF OBJECT_ID('[omop].OP_VISITS', 'U') IS NOT NULL
    DROP TABLE [omop].OP_VISITS;
IF OBJECT_ID('[omop].ALL_VISITS', 'U') IS NOT NULL
    DROP TABLE [omop].ALL_VISITS;

CREATE TABLE [omop].IP_VISITS
/* Inpatient visits */
/* Collapse IP claim lines with <=1 day between them into one visit */
WITH (DISTRIBUTION=ROUND_ROBIN) AS WITH CTE_END_DATES
                                   AS (SELECT patient,
                                              encounterclass,
                                              DATEADD(DAY, 1, EVENT_DATE) AS END_DATE
                                       FROM
                                       (
                                           SELECT patient,
                                                  encounterclass,
                                                  EVENT_DATE,
                                                  EVENT_TYPE,
                                                  MAX(START_ORDINAL) OVER (PARTITION BY patient,
                                                                                        encounterclass
                                                                           ORDER BY EVENT_DATE,
                                                                                    EVENT_TYPE
                                                                           ROWS UNBOUNDED PRECEDING
                                                                          ) AS START_ORDINAL,
                                                  ROW_NUMBER() OVER (PARTITION BY patient,
                                                                                  encounterclass
                                                                     ORDER BY EVENT_DATE,
                                                                              EVENT_TYPE
                                                                    ) AS OVERALL_ORD
                                           FROM
                                           (
                                               SELECT patient,
                                                      encounterclass,
                                                      start AS EVENT_DATE,
                                                      -1 AS EVENT_TYPE,
                                                      ROW_NUMBER() OVER (PARTITION BY patient, encounterclass ORDER BY start, stop) AS START_ORDINAL
                                               FROM [synthea].encounters
                                               WHERE encounterclass = 'inpatient'
                                               UNION ALL
                                               SELECT patient,
                                                      encounterclass,
                                                      DATEADD(DAY, 1, stop),
                                                      1 AS EVENT_TYPE,
                                                      NULL
                                               FROM [synthea].encounters
                                               WHERE encounterclass = 'inpatient'
                                           ) RAWDATA
                                       ) E
                                       WHERE (2 * E.START_ORDINAL - E.OVERALL_ORD = 0)),
                                        CTE_VISIT_ENDS
                                   AS (SELECT MIN(V.id) AS encounter_id,
                                              V.patient,
                                              V.encounterclass,
                                              V.start AS VISIT_START_DATE,
                                              MIN(E.END_DATE) AS VISIT_END_DATE
                                       FROM [synthea].encounters V
                                           JOIN CTE_END_DATES E
                                               ON V.patient = E.patient
                                                  AND V.encounterclass = E.encounterclass
                                                  AND E.END_DATE >= V.start
                                       GROUP BY V.patient,
                                                V.encounterclass,
                                                V.start)
SELECT T2.encounter_id,
       T2.patient,
       T2.encounterclass,
       T2.VISIT_START_DATE,
       T2.VISIT_END_DATE
FROM
(
    SELECT CTE_VISIT_ENDS.encounter_id,
           patient,
           encounterclass,
           MIN(VISIT_START_DATE) AS VISIT_START_DATE,
           CTE_VISIT_ENDS.VISIT_END_DATE
    FROM CTE_VISIT_ENDS
    GROUP BY CTE_VISIT_ENDS.encounter_id,
             patient,
             encounterclass,
             CTE_VISIT_ENDS.VISIT_END_DATE
) T2;

CREATE TABLE [omop].ER_VISITS
/* Emergency visits */
/* collapse ER claim lines with no days between them into one visit */
WITH (DISTRIBUTION=ROUND_ROBIN) AS SELECT T2.encounter_id,
                                          T2.patient,
                                          T2.encounterclass,
                                          T2.VISIT_START_DATE,
                                          T2.VISIT_END_DATE
                                   FROM
                                   (
                                       SELECT MIN(encounter_id) AS encounter_id,
                                              patient,
                                              encounterclass,
                                              VISIT_START_DATE,
                                              MAX(VISIT_END_DATE) AS VISIT_END_DATE
                                       FROM
                                       (
                                           SELECT CL1.id AS encounter_id,
                                                  CL1.patient,
                                                  CL1.encounterclass,
                                                  CL1.start AS VISIT_START_DATE,
                                                  CL2.stop AS VISIT_END_DATE
                                           FROM [synthea].encounters CL1
                                               JOIN [synthea].encounters CL2
                                                   ON CL1.patient = CL2.patient
                                                      AND CL1.start = CL2.start
                                                      AND CL1.encounterclass = CL2.encounterclass
                                           WHERE CL1.encounterclass IN ( 'emergency', 'urgent' )
                                       ) T1
                                       GROUP BY patient,
                                                encounterclass,
                                                VISIT_START_DATE
                                   ) T2;

/* Outpatient visits */
CREATE TABLE [omop].OP_VISITS
WITH (DISTRIBUTION=ROUND_ROBIN) AS WITH CTE_VISITS_DISTINCT
                                   AS (SELECT MIN(id) AS encounter_id,
                                              patient,
                                              encounterclass,
                                              start AS VISIT_START_DATE,
                                              stop AS VISIT_END_DATE
                                       FROM [synthea].encounters
                                       WHERE encounterclass IN ( 'ambulatory', 'wellness', 'outpatient' )
                                       GROUP BY patient,
                                                encounterclass,
                                                start,
                                                stop)
SELECT MIN(CTE_VISITS_DISTINCT.encounter_id) AS encounter_id,
       patient,
       encounterclass,
       VISIT_START_DATE,
       MAX(VISIT_END_DATE) AS VISIT_END_DATE
FROM CTE_VISITS_DISTINCT
GROUP BY patient,
         encounterclass,
         VISIT_START_DATE;

CREATE TABLE [omop].all_visits
WITH (DISTRIBUTION=ROUND_ROBIN)
/* All visits */
AS SELECT T1.encounter_id,
          patient,
          encounterclass,
          T1.VISIT_START_DATE,
          T1.VISIT_END_DATE,
          ROW_NUMBER() OVER (ORDER BY patient) AS visit_occurrence_id
   FROM
   (
       SELECT IP_VISITS.encounter_id,
              patient,
              encounterclass,
              IP_VISITS.VISIT_START_DATE,
              IP_VISITS.VISIT_END_DATE
       FROM [omop].IP_VISITS
       UNION ALL
       SELECT ER_VISITS.encounter_id,
              patient,
              encounterclass,
              VISIT_START_DATE,
              ER_VISITS.VISIT_END_DATE
       FROM [omop].ER_VISITS
       UNION ALL
       SELECT OP_VISITS.encounter_id,
              patient,
              encounterclass,
              VISIT_START_DATE,
              OP_VISITS.VISIT_END_DATE
       FROM [omop].OP_VISITS
   ) T1;

--Remove unnecessary tables
IF OBJECT_ID('[omop].IP_VISITS', 'U') IS NOT NULL
    DROP TABLE [omop].IP_VISITS;
IF OBJECT_ID('[omop].ER_VISITS', 'U') IS NOT NULL
    DROP TABLE [omop].ER_VISITS;
IF OBJECT_ID('[omop].OP_VISITS', 'U') IS NOT NULL
    DROP TABLE [omop].OP_VISITS;
