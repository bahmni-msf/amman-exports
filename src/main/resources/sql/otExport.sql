SELECT
  sa.patient_id AS `patient_id`,
  DATE_FORMAT(sb.start_datetime, '%d/%m/%Y') AS `date_of_surgery`,
  CONCAT(
    '\"',
    DATE_FORMAT(
      ADDDATE(
        sb.start_datetime,
        INTERVAL
        CASE
          WHEN (
            IFNULL(SUM(IFNULL(estTimeHours.value * 60, 0)), 0) +
            IFNULL(SUM(IFNULL(estTimeMinutes.value, 0)), 0) +
            IFNULL(SUM(IFNULL(surgeries.cleaningTime, 0)), 0)
          ) IS NULL THEN 0
          ELSE (
            IFNULL(SUM(IFNULL(estTimeHours.value * 60, 0)), 0) +
            IFNULL(SUM(IFNULL(estTimeMinutes.value, 0)), 0) +
            IFNULL(SUM(IFNULL(surgeries.cleaningTime, 0)), 0)
          )
        END
        MINUTE
      ),
      '%h:%i %p'
    ),
    '\"'
  ) AS `surgery_start_time`,
  CONCAT(
    '\"',
    (
      IFNULL(SUM(IFNULL(estTimeHours.value * 60, 0)), 0) +
      IFNULL(SUM(IFNULL(estTimeMinutes.value, 0)), 0) +
      IFNULL(SUM(IFNULL(surgeries.cleaningTime, 0)), 0)
    ),
    '\"'
  ) AS `surgery_est_time`,
  DATE_FORMAT(sa.actual_start_datetime, '%d %b %Y %h:%i %p') AS `surgery_actual_start_time`,
  DATE_FORMAT(sa.actual_end_datetime, '%d %b %Y %h:%i %p') AS `surgery_actual_end_time`,
  CONCAT('\"', TIMESTAMPDIFF(MINUTE, sa.actual_start_datetime, sa.actual_end_datetime), '\"') AS `surgery_actual_time`,
  DATE_FORMAT(sa.date_changed, '%d/%m/%Y') AS `last_date_modified`,
  l.name AS `ot`,
  CONCAT('\"', surgeries.procedureInfo_value, '\"') AS `procedures`,
  CONCAT('\"', notes.value, '\"') AS `surgery_notes`,
  CONCAT('\"', CONCAT(pn.given_name, ' ', pn.family_name), '\"') AS `surgeon`,
  otherSurgeon.name AS `other_surgeon`,
  CONCAT('\"', surgicalAssistant.value, '\"') AS `surgical_assistant`,
  CONCAT('\"', anaesthetist.value, '\"') AS `anaesthetist`,
  CONCAT('\"', scrubNurse.value, '\"') AS `scrub_nurse`,
  CONCAT('\"', circulatingNurse.value, '\"') AS `circulating_nurse`,
  sa.status AS `surgery_status`,
  CONCAT('\"', sa.notes, '\"') AS `status_change_notes`
FROM surgical_appointment sa
  INNER JOIN surgical_block sb ON sa.surgical_block_id = sb.surgical_block_id
  INNER JOIN location l ON sb.location_id = l.location_id
  INNER JOIN provider p ON sb.primary_provider_id = p.provider_id
  INNER JOIN person_name pn ON p.person_id = pn.person_id
  LEFT OUTER JOIN (
    SELECT
      sa.sort_weight,
      sa.surgical_appointment_id,
      sa.surgical_block_id,
      IFNULL(cleaningTime.value, 0) AS `cleaningTime`,
      IFNULL(estTimeMinutes.value, 0) AS `estTimeMinutes`,
      IFNULL(estTimeHours.value, 0) AS `estTimeHours`,
      IFNULL(procedureInfo.value, '') AS `procedureInfo_value`
    FROM surgical_appointment sa
      LEFT OUTER JOIN (
        SELECT IFNULL(saa.value, 0) AS `value`, saa.surgical_appointment_id
        FROM surgical_appointment_attribute saa
          INNER JOIN surgical_appointment_attribute_type saat ON
            saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
          AND saat.name = 'cleaningTime'
      ) cleaningTime ON sa.surgical_appointment_id = cleaningTime.surgical_appointment_id
      LEFT OUTER JOIN (
        SELECT IFNULL(saa.value, 0) AS `value`, saa.surgical_appointment_id
        FROM surgical_appointment_attribute saa
          INNER JOIN surgical_appointment_attribute_type saat ON
            saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
          AND saat.name = 'estTimeMinutes'
      ) estTimeMinutes ON sa.surgical_appointment_id = estTimeMinutes.surgical_appointment_id
      LEFT OUTER JOIN (
        SELECT IFNULL(saa.value, 0) AS `value`, saa.surgical_appointment_id
        FROM surgical_appointment_attribute saa
          INNER JOIN surgical_appointment_attribute_type saat ON
            saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
          AND saat.name = 'estTimeHours'
      ) estTimeHours ON sa.surgical_appointment_id = estTimeHours.surgical_appointment_id
      LEFT OUTER JOIN (
        SELECT IFNULL(saa.value, '') AS `value`, saa.surgical_appointment_id
        FROM surgical_appointment_attribute saa
          INNER JOIN surgical_appointment_attribute_type saat ON
            saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
          AND saat.name = 'procedure'
      ) procedureInfo ON procedureInfo.surgical_appointment_id = sa.surgical_appointment_id
  ) surgeries ON sa.surgical_block_id = surgeries.surgical_block_id AND surgeries.sort_weight < sa.sort_weight
LEFT OUTER JOIN (
  SELECT saa.surgical_appointment_id, IFNULL(saa.value, '') AS `value`
  FROM surgical_appointment_attribute saa
    INNER JOIN surgical_appointment_attribute_type saat ON
      saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
    AND saat.name = 'notes'
) notes ON notes.surgical_appointment_id = sa.surgical_appointment_id
LEFT OUTER JOIN (
  SELECT saa.surgical_appointment_id, IFNULL(saa.value, 0) AS `value`
  FROM surgical_appointment_attribute saa
    INNER JOIN surgical_appointment_attribute_type saat ON
      saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
    AND saat.name = 'estTimeHours'
) estTimeHours ON estTimeHours.surgical_appointment_id = sa.surgical_appointment_id
LEFT OUTER JOIN (
  SELECT saa.surgical_appointment_id, IFNULL(saa.value, 0) AS `value`
  FROM surgical_appointment_attribute saa
    INNER JOIN surgical_appointment_attribute_type saat ON
      saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
    AND saat.name = 'estTimeMinutes'
) estTimeMinutes ON estTimeMinutes.surgical_appointment_id = sa.surgical_appointment_id
LEFT OUTER JOIN (
  SELECT saa.surgical_appointment_id, IFNULL(saa.value, 0) AS `value`
  FROM surgical_appointment_attribute saa
    INNER JOIN surgical_appointment_attribute_type saat ON
      saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
    AND saat.name = 'cleaningTime'
) cleaningTime ON cleaningTime.surgical_appointment_id = sa.surgical_appointment_id
LEFT OUTER JOIN (
  SELECT saa.surgical_appointment_id, CONCAT(pn.given_name, ' ', pn.family_name) AS `name`
  FROM surgical_appointment_attribute saa
    INNER JOIN surgical_appointment_attribute_type saat ON
      saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
    AND saat.name = 'otherSurgeon'
    INNER JOIN provider p ON saa.value = p.provider_id AND NULLIF(saa.value, '') IS NOT NULL
    INNER JOIN person_name pn ON p.person_id = pn.person_id
) otherSurgeon ON otherSurgeon.surgical_appointment_id = sa.surgical_appointment_id
LEFT OUTER JOIN (
  SELECT saa.surgical_appointment_id, IFNULL(saa.value, '') AS `value`
  FROM surgical_appointment_attribute saa
    INNER JOIN surgical_appointment_attribute_type saat ON
      saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
    AND saat.name = 'surgicalAssistant'
) surgicalAssistant ON surgicalAssistant.surgical_appointment_id = sa.surgical_appointment_id
LEFT OUTER JOIN (
  SELECT saa.surgical_appointment_id, IFNULL(saa.value, '') AS `value`
  FROM surgical_appointment_attribute saa
    INNER JOIN surgical_appointment_attribute_type saat ON
      saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
    AND saat.name = 'anaesthetist'
) anaesthetist ON anaesthetist.surgical_appointment_id = sa.surgical_appointment_id
LEFT OUTER JOIN (
  SELECT saa.surgical_appointment_id, IFNULL(saa.value, '') AS `value`
  FROM surgical_appointment_attribute saa
    INNER JOIN surgical_appointment_attribute_type saat ON
      saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
    AND saat.name = 'scrubNurse'
) scrubNurse ON scrubNurse.surgical_appointment_id = sa.surgical_appointment_id
LEFT OUTER JOIN (
  SELECT saa.surgical_appointment_id, IFNULL(saa.value, '') AS `value`
  FROM surgical_appointment_attribute saa
    INNER JOIN surgical_appointment_attribute_type saat ON
      saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id
    AND saat.name = 'circulatingNurse'
) circulatingNurse ON circulatingNurse.surgical_appointment_id = sa.surgical_appointment_id
GROUP BY
  sa.surgical_block_id,
  sa.surgical_appointment_id,
  sb.start_datetime,
  sa.actual_start_datetime,
  sa.actual_end_datetime,
  sa.date_changed,
  l.name,
  surgeries.procedureInfo_value,
  notes.value,
  pn.given_name,
  pn.family_name,
  otherSurgeon.name,
  surgicalAssistant.value,
  anaesthetist.value,
  scrubNurse.value,
  circulatingNurse.value,
  sa.status,
  sa.notes
ORDER BY sa.patient_id;
