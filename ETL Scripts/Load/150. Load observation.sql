INSERT INTO [omop].OBSERVATION
(
    OBSERVATION_ID,
    PERSON_ID,
    OBSERVATION_CONCEPT_ID,
    OBSERVATION_DATE,
    OBSERVATION_DATETIME,
    OBSERVATION_TYPE_CONCEPT_ID,
    VALUE_AS_NUMBER,
    VALUE_AS_STRING,
    VALUE_AS_CONCEPT_ID,
    QUALIFIER_CONCEPT_ID,
    UNIT_CONCEPT_ID,
    PROVIDER_ID,
    VISIT_OCCURRENCE_ID,
    VISIT_DETAIL_ID,
    OBSERVATION_SOURCE_VALUE,
    OBSERVATION_SOURCE_CONCEPT_ID,
    UNIT_SOURCE_VALUE,
    QUALIFIER_SOURCE_VALUE
)
SELECT ROW_NUMBER() OVER (ORDER BY person_id) observation_id,
       person_id,
       observation_concept_id,
       observation_date,
       observation_datetime,
       observation_type_concept_id,
       value_as_number,
       value_as_string,
       value_as_concept_id,
       qualifier_concept_id,
       unit_concept_id,
       provider_id,
       visit_occurrence_id,
       visit_detail_id,
       observation_source_value,
       observation_source_concept_id,
       unit_source_value,
       qualifier_source_value
FROM
(
    SELECT p.PERSON_ID person_id,
           srctostdvm.TARGET_CONCEPT_ID observation_concept_id,
           a.start observation_date,
           a.start observation_datetime,
           38000280 observation_type_concept_id,
           CAST(NULL AS NUMERIC) value_as_number,
           CAST(NULL AS VARCHAR) value_as_string,
           0 value_as_concept_id,
           0 qualifier_concept_id,
           0 unit_concept_id,
           CAST(NULL AS BIGINT) provider_id,
           fv.VISIT_OCCURRENCE_ID_NEW visit_occurrence_id,
           fv.VISIT_OCCURRENCE_ID_NEW + 1000000 visit_detail_id,
           a.code observation_source_value,
           srctosrcvm.SOURCE_CONCEPT_ID observation_source_concept_id,
           CAST(NULL AS VARCHAR) unit_source_value,
           CAST(NULL AS VARCHAR) qualifier_source_value
    FROM [synthea].allergies a
        JOIN [helper].source_to_standard_vocab_map srctostdvm
            ON srctostdvm.SOURCE_CODE = a.code
               AND srctostdvm.TARGET_DOMAIN_ID = 'Observation'
               AND srctostdvm.TARGET_VOCABULARY_ID = 'SNOMED'
               AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
               AND srctostdvm.TARGET_INVALID_REASON IS NULL
        JOIN [helper].source_to_source_vocab_map srctosrcvm
            ON srctosrcvm.SOURCE_CODE = a.code
               AND srctosrcvm.SOURCE_VOCABULARY_ID = 'SNOMED'
               AND srctosrcvm.SOURCE_DOMAIN_ID = 'Observation'
        LEFT JOIN [helper].FINAL_VISIT_IDS fv
            ON fv.encounter_id = a.encounter
        JOIN [omop].PERSON p
            ON p.PERSON_SOURCE_VALUE = a.patient
    UNION ALL
    SELECT p.PERSON_ID person_id,
           srctostdvm.TARGET_CONCEPT_ID observation_concept_id,
           c.start observation_date,
           c.start observation_datetime,
           38000280 observation_type_concept_id,
           CAST(NULL AS NUMERIC) value_as_number,
           CAST(NULL AS VARCHAR) value_as_string,
           0 value_as_concept_id,
           0 qualifier_concept_id,
           0 unit_concept_id,
           CAST(NULL AS BIGINT) provider_id,
           fv.VISIT_OCCURRENCE_ID_NEW visit_occurrence_id,
           fv.VISIT_OCCURRENCE_ID_NEW + 1000000 visit_detail_id,
           c.code observation_source_value,
           srctosrcvm.SOURCE_CONCEPT_ID observation_source_concept_id,
           CAST(NULL AS VARCHAR) unit_source_value,
           CAST(NULL AS VARCHAR) qualifier_source_value
    FROM [synthea].conditions c
        JOIN [helper].source_to_standard_vocab_map srctostdvm
            ON srctostdvm.SOURCE_CODE = c.code
               AND srctostdvm.TARGET_DOMAIN_ID = 'Observation'
               AND srctostdvm.TARGET_VOCABULARY_ID = 'SNOMED'
               AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
               AND srctostdvm.TARGET_INVALID_REASON IS NULL
        JOIN [helper].source_to_source_vocab_map srctosrcvm
            ON srctosrcvm.SOURCE_CODE = c.code
               AND srctosrcvm.SOURCE_VOCABULARY_ID = 'SNOMED'
               AND srctosrcvm.SOURCE_DOMAIN_ID = 'Observation'
        LEFT JOIN [helper].FINAL_VISIT_IDS fv
            ON fv.encounter_id = c.encounter
        JOIN [omop].PERSON p
            ON p.PERSON_SOURCE_VALUE = c.patient
    UNION ALL
    SELECT p.PERSON_ID person_id,
           srctostdvm.TARGET_CONCEPT_ID observation_concept_id,
           o.date observation_date,
           o.date observation_datetime,
           38000280 observation_type_concept_id,
           CAST(NULL AS NUMERIC) value_as_number,
           CAST(NULL AS VARCHAR) value_as_string,
           0 value_as_concept_id,
           0 qualifier_concept_id,
           0 unit_concept_id,
           CAST(NULL AS BIGINT) provider_id,
           fv.VISIT_OCCURRENCE_ID_NEW visit_occurrence_id,
           fv.VISIT_OCCURRENCE_ID_NEW + 1000000 visit_detail_id,
           o.code observation_source_value,
           srctosrcvm.SOURCE_CONCEPT_ID observation_source_concept_id,
           CAST(NULL AS VARCHAR) unit_source_value,
           CAST(NULL AS VARCHAR) qualifier_source_value
    FROM [synthea].observations o
        JOIN [helper].source_to_standard_vocab_map srctostdvm
            ON srctostdvm.SOURCE_CODE = o.code
               AND srctostdvm.TARGET_DOMAIN_ID = 'Observation'
               AND srctostdvm.TARGET_VOCABULARY_ID = 'LOINC'
               AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
               AND srctostdvm.TARGET_INVALID_REASON IS NULL
        JOIN [helper].source_to_source_vocab_map srctosrcvm
            ON srctosrcvm.SOURCE_CODE = o.code
               AND srctosrcvm.SOURCE_VOCABULARY_ID = 'LOINC'
               AND srctosrcvm.SOURCE_DOMAIN_ID = 'Observation'
        LEFT JOIN [helper].FINAL_VISIT_IDS fv
            ON fv.encounter_id = o.encounter
        JOIN [omop].PERSON p
            ON p.PERSON_SOURCE_VALUE = o.patient
) tmp;
