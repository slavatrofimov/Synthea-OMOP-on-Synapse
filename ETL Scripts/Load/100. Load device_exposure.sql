INSERT INTO [omop].DEVICE_EXPOSURE
(
    DEVICE_EXPOSURE_ID,
    PERSON_ID,
    DEVICE_CONCEPT_ID,
    DEVICE_EXPOSURE_START_DATE,
    DEVICE_EXPOSURE_START_DATETIME,
    DEVICE_EXPOSURE_END_DATE,
    DEVICE_EXPOSURE_END_DATETIME,
    DEVICE_TYPE_CONCEPT_ID,
    UNIQUE_DEVICE_ID,
    QUANTITY,
    PROVIDER_ID,
    VISIT_OCCURRENCE_ID,
    VISIT_DETAIL_ID,
    DEVICE_SOURCE_VALUE,
    DEVICE_SOURCE_CONCEPT_ID
)
SELECT ROW_NUMBER() OVER (ORDER BY PERSON_ID) device_exposure_id,
       p.PERSON_ID person_id,
       srctostdvm.TARGET_CONCEPT_ID device_concept_id,
       d.start device_exposure_start_date,
       d.start device_exposure_start_datetime,
       d.stop device_exposure_end_date,
       d.stop device_exposure_end_datetime,
       38000267 device_type_concept_id,
       d.udi unique_device_id,
       CAST(NULL AS INT) quantity,
       CAST(NULL AS INT) provider_id,
       fv.VISIT_OCCURRENCE_ID_NEW visit_occurrence_id,
       fv.VISIT_OCCURRENCE_ID_NEW + 1000000 visit_detail_id,
       d.code device_source_value,
       srctosrcvm.SOURCE_CONCEPT_ID device_source_concept_id
FROM [synthea].devices d
    JOIN [omop].source_to_standard_vocab_map srctostdvm
        ON srctostdvm.SOURCE_CODE = d.code
           AND srctostdvm.TARGET_DOMAIN_ID = 'Device'
           AND srctostdvm.TARGET_VOCABULARY_ID = 'SNOMED'
           AND srctostdvm.SOURCE_VOCABULARY_ID = 'SNOMED'
           AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
           AND srctostdvm.TARGET_INVALID_REASON IS NULL
    JOIN [omop].source_to_source_vocab_map srctosrcvm
        ON srctosrcvm.SOURCE_CODE = d.code
           AND srctosrcvm.SOURCE_VOCABULARY_ID = 'SNOMED'
    LEFT JOIN [omop].FINAL_VISIT_IDS fv
        ON fv.encounter_id = d.encounter
    JOIN [omop].PERSON p
        ON p.PERSON_SOURCE_VALUE = d.patient;


