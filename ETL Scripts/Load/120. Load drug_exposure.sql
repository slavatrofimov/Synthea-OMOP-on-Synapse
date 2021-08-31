INSERT INTO [omop].DRUG_EXPOSURE
(
    DRUG_EXPOSURE_ID,
    PERSON_ID,
    DRUG_CONCEPT_ID,
    DRUG_EXPOSURE_START_DATE,
    DRUG_EXPOSURE_START_DATETIME,
    DRUG_EXPOSURE_END_DATE,
    DRUG_EXPOSURE_END_DATETIME,
    VERBATIM_END_DATE,
    DRUG_TYPE_CONCEPT_ID,
    STOP_REASON,
    REFILLS,
    QUANTITY,
    DAYS_SUPPLY,
    SIG,
    ROUTE_CONCEPT_ID,
    LOT_NUMBER,
    PROVIDER_ID,
    VISIT_OCCURRENCE_ID,
    VISIT_DETAIL_ID,
    DRUG_SOURCE_VALUE,
    DRUG_SOURCE_CONCEPT_ID,
    ROUTE_SOURCE_VALUE,
    DOSE_UNIT_SOURCE_VALUE
)
SELECT ROW_NUMBER() OVER (ORDER BY person_id) drug_exposure_id,
       person_id,
       drug_concept_id,
       drug_exposure_start_date,
       drug_exposure_start_datetime,
       drug_exposure_end_date,
       drug_exposure_end_datetime,
       verbatim_end_date,
       drug_type_concept_id,
       stop_reason,
       refills,
       quantity,
       days_supply,
       sig,
       route_concept_id,
       lot_number,
       provider_id,
       visit_occurrence_id,
       visit_detail_id,
       drug_source_value,
       drug_source_concept_id,
       route_source_value,
       dose_unit_source_value
FROM
(
    SELECT p.PERSON_ID person_id,
           srctostdvm.TARGET_CONCEPT_ID drug_concept_id,
           m.start drug_exposure_start_date,
           m.start drug_exposure_start_datetime,
           COALESCE(m.stop, m.start) drug_exposure_end_date,
           COALESCE(m.stop, m.start) drug_exposure_end_datetime,
           m.stop verbatim_end_date,
           38000175 drug_type_concept_id,
           CAST(NULL AS VARCHAR) stop_reason,
           0 refills,
           0 quantity,
           COALESCE(DATEDIFF(DAY, m.start, m.stop), 0) days_supply,
           CAST(NULL AS VARCHAR) sig,
           0 route_concept_id,
           0 lot_number,
           0 provider_id,
           fv.VISIT_OCCURRENCE_ID_NEW visit_occurrence_id,
           fv.VISIT_OCCURRENCE_ID_NEW + 1000000 visit_detail_id,
           m.code drug_source_value,
           srctosrcvm.SOURCE_CONCEPT_ID drug_source_concept_id,
           CAST(NULL AS VARCHAR) route_source_value,
           CAST(NULL AS VARCHAR) dose_unit_source_value
    FROM [synthea].medications m
        JOIN [omop].source_to_standard_vocab_map srctostdvm
            ON srctostdvm.SOURCE_CODE = m.code
               AND srctostdvm.TARGET_DOMAIN_ID = 'Drug'
               AND srctostdvm.TARGET_VOCABULARY_ID = 'RxNorm'
               AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
               AND srctostdvm.TARGET_INVALID_REASON IS NULL
        JOIN [omop].source_to_source_vocab_map srctosrcvm
            ON srctosrcvm.SOURCE_CODE = m.code
               AND srctosrcvm.SOURCE_VOCABULARY_ID = 'RxNorm'
        LEFT JOIN [omop].FINAL_VISIT_IDS fv
            ON fv.encounter_id = m.encounter
        JOIN [omop].PERSON p
            ON p.PERSON_SOURCE_VALUE = m.patient
    UNION ALL
    SELECT p.PERSON_ID person_id,
           srctostdvm.TARGET_CONCEPT_ID drug_concept_id,
           i.date drug_exposure_start_date,
           i.date drug_exposure_start_datetime,
           i.date drug_exposure_end_date,
           i.date drug_exposure_end_datetime,
           i.date verbatim_end_date,
           38000175 drug_type_concept_id,
           CAST(NULL AS VARCHAR) stop_reason,
           0 refills,
           0 quantity,
           0 days_supply,
           CAST(NULL AS VARCHAR) sig,
           0 route_concept_id,
           0 lot_number,
           0 provider_id,
           fv.VISIT_OCCURRENCE_ID_NEW visit_occurrence_id,
           fv.VISIT_OCCURRENCE_ID_NEW + 1000000 visit_detail_id,
           i.code drug_source_value,
           srctosrcvm.SOURCE_CONCEPT_ID drug_source_concept_id,
           CAST(NULL AS VARCHAR) route_source_value,
           CAST(NULL AS VARCHAR) dose_unit_source_value
    FROM [synthea].immunizations i
        JOIN [omop].source_to_standard_vocab_map srctostdvm
            ON srctostdvm.SOURCE_CODE = i.code
               AND srctostdvm.TARGET_DOMAIN_ID = 'Drug'
               AND srctostdvm.TARGET_VOCABULARY_ID = 'CVX'
               AND srctostdvm.TARGET_STANDARD_CONCEPT = 'S'
               AND srctostdvm.TARGET_INVALID_REASON IS NULL
        JOIN [omop].source_to_source_vocab_map srctosrcvm
            ON srctosrcvm.SOURCE_CODE = i.code
               AND srctosrcvm.SOURCE_VOCABULARY_ID = 'CVX'
        LEFT JOIN [omop].FINAL_VISIT_IDS fv
            ON fv.encounter_id = i.encounter
        JOIN [omop].PERSON p
            ON p.PERSON_SOURCE_VALUE = i.patient
) tmp;
