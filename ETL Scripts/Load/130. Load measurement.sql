INSERT INTO [omop].MEASUREMENT
(
    MEASUREMENT_ID,
    PERSON_ID,
    MEASUREMENT_CONCEPT_ID,
    MEASUREMENT_DATE,
    MEASUREMENT_DATETIME,
    MEASUREMENT_TIME,
    MEASUREMENT_TYPE_CONCEPT_ID,
    OPERATOR_CONCEPT_ID,
    VALUE_AS_NUMBER,
    VALUE_AS_CONCEPT_ID,
    UNIT_CONCEPT_ID,
    RANGE_LOW,
    RANGE_HIGH,
    PROVIDER_ID,
    VISIT_OCCURRENCE_ID,
    VISIT_DETAIL_ID,
    MEASUREMENT_SOURCE_VALUE,
    MEASUREMENT_SOURCE_CONCEPT_ID,
    UNIT_SOURCE_VALUE,
    VALUE_SOURCE_VALUE
)
SELECT ROW_NUMBER() OVER (ORDER BY person_id) measurement_id,
       person_id,
       measurement_concept_id,
       measurement_date,
       measurement_datetime,
       measurement_time,
       measurement_type_concept_id,
       operator_concept_id,
       value_as_number,
       value_as_concept_id,
       unit_concept_id,
       range_low,
       range_high,
       provider_id,
       visit_occurrence_id,
       visit_detail_id,
       measurement_source_value,
       measurement_source_concept_id,
       unit_source_value,
       value_source_value
FROM
(
    SELECT p.PERSON_ID person_id,
           srctostdvm.TARGET_CONCEPT_ID measurement_concept_id,
           pr.date measurement_date,
           pr.date measurement_datetime,
           pr.date measurement_time,
           38000267 measurement_type_concept_id,
           0 operator_concept_id,
           CAST(NULL AS FLOAT) value_as_number,
           0 value_as_concept_id,
           0 unit_concept_id,
           CAST(NULL AS FLOAT) range_low,
           CAST(NULL AS FLOAT) range_high,
           0 provider_id,
           fv.VISIT_OCCURRENCE_ID_NEW visit_occurrence_id,
           fv.VISIT_OCCURRENCE_ID_NEW + 1000000 visit_detail_id,
           pr.code measurement_source_value,
           srctosrcvm.SOURCE_CONCEPT_ID measurement_source_concept_id,
           CAST(NULL AS VARCHAR) unit_source_value,
           CAST(NULL AS VARCHAR) value_source_value
    FROM [synthea].procedures pr
        JOIN [omop].source_to_standard_vocab_map srctostdvm
            ON srctostdvm.SOURCE_CODE = pr.code
               AND srctostdvm.TARGET_DOMAIN_ID = 'Measurement'
               AND srctostdvm.SOURCE_VOCABULARY_ID = 'SNOMED'
               AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
               AND srctostdvm.TARGET_INVALID_REASON IS NULL
        JOIN [omop].source_to_source_vocab_map srctosrcvm
            ON srctosrcvm.SOURCE_CODE = pr.code
               AND srctosrcvm.SOURCE_VOCABULARY_ID = 'SNOMED'
        LEFT JOIN [omop].FINAL_VISIT_IDS fv
            ON fv.encounter_id = pr.encounter
        JOIN [omop].PERSON p
            ON p.PERSON_SOURCE_VALUE = pr.patient
    UNION ALL
    SELECT p.PERSON_ID person_id,
           srctostdvm.TARGET_CONCEPT_ID measurement_concept_id,
           o.date measurement_date,
           o.date measurement_datetime,
           o.date measurement_time,
           38000267 measurement_type_concept_id,
           0 operator_concept_id,
           CASE
               WHEN ISNUMERIC(o.value) = 1 THEN
                   CAST(o.value AS FLOAT)
               ELSE
                   CAST(NULL AS FLOAT)
           END value_as_number,
           COALESCE(srcmap2.TARGET_CONCEPT_ID, 0) value_as_concept_id,
           COALESCE(srcmap1.TARGET_CONCEPT_ID, 0) unit_concept_id,
           CAST(NULL AS FLOAT) range_low,
           CAST(NULL AS FLOAT) range_high,
           0 provider_id,
           fv.VISIT_OCCURRENCE_ID_NEW visit_occurrence_id,
           fv.VISIT_OCCURRENCE_ID_NEW + 1000000 visit_detail_id,
           o.code measurement_source_value,
           COALESCE(srctosrcvm.SOURCE_CONCEPT_ID, 0) measurement_source_concept_id,
           o.units unit_source_value,
           o.value value_source_value
    FROM [synthea].observations o
        JOIN [omop].source_to_standard_vocab_map srctostdvm
            ON srctostdvm.SOURCE_CODE = o.code
               AND srctostdvm.TARGET_DOMAIN_ID = 'Measurement'
               AND srctostdvm.SOURCE_VOCABULARY_ID = 'LOINC'
               AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
               AND srctostdvm.TARGET_INVALID_REASON IS NULL
        LEFT JOIN [omop].source_to_standard_vocab_map srcmap1
            ON srcmap1.SOURCE_CODE = o.units
               AND srcmap1.TARGET_VOCABULARY_ID = 'UCUM'
               AND srcmap1.SOURCE_VOCABULARY_ID = 'UCUM'
               AND srcmap1.TARGET_STANDARD_CONCEPT = 'S'
               AND srcmap1.TARGET_INVALID_REASON IS NULL
        LEFT JOIN [omop].source_to_standard_vocab_map srcmap2
            ON srcmap2.SOURCE_CODE = o.value
               AND srcmap2.TARGET_DOMAIN_ID = 'Meas value'
               AND srcmap2.TARGET_STANDARD_CONCEPT = 'S'
               AND srcmap2.TARGET_INVALID_REASON IS NULL
        LEFT JOIN [omop].source_to_source_vocab_map srctosrcvm
            ON srctosrcvm.SOURCE_CODE = o.code
               AND srctosrcvm.SOURCE_VOCABULARY_ID = 'LOINC'
        LEFT JOIN [omop].FINAL_VISIT_IDS fv
            ON fv.encounter_id = o.encounter
        JOIN [omop].PERSON p
            ON p.PERSON_SOURCE_VALUE = o.patient
) tmp;
