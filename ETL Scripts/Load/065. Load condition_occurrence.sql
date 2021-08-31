INSERT INTO [omop].CONDITION_OCCURRENCE
(
    CONDITION_OCCURRENCE_ID,
    PERSON_ID,
    CONDITION_CONCEPT_ID,
    CONDITION_START_DATE,
    CONDITION_START_DATETIME,
    CONDITION_END_DATE,
    CONDITION_END_DATETIME,
    CONDITION_TYPE_CONCEPT_ID,
    STOP_REASON,
    PROVIDER_ID,
    VISIT_OCCURRENCE_ID,
    VISIT_DETAIL_ID,
    CONDITION_SOURCE_VALUE,
    CONDITION_SOURCE_CONCEPT_ID,
    CONDITION_STATUS_SOURCE_VALUE,
    CONDITION_STATUS_CONCEPT_ID
)
SELECT ROW_NUMBER() OVER (ORDER BY p.PERSON_ID) condition_occurrence_id,
       p.PERSON_ID person_id,
       srctostdvm.TARGET_CONCEPT_ID condition_concept_id,
       c.start condition_start_date,
       c.start condition_start_datetime,
       c.stop condition_end_date,
       c.stop condition_end_datetime,
       38000175 condition_type_concept_id,
       CAST(NULL AS VARCHAR) stop_reason,
       CAST(NULL AS INTEGER) provider_id,
       fv.VISIT_OCCURRENCE_ID_NEW visit_occurrence_id,
       fv.VISIT_OCCURRENCE_ID_NEW + 1000000 visit_detail_id,
       c.code condition_source_value,
       srctosrcvm.SOURCE_CONCEPT_ID condition_source_concept_id,
       NULL condition_status_source_value,
       0 condition_status_concept_id
FROM [synthea].conditions c
    JOIN [helper].source_to_standard_vocab_map srctostdvm
        ON srctostdvm.SOURCE_CODE = c.code
           AND srctostdvm.TARGET_DOMAIN_ID = 'Condition'
           AND srctostdvm.TARGET_VOCABULARY_ID = 'SNOMED'
           AND srctostdvm.SOURCE_VOCABULARY_ID = 'SNOMED'
           AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
           AND srctostdvm.TARGET_INVALID_REASON IS NULL
    JOIN [helper].source_to_source_vocab_map srctosrcvm
        ON srctosrcvm.SOURCE_CODE = c.code
           AND srctosrcvm.SOURCE_VOCABULARY_ID = 'SNOMED'
           AND srctosrcvm.SOURCE_DOMAIN_ID = 'Condition'
    LEFT JOIN [helper].FINAL_VISIT_IDS fv
        ON fv.encounter_id = c.encounter
    JOIN [omop].PERSON p
        ON c.patient = p.PERSON_SOURCE_VALUE;

