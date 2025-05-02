CREATE OR REPLACE VIEW vw_cleaned_requests AS
SELECT
    case_enquiry_id,
    open_dt::timestamp,
    closed_dt::timestamp,
    sla_target_dt::timestamp,
    department,
    subject,
    reason,
    case_title,
    case_status,
    on_time,
    neighborhood,
    ward,
    latitude,
    longitude,
    source,

    EXTRACT(EPOCH FROM (closed_dt - open_dt))/3600 AS resolution_time_hrs,
    CASE WHEN on_time = 'ONTIME' THEN 1 ELSE 0 END AS sla_met,
    CASE WHEN closed_dt IS NULL THEN 'Open' ELSE 'Closed' END AS current_status,
    DATE_TRUNC('month', open_dt) AS open_month,
    CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN TRUE ELSE FALSE END AS has_geo
	
FROM raw_311_data
WHERE open_dt IS NOT NULL
  AND neighborhood IS NOT NULL
  AND department IS NOT NULL;
