INSERT INTO [omop].VISIT_OCCURRENCE
(
    VISIT_OCCURRENCE_ID,
    PERSON_ID,
    VISIT_CONCEPT_ID,
    VISIT_START_DATE,
    VISIT_START_DATETIME,
    VISIT_END_DATE,
    VISIT_END_DATETIME,
    VISIT_TYPE_CONCEPT_ID,
    PROVIDER_ID,
    CARE_SITE_ID,
    VISIT_SOURCE_VALUE,
    VISIT_SOURCE_CONCEPT_ID,
    ADMITTING_SOURCE_CONCEPT_ID,
    ADMITTING_SOURCE_VALUE,
    DISCHARGE_TO_CONCEPT_ID,
    DISCHARGE_TO_SOURCE_VALUE,
    PRECEDING_VISIT_OCCURRENCE_ID
)
SELECT av.visit_occurrence_id,
       p.person_id,
       CASE LOWER(av.encounterclass)
           WHEN 'ambulatory' THEN
               9202
           WHEN 'emergency' THEN
               9203
           WHEN 'inpatient' THEN
               9201
           WHEN 'wellness' THEN
               9202
           WHEN 'urgentcare' THEN
               9203
           WHEN 'outpatient' THEN
               9202
           ELSE
               0
       END,
       av.visit_start_date,
       av.visit_start_date,
       av.visit_end_date,
       av.visit_end_date,
       44818517,
       NULL,
       NULL,
       av.encounter_id,
       0,
       0,
       NULL,
       0,
       NULL,
       lag(av.visit_occurrence_id) OVER (partition BY p.person_id ORDER BY av.visit_start_date)
FROM [omop].all_visits av
    JOIN [omop].person p
        ON av.patient = p.person_source_value
WHERE av.visit_occurrence_id IN
      (
          SELECT DISTINCT VISIT_OCCURRENCE_ID_NEW FROM [omop].FINAL_VISIT_IDS
      );