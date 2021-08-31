INSERT INTO [omop].PROCEDURE_OCCURRENCE
(
    PROCEDURE_OCCURRENCE_ID,
    PERSON_ID,
    PROCEDURE_CONCEPT_ID,
    PROCEDURE_DATE,
    PROCEDURE_DATETIME,
    PROCEDURE_TYPE_CONCEPT_ID,
    MODIFIER_CONCEPT_ID,
    QUANTITY,
    PROVIDER_ID,
    VISIT_OCCURRENCE_ID,
    VISIT_DETAIL_ID,
    PROCEDURE_SOURCE_VALUE,
    PROCEDURE_SOURCE_CONCEPT_ID,
    MODIFIER_SOURCE_VALUE
)
SELECT ROW_NUMBER() OVER (ORDER BY p.PERSON_ID) procedure_occurrence_id,
       p.PERSON_ID person_id,
       srctostdvm.TARGET_CONCEPT_ID procedure_concept_id,
       pr.date procedure_date,
       pr.date procedure_datetime,
       38000267 procedure_type_concept_id,
       0 modifier_concept_id,
       CAST(NULL AS INTEGER) quantity,
       CAST(NULL AS INTEGER) provider_id,
       fv.VISIT_OCCURRENCE_ID_NEW visit_occurrence_id,
       fv.VISIT_OCCURRENCE_ID_NEW + 1000000 visit_detail_id,
       pr.code procedure_source_value,
       srctosrcvm.SOURCE_CONCEPT_ID procedure_source_concept_id,
       NULL modifier_source_value
FROM [synthea].procedures pr
    JOIN [omop].source_to_standard_vocab_map srctostdvm
        ON srctostdvm.SOURCE_CODE = pr.code
           AND srctostdvm.TARGET_DOMAIN_ID = 'Procedure'
           AND srctostdvm.TARGET_VOCABULARY_ID = 'SNOMED'
           AND srctostdvm.SOURCE_VOCABULARY_ID = 'SNOMED'
           AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
           AND srctostdvm.TARGET_INVALID_REASON IS NULL
    JOIN [omop].source_to_source_vocab_map srctosrcvm
        ON srctosrcvm.SOURCE_CODE = pr.code
           AND srctosrcvm.SOURCE_VOCABULARY_ID = 'SNOMED'
    LEFT JOIN [omop].FINAL_VISIT_IDS fv
        ON fv.encounter_id = pr.encounter
    JOIN [omop].PERSON p
        ON p.PERSON_SOURCE_VALUE = pr.patient;
