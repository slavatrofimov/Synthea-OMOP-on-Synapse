-- =============================================
-- Create Date: 20210505
-- Description: Insert condition era
-- This procedure is derived from: https://github.com/OHDSI/ETL-CMS/blob/master/SQL/create_CDMv5_condition_era.sql
-- =============================================
IF OBJECT_ID('tempdb..#tmp_ce', 'U') IS NOT NULL
    DROP TABLE #tmp_ce;

WITH cteConditionTarget (condition_occurrence_id, person_id, condition_concept_id, condition_start_date,
                         condition_end_date
                        )
AS (SELECT co.CONDITION_OCCURRENCE_ID,
           co.PERSON_ID,
           co.CONDITION_CONCEPT_ID,
           co.CONDITION_START_DATE,
           COALESCE(NULLIF(co.CONDITION_END_DATE, NULL), DATEADD(DAY, 1, CONDITION_START_DATE)) AS condition_end_date
    FROM [omop].CONDITION_OCCURRENCE co
/* Depending on the needs of your data, you can put more filters on to your code. We assign 0 to our unmapped condition_concept_id's,
	 * and since we don't want different conditions put in the same era, we put in the filter below.
 	 */
---WHERE condition_concept_id != 0
),
     --------------------------------------------------------------------------------------------------------------
     cteEndDates (person_id, condition_concept_id, end_date)
AS   -- the magic
(SELECT person_id,
        condition_concept_id,
        DATEADD(DAY, -30, event_date) AS end_date -- unpad the end date
 FROM
 (
     SELECT person_id,
            condition_concept_id,
            event_date,
            event_type,
            MAX(start_ordinal) OVER (PARTITION BY person_id,
                                                  condition_concept_id
                                     ORDER BY event_date,
                                              event_type
                                     ROWS UNBOUNDED PRECEDING
                                    ) AS start_ordinal, -- this pulls the current START down from the prior rows so that the NULLs from the END DATES will contain a value we can compare with
            ROW_NUMBER() OVER (PARTITION BY person_id,
                                            condition_concept_id
                               ORDER BY event_date,
                                        event_type
                              ) AS overall_ord          -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
     FROM
     (
         -- select the start dates, assigning a row number to each
         SELECT person_id,
                condition_concept_id,
                condition_start_date AS event_date,
                -1 AS event_type,
                ROW_NUMBER() OVER (PARTITION BY person_id,
                                                condition_concept_id
                                   ORDER BY condition_start_date
                                  ) AS start_ordinal
         FROM cteConditionTarget
         UNION ALL

         -- pad the end dates by 30 to allow a grace period for overlapping ranges.
         SELECT person_id,
                condition_concept_id,
                DATEADD(DAY, 30, condition_end_date),
                1 AS event_type,
                NULL
         FROM cteConditionTarget
     ) RAWDATA
 ) E
 WHERE (2 * e.start_ordinal) - e.overall_ord = 0),
     --------------------------------------------------------------------------------------------------------------
     cteConditionEnds (person_id, condition_concept_id, condition_start_date, era_end_date)
AS (SELECT c.person_id,
           c.condition_concept_id,
           c.condition_start_date,
           MIN(e.end_date) AS era_end_date
    FROM cteConditionTarget c
        JOIN cteEndDates e
            ON c.person_id = e.person_id
               AND c.condition_concept_id = e.condition_concept_id
               AND e.end_date >= c.condition_start_date
    GROUP BY c.condition_occurrence_id,
             c.person_id,
             c.condition_concept_id,
             c.condition_start_date)
--------------------------------------------------------------------------------------------------------------


SELECT ROW_NUMBER() OVER (ORDER BY person_id) condition_era_id,
       person_id,
       condition_concept_id,
       MIN(condition_start_date) AS condition_era_start_date,
       era_end_date AS condition_era_end_date,
       COUNT(*) AS condition_occurrence_count
INTO #tmp_ce
FROM cteConditionEnds
GROUP BY person_id,
         condition_concept_id,
         era_end_date;

INSERT INTO [omop].CONDITION_ERA
(
    CONDITION_ERA_ID,
    PERSON_ID,
    CONDITION_CONCEPT_ID,
    CONDITION_ERA_START_DATE,
    CONDITION_ERA_END_DATE,
    CONDITION_OCCURRENCE_COUNT
)
SELECT CONDITION_ERA_ID,
    PERSON_ID,
    CONDITION_CONCEPT_ID,
    CONDITION_ERA_START_DATE,
    CONDITION_ERA_END_DATE,
    CONDITION_OCCURRENCE_COUNT
FROM #tmp_ce;

