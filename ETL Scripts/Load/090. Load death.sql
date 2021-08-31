-- NB:
-- We observe death records in both the encounters.csv and observations.csv file.
-- To find the death records in observations, use code = '69453-9'. This is a LOINC code 
-- that represents an observation of the US standard certificate of death.  To find the 
-- corresponding cause of death, we would need to join to conditions on patient and description 
-- (specifically conditions.description = observations.value).  Instead, we can use the encounters table. 
-- Encounters.code = '308646001' is the SNOMED observation of death certification.
-- The reasoncode column is the SNOMED code for the condition that caused death, so by using encounters
-- we get both the code for the death certification and the corresponding cause of death. 

INSERT INTO [omop].DEATH
(
    PERSON_ID,
    DEATH_DATE,
    DEATH_DATETIME,
    DEATH_TYPE_CONCEPT_ID,
    CAUSE_CONCEPT_ID,
    CAUSE_SOURCE_VALUE,
    CAUSE_SOURCE_CONCEPT_ID
)
SELECT p.PERSON_ID person_id,
       e.start death_date,
       e.start death_datetime,
       38003566 death_type_concept_id,
       srctostdvm.TARGET_CONCEPT_ID cause_concept_id,
       e.reasoncode cause_source_value,
       srctostdvm.SOURCE_CONCEPT_ID cause_source_concept_id
FROM [synthea].encounters e
    JOIN [helper].source_to_standard_vocab_map srctostdvm
        ON srctostdvm.SOURCE_CODE = e.reasoncode
           AND srctostdvm.TARGET_DOMAIN_ID = 'Condition'
           AND srctostdvm.SOURCE_DOMAIN_ID = 'Condition'
           AND srctostdvm.TARGET_VOCABULARY_ID = 'SNOMED'
           AND srctostdvm.SOURCE_VOCABULARY_ID = 'SNOMED'
           AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
           AND srctostdvm.TARGET_INVALID_REASON IS NULL
    JOIN [omop].PERSON p
        ON e.patient = p.PERSON_SOURCE_VALUE
WHERE e.code = '308646001';

