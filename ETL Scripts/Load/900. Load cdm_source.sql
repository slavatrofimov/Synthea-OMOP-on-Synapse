INSERT INTO [omop].CDM_SOURCE
(
    CDM_SOURCE_NAME,
    CDM_SOURCE_ABBREVIATION,
    CDM_HOLDER,
    SOURCE_DESCRIPTION,
    SOURCE_DOCUMENTATION_REFERENCE,
    CDM_ETL_REFERENCE,
    SOURCE_RELEASE_DATE,
    CDM_RELEASE_DATE,
    CDM_VERSION,
    VOCABULARY_VERSION
)
SELECT 'Synthea synthetic health database',
       'Synthea',
       'OHDSI Community',
       'SyntheaTM is a Synthetic Patient Population Simulator. The goal is to output synthetic, realistic (but not real), patient data and associated health records in a variety of formats.',
       'https://synthetichealth.github.io/synthea/',
       'https://github.com/slavatrofimov/Synthea-OMOP-on-Synapse',
       GETDATE(), -- NB: Set this value to the day the source data was pulled
       GETDATE(),
       'v5.3',
       VOCABULARY_VERSION
FROM [vocab].VOCABULARY
WHERE VOCABULARY_ID = 'None';
