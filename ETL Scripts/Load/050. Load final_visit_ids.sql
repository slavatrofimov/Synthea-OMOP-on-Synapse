-- =============================================
-- Create Date: 20210505
-- Description: Create and load [omop].FINAL_VISIT_IDS table
-- =============================================
IF OBJECT_ID('[omop].FINAL_VISIT_IDS', 'U') IS NOT NULL
    DROP TABLE [omop].FINAL_VISIT_IDS;

CREATE TABLE [omop].FINAL_VISIT_IDS
WITH (DISTRIBUTION=ROUND_ROBIN) AS SELECT encounter_id,
                                          VISIT_OCCURRENCE_ID_NEW
                                   FROM
                                   (
                                       SELECT T1.PRIORITY,
                                              T1.encounter_id,
                                              T1.VISIT_OCCURRENCE_ID_NEW,
                                              ROW_NUMBER() OVER (PARTITION BY encounter_id ORDER BY T1.PRIORITY) AS RN
                                       FROM
                                       (
                                           SELECT *,
                                                  CASE
                                                      WHEN encounterclass IN ( 'emergency', 'urgent' ) THEN
                                                  (CASE
                                                       WHEN VISIT_TYPE = 'inpatient'
                                                            AND VISIT_OCCURRENCE_ID_NEW IS NOT NULL THEN
                                                           1
                                                       WHEN VISIT_TYPE IN ( 'emergency', 'urgent' )
                                                            AND VISIT_OCCURRENCE_ID_NEW IS NOT NULL THEN
                                                           2
                                                       ELSE
                                                           99
                                                   END
                                                  )
                                                      WHEN encounterclass IN ( 'ambulatory', 'wellness', 'outpatient' ) THEN
                                                  (CASE
                                                       WHEN VISIT_TYPE = 'inpatient'
                                                            AND VISIT_OCCURRENCE_ID_NEW IS NOT NULL THEN
                                                           1
                                                       WHEN VISIT_TYPE IN ( 'ambulatory', 'wellness', 'outpatient' )
                                                            AND VISIT_OCCURRENCE_ID_NEW IS NOT NULL THEN
                                                           2
                                                       ELSE
                                                           99
                                                   END
                                                  )
                                                      WHEN encounterclass = 'inpatient'
                                                           AND VISIT_TYPE = 'inpatient'
                                                           AND VISIT_OCCURRENCE_ID_NEW IS NOT NULL THEN
                                                          1
                                                      ELSE
                                                          99
                                                  END AS PRIORITY
                                           FROM [omop].ASSIGN_ALL_VISIT_IDS
                                       ) T1
                                   ) T2
                                   WHERE T2.RN = 1;