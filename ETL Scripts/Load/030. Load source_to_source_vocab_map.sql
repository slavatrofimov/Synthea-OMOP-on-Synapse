--Use this code to map source codes to source concept ids;
IF OBJECT_ID('[helper].source_to_source_vocab_map', 'U') IS NOT NULL
    DROP TABLE [helper].source_to_source_vocab_map;


CREATE TABLE [helper].source_to_source_vocab_map
WITH (DISTRIBUTION=ROUND_ROBIN) AS WITH CTE_VOCAB_MAP
                                   AS (SELECT c.CONCEPT_CODE AS SOURCE_CODE,
                                              c.CONCEPT_ID AS SOURCE_CONCEPT_ID,
                                              c.CONCEPT_NAME AS SOURCE_CODE_DESCRIPTION,
                                              c.VOCABULARY_ID AS SOURCE_VOCABULARY_ID,
                                              c.DOMAIN_ID AS SOURCE_DOMAIN_ID,
                                              c.CONCEPT_CLASS_ID AS SOURCE_CONCEPT_CLASS_ID,
                                              c.VALID_START_DATE AS SOURCE_VALID_START_DATE,
                                              c.VALID_END_DATE AS SOURCE_VALID_END_DATE,
                                              c.INVALID_REASON AS SOURCE_INVALID_REASON,
                                              c.CONCEPT_ID AS TARGET_CONCEPT_ID,
                                              c.CONCEPT_NAME AS TARGET_CONCEPT_NAME,
                                              c.VOCABULARY_ID AS TARGET_VOCABULARY_ID,
                                              c.DOMAIN_ID AS TARGET_DOMAIN_ID,
                                              c.CONCEPT_CLASS_ID AS TARGET_CONCEPT_CLASS_ID,
                                              c.INVALID_REASON AS TARGET_INVALID_REASON,
                                              c.STANDARD_CONCEPT AS TARGET_STANDARD_CONCEPT
                                       FROM [omop].CONCEPT c
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
                                           LEFT OUTER JOIN [omop].CONCEPT c1
                                               ON c1.CONCEPT_ID = stcm.SOURCE_CONCEPT_ID
                                           LEFT OUTER JOIN [omop].CONCEPT c2
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

CREATE INDEX idx_source_vocab_map_source_code
ON [helper].source_to_source_vocab_map (SOURCE_CODE);
CREATE INDEX idx_source_vocab_map_source_vocab_id
ON [helper].source_to_source_vocab_map (SOURCE_VOCABULARY_ID);
