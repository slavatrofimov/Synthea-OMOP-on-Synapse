/*Assign VISIT_OCCURRENCE_ID to all encounters*/

IF OBJECT_ID('[omop].ASSIGN_ALL_VISIT_IDS', 'U') IS NOT NULL
BEGIN
    DROP TABLE [omop].ASSIGN_ALL_VISIT_IDS;
END;

CREATE TABLE [omop].ASSIGN_ALL_VISIT_IDS
WITH (DISTRIBUTION=ROUND_ROBIN) AS SELECT E.id AS encounter_id,
                                          E.patient AS person_source_value,
                                          E.start AS date_service,
                                          E.stop AS date_service_end,
                                          E.encounterclass,
                                          AV.encounterclass AS VISIT_TYPE,
                                          AV.VISIT_START_DATE,
                                          AV.VISIT_END_DATE,
                                          AV.visit_occurrence_id,
                                          CASE
                                              WHEN E.encounterclass = 'inpatient'
                                                   AND AV.encounterclass = 'inpatient' THEN
                                                  visit_occurrence_id
                                              WHEN E.encounterclass IN ( 'emergency', 'urgent' ) THEN
                                          (CASE
                                               WHEN AV.encounterclass = 'inpatient'
                                                    AND E.start > AV.VISIT_START_DATE THEN
                                                   visit_occurrence_id
                                               WHEN AV.encounterclass IN ( 'emergency', 'urgent' )
                                                    AND E.start = AV.VISIT_START_DATE THEN
                                                   visit_occurrence_id
                                               ELSE
                                                   NULL
                                           END
                                          )
                                              WHEN E.encounterclass IN ( 'ambulatory', 'wellness', 'outpatient' ) THEN
                                          (CASE
                                               WHEN AV.encounterclass = 'inpatient'
                                                    AND E.start >= AV.VISIT_START_DATE THEN
                                                   visit_occurrence_id
                                               WHEN AV.encounterclass IN ( 'ambulatory', 'wellness', 'outpatient' ) THEN
                                                   visit_occurrence_id
                                               ELSE
                                                   NULL
                                           END
                                          )
                                              ELSE
                                                  NULL
                                          END AS VISIT_OCCURRENCE_ID_NEW
                                   FROM [synthea].encounters AS E
                                       JOIN [omop].all_visits AS AV
                                           ON E.patient = AV.patient
                                              AND E.start >= AV.VISIT_START_DATE
                                              AND E.start <= AV.VISIT_END_DATE;
