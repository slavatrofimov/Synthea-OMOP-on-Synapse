-- =============================================
-- Create Date: 20210505
-- Description: Insert condition occurrence
-- Code derived from: https://github.com/OHDSI/ETL-CMS/blob/master/SQL/create_CDMv5_drug_era_non_stockpile.sql
-- =============================================


IF OBJECT_ID('tempdb..#tmp_de') IS NOT NULL
    DROP TABLE #tmp_de;

CREATE TABLE #tmp_de
WITH (DISTRIBUTION=ROUND_ROBIN) AS 
	WITH ctePreDrugTarget (drug_exposure_id, person_id,
                                ingredient_concept_id,
                                drug_exposure_start_date,
                                days_supply,
                                drug_exposure_end_date
                                )
        AS (SELECT d.DRUG_EXPOSURE_ID,
                    d.PERSON_ID,
                    c.CONCEPT_ID AS ingredient_concept_id,
                    d.DRUG_EXPOSURE_START_DATE AS drug_exposure_start_date,
                    d.DAYS_SUPPLY AS days_supply,
                    COALESCE(
                                ---NULLIF returns NULL if both values are the same, otherwise it returns the first parameter
                                NULLIF(DRUG_EXPOSURE_END_DATE, NULL),
                                ---If drug_exposure_end_date != NULL, return drug_exposure_end_date, otherwise go to next case
                                NULLIF(DATEADD(
                                                    DAY,
                                                    DAYS_SUPPLY,
                                                    DRUG_EXPOSURE_START_DATE
                                                ), DRUG_EXPOSURE_START_DATE),
                                ---If days_supply != NULL or 0, return drug_exposure_start_date + days_supply, otherwise go to next case
                                DATEADD(
                                            DAY,
                                            1,
                                            DRUG_EXPOSURE_START_DATE
                                        )
                            ---Add 1 day to the drug_exposure_start_date since there is no end_date or INTERVAL for the days_supply
                            ) AS drug_exposure_end_date
            FROM [omop].DRUG_EXPOSURE d
                JOIN [vocab].CONCEPT_ANCESTOR ca
                    ON ca.DESCENDANT_CONCEPT_ID = d.DRUG_CONCEPT_ID
                JOIN [vocab].CONCEPT c
                    ON ca.ANCESTOR_CONCEPT_ID = c.CONCEPT_ID
            WHERE c.VOCABULARY_ID = 'RxNorm'
                    AND c.CONCEPT_CLASS_ID = 'Ingredient'
                    AND d.DRUG_CONCEPT_ID != 0 ---Our unmapped drug_concept_id's are set to 0, so we don't want different drugs wrapped up in the same era
                    AND COALESCE(d.DAYS_SUPPLY, 0) >= 0
        ---We have cases where days_supply is negative, and this can set the end_date before the start_date, which we don't want. So we're just looking over those rows. This is a data-quality issue.
        ),
                cteSubExposureEndDates (person_id,
                                        ingredient_concept_id,
                                        end_date
                                    )
        AS
        --- A preliminary sorting that groups all of the overlapping exposures into one exposure so that we don't double-count non-gap-days
        (SELECT person_id,
                ingredient_concept_id,
                event_date AS end_date
            FROM
            (
                SELECT person_id,
                    ingredient_concept_id,
                    event_date,
                    event_type,
                    MAX(start_ordinal) OVER (PARTITION BY person_id,
                                                            ingredient_concept_id
                                                ORDER BY event_date,
                                                        event_type
                                                ROWS unbounded preceding
                                            ) AS start_ordinal,
                    -- this pulls the current START down from the prior rows so that the NULLs
                    -- from the END DATES will contain a value we can compare with
                    ROW_NUMBER() OVER (PARTITION BY person_id,
                                                    ingredient_concept_id
                                        ORDER BY event_date,
                                                event_type
                                        ) AS overall_ord
                -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
                FROM
                (
                    -- select the start dates, assigning a row number to each
                    SELECT person_id,
                        ingredient_concept_id,
                        drug_exposure_start_date AS event_date,
                        -1 AS event_type,
                        ROW_NUMBER() OVER (PARTITION BY person_id,
                                                        ingredient_concept_id
                                            ORDER BY drug_exposure_start_date
                                            ) AS start_ordinal
                    FROM ctePreDrugTarget
                    UNION ALL
                    SELECT person_id,
                        ingredient_concept_id,
                        drug_exposure_end_date,
                        1 AS event_type,
                        NULL
                    FROM ctePreDrugTarget
                ) RAWDATA
            ) E
            WHERE (2 * E.start_ordinal) - E.overall_ord = 0),
                cteDrugExposureEnds (person_id, drug_concept_id,
                                    drug_exposure_start_date,
                                    drug_sub_exposure_end_date
                                    )
        AS (SELECT dt.person_id,
                    dt.ingredient_concept_id,
                    dt.drug_exposure_start_date,
                    MIN(e.end_date) AS drug_sub_exposure_end_date
            FROM ctePreDrugTarget dt
                JOIN cteSubExposureEndDates e
                    ON dt.person_id = e.person_id
                        AND dt.ingredient_concept_id = e.ingredient_concept_id
                        AND e.end_date >= dt.drug_exposure_start_date
            GROUP BY dt.drug_exposure_id,
                        dt.person_id,
                        dt.ingredient_concept_id,
                        dt.drug_exposure_start_date),
                --------------------------------------------------------------------------------------------------------------
                cteSubExposures (row_number, person_id,
                                drug_concept_id,
                                drug_sub_exposure_start_date,
                                drug_sub_exposure_end_date,
                                drug_exposure_count
                                )
        AS (SELECT ROW_NUMBER() OVER (PARTITION BY person_id,
                                                    drug_concept_id,
                                                    drug_sub_exposure_end_date
                                        ORDER BY person_id
                                        ),
                    person_id,
                    drug_concept_id,
                    MIN(drug_exposure_start_date) AS drug_sub_exposure_start_date,
                    drug_sub_exposure_end_date,
                    COUNT(*) AS drug_exposure_count
            FROM cteDrugExposureEnds
            GROUP BY person_id,
                        drug_concept_id,
                        drug_sub_exposure_end_date
                --ORDER BY person_id, drug_concept_id
                ),
                --------------------------------------------------------------------------------------------------------------
                /*Everything above grouped exposures into sub_exposures if there was overlap between exposures.
*So there was no persistence window. Now we can add the persistence window to calculate eras.
*/
                --------------------------------------------------------------------------------------------------------------
                cteFinalTarget (row_number, person_id,
                                ingredient_concept_id,
                                drug_sub_exposure_start_date,
                                drug_sub_exposure_end_date,
                                drug_exposure_count, days_exposed
                            )
        AS (SELECT row_number,
                    person_id,
                    drug_concept_id,
                    drug_sub_exposure_start_date,
                    drug_sub_exposure_end_date,
                    drug_exposure_count,
                    DATEDIFF(
                                DAY,
                                drug_sub_exposure_start_date,
                                drug_sub_exposure_end_date
                            ) AS days_exposed
            FROM cteSubExposures),
                --------------------------------------------------------------------------------------------------------------
                cteEndDates (person_id, ingredient_concept_id,
                            end_date
                            )
        AS
        -- the magic
        (SELECT person_id,
                ingredient_concept_id,
                DATEADD(DAY, -30, event_date) AS end_date
            -- unpad the end date
            FROM
            (
                SELECT person_id,
                    ingredient_concept_id,
                    event_date,
                    event_type,
                    MAX(start_ordinal) OVER (PARTITION BY person_id,
                                                            ingredient_concept_id
                                                ORDER BY event_date,
                                                        event_type
                                                ROWS UNBOUNDED PRECEDING
                                            ) AS start_ordinal,
                    -- this pulls the current START down from the prior rows so that the NULLs
                    -- from the END DATES will contain a value we can compare with
                    ROW_NUMBER() OVER (PARTITION BY person_id,
                                                    ingredient_concept_id
                                        ORDER BY event_date,
                                                event_type
                                        ) AS overall_ord
                -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
                FROM
                (
                    -- select the start dates, assigning a row number to each
                    SELECT person_id,
                        ingredient_concept_id,
                        drug_sub_exposure_start_date AS event_date,
                        -1 AS event_type,
                        ROW_NUMBER() OVER (PARTITION BY person_id,
                                                        ingredient_concept_id
                                            ORDER BY drug_sub_exposure_start_date
                                            ) AS start_ordinal
                    FROM cteFinalTarget
                    UNION ALL

                    -- pad the end dates by 30 to allow a grace period for overlapping ranges.
                    SELECT person_id,
                        ingredient_concept_id,
                        DATEADD(
                                    DAY,
                                    30,
                                    drug_sub_exposure_end_date
                                ),
                        1 AS event_type,
                        NULL
                    FROM cteFinalTarget
                ) RAWDATA
            ) E
            WHERE (2 * E.start_ordinal) - E.overall_ord = 0),
                cteDrugEraEnds (person_id, drug_concept_id,
                                drug_sub_exposure_start_date,
                                drug_era_end_date,
                                drug_exposure_count, days_exposed
                            )
        AS (SELECT ft.person_id,
                    ft.ingredient_concept_id,
                    ft.drug_sub_exposure_start_date,
                    MIN(e.end_date) AS era_end_date,
                    drug_exposure_count,
                    days_exposed
            FROM cteFinalTarget ft
                JOIN cteEndDates e
                    ON ft.person_id = e.person_id
                        AND ft.ingredient_concept_id = e.ingredient_concept_id
                        AND e.end_date >= ft.drug_sub_exposure_start_date
            GROUP BY ft.person_id,
                        ft.ingredient_concept_id,
                        ft.drug_sub_exposure_start_date,
                        drug_exposure_count,
                        days_exposed)
SELECT ROW_NUMBER() OVER (ORDER BY person_id) drug_era_id,
       person_id,
       drug_concept_id,
       MIN(drug_sub_exposure_start_date) AS drug_era_start_date,
       drug_era_end_date,
       SUM(drug_exposure_count) AS drug_exposure_count,
       DATEDIFF(
                   DAY,
                   '1970-01-01',
                   DATEADD(
                              DAY,
                              - (DATEDIFF(DAY, MIN(drug_sub_exposure_start_date), drug_era_end_date)
                                 - SUM(days_exposed)
                                ),
                              drug_era_end_date
                          )
               ) AS gap_days
FROM cteDrugEraEnds dee
GROUP BY person_id,
         drug_concept_id,
         drug_era_end_date;


INSERT INTO [omop].DRUG_ERA
(
    DRUG_ERA_ID,
    PERSON_ID,
    DRUG_CONCEPT_ID,
    DRUG_ERA_START_DATE,
    DRUG_ERA_END_DATE,
    DRUG_EXPOSURE_COUNT,
    GAP_DAYS
)
SELECT     DRUG_ERA_ID,
    PERSON_ID,
    DRUG_CONCEPT_ID,
    DRUG_ERA_START_DATE,
    DRUG_ERA_END_DATE,
    DRUG_EXPOSURE_COUNT,
    GAP_DAYS
FROM #tmp_de;


