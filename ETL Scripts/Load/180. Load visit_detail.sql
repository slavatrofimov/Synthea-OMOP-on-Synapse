-- =============================================
-- Create Date: 20210505
-- Description: Insert visit detail
-- For testing purposes, create populate VISIT_DETAIL
-- such that it's basically a copy of VISIT_OCCURRENCE
-- =============================================


INSERT INTO [omop].VISIT_DETAIL
(
    VISIT_DETAIL_ID,
    PERSON_ID,
    VISIT_DETAIL_CONCEPT_ID,
    VISIT_DETAIL_START_DATE,
    VISIT_DETAIL_START_DATETIME,
    VISIT_DETAIL_END_DATE,
    VISIT_DETAIL_END_DATETIME,
    VISIT_DETAIL_TYPE_CONCEPT_ID,
    PROVIDER_ID,
    CARE_SITE_ID,
    ADMITTING_SOURCE_CONCEPT_ID,
    DISCHARGE_TO_CONCEPT_ID,
    PRECEDING_VISIT_DETAIL_ID,
    VISIT_DETAIL_SOURCE_VALUE,
    VISIT_DETAIL_SOURCE_CONCEPT_ID,
    ADMITTING_SOURCE_VALUE,
    DISCHARGE_TO_SOURCE_VALUE,
    VISIT_DETAIL_PARENT_ID,
    VISIT_OCCURRENCE_ID
)
SELECT av.visit_occurrence_id + 1000000 visit_detail_id,
       p.person_id person_id,
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
       END visit_detail_concept_id,
       av.visit_start_date visit_detail_start_date,
       av.visit_start_date visit_detail_start_datetime,
       av.visit_end_date visit_detail_end_date,
       av.visit_end_date visit_detail_end_datetime,
       44818517 visit_detail_type_concept_id,
       NULL provider_id,
       NULL care_site_id,
       0 admitting_source_concept_id,
       0 discharge_to_concept_id,
       lag(av.visit_occurrence_id) OVER (partition BY p.person_id ORDER BY av.visit_start_date) + 1000000 preceding_visit_detail_id,
       av.encounter_id visit_detail_source_value,
       0 visit_detail_source_concept_id,
       NULL admitting_source_value,
       NULL discharge_to_source_value,
       NULL visit_detail_parent_id,
       av.visit_occurrence_id visit_occurrence_id
FROM [omop].all_visits av
    JOIN [omop].person p
        ON av.patient = p.person_source_value
WHERE av.visit_occurrence_id IN
      (
          SELECT DISTINCT VISIT_OCCURRENCE_ID_NEW FROM [omop].FINAL_VISIT_IDS
      );