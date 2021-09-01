-- Create mapping table as per logic in 3.1.2 Source to Standard Terminology
-- found in Truven_CCAE_and_MDCR_ETL_CDM_V5.2.0.doc
--
IF OBJECT_ID('[helper].source_to_standard_vocab_map', 'U') IS NOT NULL
    DROP TABLE [helper].source_to_standard_vocab_map;

CREATE TABLE [helper].source_to_standard_vocab_map
WITH (DISTRIBUTION=ROUND_ROBIN) AS WITH CTE_VOCAB_MAP
                                   AS (SELECT C.CONCEPT_CODE AS SOURCE_CODE,
                                              C.CONCEPT_ID AS SOURCE_CONCEPT_ID,
                                              C.CONCEPT_NAME AS SOURCE_CODE_DESCRIPTION,
                                              C.VOCABULARY_ID AS SOURCE_VOCABULARY_ID,
                                              C.DOMAIN_ID AS SOURCE_DOMAIN_ID,
                                              C.CONCEPT_CLASS_ID AS SOURCE_CONCEPT_CLASS_ID,
                                              C.VALID_START_DATE AS SOURCE_VALID_START_DATE,
                                              C.VALID_END_DATE AS SOURCE_VALID_END_DATE,
                                              C.INVALID_REASON AS SOURCE_INVALID_REASON,
                                              C1.CONCEPT_ID AS TARGET_CONCEPT_ID,
                                              C1.CONCEPT_NAME AS TARGET_CONCEPT_NAME,
                                              C1.VOCABULARY_ID AS TARGET_VOCABULARY_ID,
                                              C1.DOMAIN_ID AS TARGET_DOMAIN_ID,
                                              C1.CONCEPT_CLASS_ID AS TARGET_CONCEPT_CLASS_ID,
                                              C1.INVALID_REASON AS TARGET_INVALID_REASON,
                                              C1.STANDARD_CONCEPT AS TARGET_STANDARD_CONCEPT
                                       FROM [vocab].CONCEPT C
                                           JOIN [vocab].CONCEPT_RELATIONSHIP CR
                                               ON C.CONCEPT_ID = CR.CONCEPT_ID_1
                                                  AND CR.INVALID_REASON IS NULL
                                                  AND LOWER(CR.RELATIONSHIP_ID) = CAST('maps to' AS VARCHAR(20))
                                           JOIN [vocab].CONCEPT C1
                                               ON CR.CONCEPT_ID_2 = C1.CONCEPT_ID
                                                  AND C1.INVALID_REASON IS NULL
                                       UNION
                                       SELECT SOURCE_CODE,
                                              SOURCE_CONCEPT_ID,
                                              SOURCE_CODE_DESCRIPTION,
                                              SOURCE_VOCABULARY_ID,
                                              c1.DOMAIN_ID AS SOURCE_DOMAIN_ID,
                                              c2.CONCEPT_CLASS_ID AS SOURCE_CONCEPT_CLASS_ID,
                                              c1.VALID_START_DATE AS SOURCE_VALID_START_DATE,
                                              c1.VALID_END_DATE AS SOURCE_VALID_END_DATE,
                                              stcm.INVALID_REASON AS SOURCE_INVALID_REASON,
                                              TARGET_CONCEPT_ID,
                                              c2.CONCEPT_NAME AS TARGET_CONCEPT_NAME,
                                              TARGET_VOCABULARY_ID,
                                              c2.DOMAIN_ID AS TARGET_DOMAIN_ID,
                                              c2.CONCEPT_CLASS_ID AS TARGET_CONCEPT_CLASS_ID,
                                              c2.INVALID_REASON AS TARGET_INVALID_REASON,
                                              c2.STANDARD_CONCEPT AS TARGET_STANDARD_CONCEPT
                                       FROM [omop].SOURCE_TO_CONCEPT_MAP stcm
                                           LEFT OUTER JOIN [vocab].CONCEPT c1
                                               ON c1.CONCEPT_ID = stcm.SOURCE_CONCEPT_ID
                                           LEFT OUTER JOIN [vocab].CONCEPT c2
                                               ON c2.CONCEPT_ID = stcm.TARGET_CONCEPT_ID
                                       WHERE stcm.INVALID_REASON IS NULL)
SELECT CTE_VOCAB_MAP.SOURCE_CODE,
       CTE_VOCAB_MAP.SOURCE_CONCEPT_ID,
       CTE_VOCAB_MAP.SOURCE_CODE_DESCRIPTION,
       CTE_VOCAB_MAP.SOURCE_VOCABULARY_ID,
       CTE_VOCAB_MAP.SOURCE_DOMAIN_ID,
       CTE_VOCAB_MAP.SOURCE_CONCEPT_CLASS_ID,
       CTE_VOCAB_MAP.SOURCE_VALID_START_DATE,
       CTE_VOCAB_MAP.SOURCE_VALID_END_DATE,
       CTE_VOCAB_MAP.SOURCE_INVALID_REASON,
       CTE_VOCAB_MAP.TARGET_CONCEPT_ID,
       CTE_VOCAB_MAP.TARGET_CONCEPT_NAME,
       CTE_VOCAB_MAP.TARGET_VOCABULARY_ID,
       CTE_VOCAB_MAP.TARGET_DOMAIN_ID,
       CTE_VOCAB_MAP.TARGET_CONCEPT_CLASS_ID,
       CTE_VOCAB_MAP.TARGET_INVALID_REASON,
       CTE_VOCAB_MAP.TARGET_STANDARD_CONCEPT
FROM CTE_VOCAB_MAP;

CREATE INDEX idx_vocab_map_source_code
ON [helper].source_to_standard_vocab_map (SOURCE_CODE);
CREATE INDEX idx_vocab_map_source_vocab_id
ON [helper].source_to_standard_vocab_map (SOURCE_VOCABULARY_ID);
