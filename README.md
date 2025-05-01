# Boston 311 Service Requests: SQL Analytics Case Study

This project analyzes 311 service request data from the City of Boston using advanced SQL to extract operational and service performance insights. Through structured queries and analytical techniques, it examines how city departments handle resident complaints, evaluates resolution efficiency, and identifies which submission channels are most frequently used. The goal is to uncover trends in service delivery, assess departmental workload and compliance with service-level agreements (SLAs), and inform opportunities for operational improvement.

<p align="center">
  <img src="images/boston_311.png" alt="Boston 311 Logo" width="550"/>
</p>

---

## 🔧 Tools & Skills Demonstrated

- PostgreSQL (via pgAdmin)
- **Advanced SQL techniques**:
  - CTEs (Common Table Expressions)
  - Window functions: `RANK()`, `LAG()`, `AVG() OVER`, `FILTER`
  - Aggregations and time-based analysis
  - Query structuring for business storytelling
- Optional visualization in Tableau (to support findings)

---

## 📈 Business Questions & SQL Solutions

Each section below begins with a real-world business question and a summary of the results. The corresponding SQL logic and visualizations are provided in collapsible sections to highlight both the analytical process and the insights derived from the data.


### 1. Which departments meet SLA targets most often, and how long do they take to resolve requests?

This query ranks departments based on their SLA compliance percentage and average resolution time for closed requests.  
It uses conditional aggregation, filtering, and sorting to surface operational performance metrics.

**Result:**  
| department | total_requests | sla_compliance_pct | avg_resolution_time_hrs |
|------------|----------------|---------------------|--------------------------|
| BTDT       | 62912          | 0.63                | 192.85                   |
| PROP       | 2208           | 0.78                | 816.84                   |
| BWSC       | 1495           | 0.80                | 305.11                   |
| ISD        | 14870          | 0.85                | 273.65                   |
| INFO       | 7933           | 0.86                | 150.10                   |
| PWDx       | 123544         | 0.92                | 62.05                    |
| PARK       | 17439          | 0.94                | 686.73                   |
| ANML       | 636            | 0.96                | 44.20                    |
| GEN_       | 10737          | 1.00                | 2.68                     |


<details>
  <summary>🧠 View SQL Code</summary>

```sql
SELECT
    department,
    COUNT(*) AS total_requests,
    ROUND(SUM(sla_met)::decimal / COUNT(*), 2) AS sla_compliance_pct,
    ROUND(AVG(resolution_time_hrs), 2) AS avg_resolution_time_hrs
FROM vw_cleaned_requests
WHERE current_status = 'Closed'
GROUP BY department
HAVING COUNT(*) >= 100
ORDER BY sla_compliance_pct ASC, avg_resolution_time_hrs DESC;
```

</details>
<br>

### 2. How many 311 complaints were submitted each month?

This query counts the number of 311 complaints submitted each month by extracting and grouping by the month from the request date. It helps identify monthly patterns and trends in complaint volume across the year.

**Result:**  
| Month Name   |   Total Requests |
|:-------------|-----------------:|
| January      |            20638 |
| February     |            18697 |
| March        |            22164 |
| April        |            23055 |
| May          |            25011 |
| June         |            26118 |
| July         |            26634 |
| August       |            28909 |
| September    |            28039 |
| October      |            23305 |
| November     |            19859 |
| December     |            20194 |


<details>
  <summary>🧠 View SQL Code</summary>

```sql
SELECT
    TRIM(TO_CHAR(open_dt, 'Month')) AS month_name,
    COUNT(*) AS total_requests
FROM vw_cleaned_requests
GROUP BY month_name, EXTRACT(MONTH FROM open_dt)
ORDER BY EXTRACT(MONTH FROM open_dt);
```

</details>
<br>

### 3. For the most frequently reported 311 service request types, which submission source is most commonly used and what share of the total requests does it represent?

**Result:**  
| Reason                           | Top Source           |   Source Count |   Total Requests |   Source Percentage (%) |
|:---------------------------------|:---------------------|---------------:|-----------------:|------------------------:|
| Enforcement & Abandoned Vehicles | Citizens Connect App |          56844 |            68058 |                   83.52 |
| Street Cleaning                  | Citizens Connect App |          23544 |            49840 |                   47.24 |
| Code Enforcement                 | Citizens Connect App |          27433 |            36745 |                   74.66 |
| Highway Maintenance              | Citizens Connect App |          14900 |            22529 |                   66.14 |
| Trees                            | City Worker App      |           3956 |            12027 |                   32.89 |
| Signs & Signals                  | Citizens Connect App |           7114 |            11295 |                   62.98 |
| Sanitation                       | Constituent Call     |           9683 |            10757 |                   90.02 |
| Needle Program                   | Citizens Connect App |           8660 |            10726 |                   80.74 |
| Recycling                        | Constituent Call     |           6684 |            10690 |                   62.53 |
| Park Maintenance & Safety        | Citizens Connect App |           5133 |             7661 |                   67.00 |


<details>
  <summary>🧠 View SQL Code</summary>

```sql
WITH top_reasons AS (
    SELECT reason, COUNT(*) AS total_requests
    FROM vw_cleaned_requests
    GROUP BY reason
    ORDER BY total_requests DESC
    LIMIT 10
),
source_distribution AS (
    SELECT
        r.reason,
        r.source,
        COUNT(*) AS source_count
    FROM vw_cleaned_requests r
    JOIN top_reasons t ON r.reason = t.reason
    GROUP BY r.reason, r.source
),
ranked_sources AS (
    SELECT *,
        RANK() OVER (PARTITION BY reason ORDER BY source_count DESC) AS source_rank
    FROM source_distribution
)
SELECT
    rs.reason,
    rs.source AS top_source,
    rs.source_count,
    t.total_requests,
    ROUND((rs.source_count::decimal / t.total_requests) * 100, 2) AS source_percentage
FROM ranked_sources rs
JOIN top_reasons t USING(reason)
WHERE rs.source_rank = 1
ORDER BY t.total_requests DESC;
```

</details>
<br>

### 4. Which neighborhoods have the most currently open 311 requests and what’s the average time taken to resolve cases in those neighborhoods?

**Result:**  
| Neighborhood                                 |   Open Requests |   Total Requests |   Avg Resolution Time (hrs) |
|:---------------------------------------------|----------------:|-----------------:|----------------------------:|
| Dorchester                                   |            4769 |            35974 |                      191.1  |
| South Boston / South Boston Waterfront       |            3665 |            23949 |                      101    |
| Roxbury                                      |            2952 |            24841 |                      148.08 |
| Allston / Brighton                           |            2806 |            22779 |                      156.75 |
| Jamaica Plain                                |            2610 |            18214 |                      160.81 |
| East Boston                                  |            2815 |            17411 |                      160.81 |
| South End                                    |            2559 |            20386 |                       79.9  |
| Downtown / Financial District                |            2459 |            15624 |                      126.35 |
| Back Bay                                     |            2274 |            14463 |                      108.75 |
| Boston                                       |            2051 |            12997 |                      123.57 |
| Charlestown                                  |            1700 |             8939 |                      240.7  |
| Roslindale                                   |            1461 |             9322 |                      265.47 |
| Greater Mattapan                             |            1443 |            10096 |                      195.41 |
| West Roxbury                                 |            1375 |             8591 |                      314.1  |
| Hyde Park                                    |            1277 |             9841 |                      238.31 |
| Fenway / Kenmore / Audubon Circle / Longwood |            1157 |             5484 |                      152.76 |
| Beacon Hill                                  |             997 |             9848 |                      102.63 |
| Mission Hill                                 |             554 |             5028 |                      187.9  |
| South Boston                                 |             440 |             2888 |                      148.05 |
| Brighton                                     |             326 |             2019 |                      168.85 |
| Allston                                      |             147 |             1260 |                      119.56 |
| Mattapan                                     |              61 |              651 |                      232.75 |


<details>
  <summary>🧠 View SQL Code</summary>

```sql
SELECT
    neighborhood,
    COUNT(*) FILTER (WHERE current_status = 'Open') AS open_requests,
    COUNT(*) AS total_requests,
    ROUND(AVG(resolution_time_hrs), 2) AS avg_resolution_time_hrs
FROM vw_cleaned_requests
WHERE neighborhood IS NOT NULL
	AND TRIM(neighborhood) <> ''
GROUP BY neighborhood
HAVING COUNT(*) >= 100
ORDER BY open_requests DESC;
```

</details>
<br>

### 5. What are the most common complaint types in each Boston neighborhood?

**Result:**  
| Neighborhood                                 | Top Complaint Type               |   Request Count |
|:---------------------------------------------|:---------------------------------|----------------:|
| South Boston / South Boston Waterfront       | Enforcement & Abandoned Vehicles |           11514 |
| Dorchester                                   | Enforcement & Abandoned Vehicles |            8030 |
| East Boston                                  | Enforcement & Abandoned Vehicles |            5786 |
| South End                                    | Street Cleaning                  |            5501 |
| Allston / Brighton                           | Enforcement & Abandoned Vehicles |            5253 |
| Roxbury                                      | Street Cleaning                  |            4444 |
| Jamaica Plain                                | Enforcement & Abandoned Vehicles |            4420 |
| Boston                                       | Enforcement & Abandoned Vehicles |            4128 |
| Downtown / Financial District                | Enforcement & Abandoned Vehicles |            3837 |
| Back Bay                                     | Street Cleaning                  |            3680 |
| Beacon Hill                                  | Street Cleaning                  |            3453 |
| Charlestown                                  | Enforcement & Abandoned Vehicles |            3132 |
| Roslindale                                   | Enforcement & Abandoned Vehicles |            2065 |
| Greater Mattapan                             | Code Enforcement                 |            1611 |
| Fenway / Kenmore / Audubon Circle / Longwood | Enforcement & Abandoned Vehicles |            1554 |
| Hyde Park                                    | Enforcement & Abandoned Vehicles |            1544 |
| West Roxbury                                 | Enforcement & Abandoned Vehicles |            1110 |
| Mission Hill                                 | Code Enforcement                 |            1010 |
| South Boston                                 | Enforcement & Abandoned Vehicles |            1010 |
| Brighton                                     | Enforcement & Abandoned Vehicles |             517 |
| Allston                                      | Enforcement & Abandoned Vehicles |             262 |
| Mattapan                                     | Code Enforcement                 |              98 |
| Chestnut Hill                                | Code Enforcement                 |               4 |


<details>
  <summary>🧠 View SQL Code</summary>

```sql
WITH complaint_counts AS (
    SELECT
        neighborhood,
        reason,
        COUNT(*) AS request_count
    FROM vw_cleaned_requests
    WHERE neighborhood IS NOT NULL
      AND TRIM(neighborhood) <> ''
    GROUP BY neighborhood, reason
),
ranked_complaints AS (
    SELECT *,
           RANK() OVER (PARTITION BY neighborhood ORDER BY request_count DESC) AS reason_rank
    FROM complaint_counts
)
SELECT
    neighborhood,
    reason AS top_complaint_type,
    request_count
FROM ranked_complaints
WHERE reason_rank = 1
ORDER BY request_count DESC;
```

</details>
<br>

### 6. Which 311 complaint types take the longest to resolve on average?

**Result:**  
| Reason                                  | Total Requests | Avg Resolution Time (hrs) |
|-----------------------------------------|----------------|----------------------------|
| Trees                                   | 10,300         | 1071.16                    |
| Graffiti                                | 2,132          | 800.66                     |
| Traffic Management & Engineering        | 635            | 688.86                     |
| Street Lights                           | 5,274          | 546.54                     |
| Building                                | 3,746          | 464.10                     |
| Housing                                 | 5,044          | 397.06                     |
| Administrative & General Requests       | 1,766          | 381.49                     |
| Notification                            | 433            | 359.57                     |
| Catchbasin                              | 298            | 314.21                     |
| Sidewalk Cover / Manhole                | 193            | 312.96                     |

<details>
  <summary>🧠 View SQL Code</summary>

```sql
SELECT
    reason,
    COUNT(*) AS total_requests,
    ROUND(AVG(resolution_time_hrs), 2) AS avg_resolution_time_hrs
FROM vw_cleaned_requests
WHERE resolution_time_hrs IS NOT NULL
GROUP BY reason
HAVING COUNT(*) >= 100
ORDER BY avg_resolution_time_hrs DESC
LIMIT 10;
```

</details>
<br>

### 7. Which departments maintain SLA compliance while managing high workloads and open case volumes?

**Result:**  
| Department | Total Requests | Open Requests | Open Request % | SLA Compliance % | SLA Rank |
|------------|----------------|----------------|----------------|------------------|----------|
| GEN_       | 10,737         | 0              | 0.00           | 1.00             | 1        |
| PARK       | 19,085         | 1,646          | 0.09           | 0.94             | 2        |
| ANML       | 762            | 126            | 0.17           | 0.90             | 3        |
| PWDx       | 130,764        | 7,220          | 0.06           | 0.87             | 4        |
| PROP       | 2,596          | 388            | 0.15           | 0.74             | 5        |
| ISD        | 18,635         | 3,765          | 0.20           | 0.73             | 6        |
| INFO       | 14,390         | 6,457          | 0.45           | 0.59             | 7        |
| BWSC       | 3,366          | 1,871          | 0.56           | 0.53             | 8        |
| BTDT       | 81,529         | 18,617         | 0.23           | 0.50             | 9        |
| BPD_       | 296            | 253            | 0.85           | 0.18             | 10       |
| BHA_       | 129            | 127            | 0.98           | 0.14             | 11       |
| BPS_       | 177            | 173            | 0.98           | 0.13             | 12       |

<details>
  <summary>🧠 View SQL Code</summary>

```sql
SELECT
    department,
    COUNT(*) AS total_requests,
    COUNT(*) FILTER (WHERE current_status = 'Open') AS open_requests,
    ROUND(
        COUNT(*) FILTER (WHERE current_status = 'Open')::decimal / COUNT(*),
        2
    ) AS open_request_pct,
    ROUND(SUM(sla_met)::decimal / COUNT(*), 2) AS sla_compliance_pct,
    RANK() OVER (ORDER BY ROUND(SUM(sla_met)::decimal / COUNT(*), 2) DESC) AS sla_rank
FROM vw_cleaned_requests
GROUP BY department
HAVING COUNT(*) >= 100
ORDER BY sla_rank;
```

</details>
<br>

### 8. Are departments improving or declining in their SLA performance over time?

**Result:**  
<details>
  <summary>Click to expand SLA Performance Table</summary>

| department | month_name | sla_pct | prev_month_sla_pct | change_from_last_month | total_requests |
|---|---|---|---|---|---|
| ANML | January | 1.0 | NaN | NaN | 41 |
| ANML | February | 1.0 | 1.0 | 0.0 | 34 |
| ANML | March | 1.0 | 1.0 | 0.0 | 40 |
| ANML | April | 0.942 | 1.0 | -0.058 | 69 |
| ANML | May | 1.0 | 0.942 | 0.058 | 57 |
| ANML | June | 0.8696 | 1.0 | -0.1304 | 69 |
| ANML | July | 0.9836 | 0.8696 | 0.114 | 61 |
| ANML | August | 0.9655 | 0.9836 | -0.0181 | 58 |
| ANML | September | 1.0 | 0.9655 | 0.0345 | 63 |
| ANML | October | 0.8919 | 1.0 | -0.1081 | 37 |
| ANML | November | 0.9688 | 0.8919 | 0.0769 | 64 |
| ANML | December | 0.9535 | 0.9688 | -0.0153 | 43 |
| BTDT | January | 0.4801 | NaN | NaN | 5401 |
| BTDT | February | 0.6822 | 0.4801 | 0.2021 | 5717 |
| BTDT | March | 0.7266 | 0.6822 | 0.0444 | 6980 |
| BTDT | April | 0.7276 | 0.7266 | 0.001 | 6767 |
| BTDT | May | 0.5824 | 0.7276 | -0.1452 | 7225 |
| BTDT | June | 0.6593 | 0.5824 | 0.0769 | 4732 |
| BTDT | July | 0.6596 | 0.6593 | 0.0003 | 3546 |
| BTDT | August | 0.4845 | 0.6596 | -0.1751 | 5185 |
| BTDT | September | 0.4129 | 0.4845 | -0.0716 | 6432 |
| BTDT | October | 0.6506 | 0.4129 | 0.2377 | 5177 |
| BTDT | November | 0.8784 | 0.6506 | 0.2278 | 3199 |
| BTDT | December | 0.9424 | 0.8784 | 0.064 | 2551 |
| BWSC | January | 0.9574 | NaN | NaN | 141 |
| BWSC | February | 0.8272 | 0.9574 | -0.1302 | 81 |
| BWSC | March | 0.6209 | 0.8272 | -0.2063 | 153 |
| BWSC | April | 0.5722 | 0.6209 | -0.0487 | 187 |
| BWSC | May | 0.7778 | 0.5722 | 0.2056 | 144 |
| BWSC | June | 0.7639 | 0.7778 | -0.0139 | 144 |
| BWSC | July | 0.7958 | 0.7639 | 0.0319 | 142 |
| BWSC | August | 0.8062 | 0.7958 | 0.0104 | 129 |
| BWSC | September | 0.9452 | 0.8062 | 0.139 | 146 |
| BWSC | October | 0.957 | 0.9452 | 0.0118 | 93 |
| BWSC | November | 0.9136 | 0.957 | -0.0434 | 81 |
| BWSC | December | 0.9444 | 0.9136 | 0.0308 | 54 |
| GEN_ | January | 1.0 | NaN | NaN | 498 |
| GEN_ | February | 1.0 | 1.0 | 0.0 | 488 |
| GEN_ | March | 1.0 | 1.0 | 0.0 | 561 |
| GEN_ | April | 1.0 | 1.0 | 0.0 | 625 |
| GEN_ | May | 1.0 | 1.0 | 0.0 | 798 |
| GEN_ | June | 1.0 | 1.0 | 0.0 | 1009 |
| GEN_ | July | 1.0 | 1.0 | 0.0 | 1314 |
| GEN_ | August | 1.0 | 1.0 | 0.0 | 1264 |
| GEN_ | September | 1.0 | 1.0 | 0.0 | 1274 |
| GEN_ | October | 1.0 | 1.0 | 0.0 | 1223 |
| GEN_ | November | 1.0 | 1.0 | 0.0 | 923 |
| GEN_ | December | 1.0 | 1.0 | 0.0 | 760 |
| INFO | January | 0.8857 | NaN | NaN | 481 |
| INFO | February | 0.8709 | 0.8857 | -0.0148 | 573 |
| INFO | March | 0.8602 | 0.8709 | -0.0107 | 601 |
| INFO | April | 0.8241 | 0.8602 | -0.0361 | 739 |
| INFO | May | 0.8761 | 0.8241 | 0.052 | 896 |
| INFO | June | 0.8144 | 0.8761 | -0.0617 | 819 |
| INFO | July | 0.8646 | 0.8144 | 0.0502 | 960 |
| INFO | August | 0.8695 | 0.8646 | 0.0049 | 858 |
| INFO | September | 0.8989 | 0.8695 | 0.0294 | 623 |
| INFO | October | 0.8243 | 0.8989 | -0.0746 | 552 |
| INFO | November | 0.8834 | 0.8243 | 0.0591 | 463 |
| INFO | December | 0.8668 | 0.8834 | -0.0166 | 368 |
| ISD | January | 0.7586 | NaN | NaN | 1305 |
| ISD | February | 0.7649 | 0.7586 | 0.0063 | 1140 |
| ISD | March | 0.8126 | 0.7649 | 0.0477 | 1190 |
| ISD | April | 0.8343 | 0.8126 | 0.0217 | 1171 |
| ISD | May | 0.8494 | 0.8343 | 0.0151 | 1235 |
| ISD | June | 0.8479 | 0.8494 | -0.0015 | 1381 |
| ISD | July | 0.8915 | 0.8479 | 0.0436 | 1475 |
| ISD | August | 0.8974 | 0.8915 | 0.0059 | 1588 |
| ISD | September | 0.8886 | 0.8974 | -0.0088 | 1382 |
| ISD | October | 0.8829 | 0.8886 | -0.0057 | 1264 |
| ISD | November | 0.8824 | 0.8829 | -0.0005 | 884 |
| ISD | December | 0.9322 | 0.8824 | 0.0498 | 855 |
| PARK | January | 0.9185 | NaN | NaN | 932 |
| PARK | February | 0.9376 | 0.9185 | 0.0191 | 801 |
| PARK | March | 0.9505 | 0.9376 | 0.0129 | 1293 |
| PARK | April | 0.9567 | 0.9505 | 0.0062 | 1525 |
| PARK | May | 0.941 | 0.9567 | -0.0157 | 2000 |
| PARK | June | 0.9516 | 0.941 | 0.0106 | 2792 |
| PARK | July | 0.9487 | 0.9516 | -0.0029 | 2517 |
| PARK | August | 0.9311 | 0.9487 | -0.0176 | 1916 |
| PARK | September | 0.9534 | 0.9311 | 0.0223 | 1331 |
| PARK | October | 0.9209 | 0.9534 | -0.0325 | 973 |
| PARK | November | 0.9188 | 0.9209 | -0.0021 | 739 |
| PARK | December | 0.9194 | 0.9188 | 0.0006 | 620 |
| PROP | January | 0.427 | NaN | NaN | 89 |
| PROP | February | 0.3947 | 0.427 | -0.0323 | 114 |
| PROP | March | 0.6029 | 0.3947 | 0.2082 | 204 |
| PROP | April | 0.7978 | 0.6029 | 0.1949 | 272 |
| PROP | May | 0.7479 | 0.7978 | -0.0499 | 234 |
| PROP | June | 0.7516 | 0.7479 | 0.0037 | 322 |
| PROP | July | 0.8878 | 0.7516 | 0.1362 | 196 |
| PROP | August | 0.8567 | 0.8878 | -0.0311 | 342 |
| PROP | September | 0.9441 | 0.8567 | 0.0874 | 143 |
| PROP | October | 0.9825 | 0.9441 | 0.0384 | 171 |
| PROP | November | 0.9913 | 0.9825 | 0.0088 | 115 |
| PWDx | January | 0.885 | NaN | NaN | 10313 |
| PWDx | February | 0.891 | 0.885 | 0.006 | 8361 |
| PWDx | March | 0.8871 | 0.891 | -0.0039 | 9369 |
| PWDx | April | 0.898 | 0.8871 | 0.0109 | 9610 |
| PWDx | May | 0.9307 | 0.898 | 0.0327 | 10170 |
| PWDx | June | 0.9385 | 0.9307 | 0.0078 | 10388 |
| PWDx | July | 0.9243 | 0.9385 | -0.0142 | 11302 |
| PWDx | August | 0.9486 | 0.9243 | 0.0243 | 13711 |
| PWDx | September | 0.9539 | 0.9486 | 0.0053 | 13089 |
| PWDx | October | 0.9368 | 0.9539 | -0.0171 | 9240 |
| PWDx | November | 0.9277 | 0.9368 | -0.0091 | 8032 |
| PWDx | December | 0.8975 | 0.9277 | -0.0302 | 9959 |

</details>

<details>
  <summary>🧠 View SQL Code</summary>

```sql
WITH monthly_sla AS (
    SELECT
        department,
        DATE_TRUNC('month', open_dt) AS month,
        COUNT(*) AS total_requests,
        ROUND(SUM(sla_met)::decimal / COUNT(*), 4) AS sla_pct
    FROM vw_cleaned_requests
    WHERE current_status = 'Closed'
    GROUP BY department, DATE_TRUNC('month', open_dt)
    HAVING COUNT(*) >= 30
),
sla_with_trend AS (
    SELECT *,
        LAG(sla_pct) OVER (PARTITION BY department ORDER BY month) AS prev_month_sla_pct,
        ROUND(sla_pct - LAG(sla_pct) OVER (PARTITION BY department ORDER BY month), 4) AS change_from_last_month
    FROM monthly_sla
)
SELECT
    department,
    TRIM(TO_CHAR(month, 'Month')) AS month_name,
    sla_pct,
    prev_month_sla_pct,
    change_from_last_month,
    total_requests
FROM sla_with_trend
ORDER BY department, month;
```

</details>
<br>

### 9. How is the volume of 311 requests changing over time, and what’s the rolling 3-month average?

**Result:**  
| Month      | Total Requests | Rolling 3-Month Avg |
|------------|----------------|----------------------|
| January    | 20,638         | 20,638.00            |
| February   | 18,697         | 19,667.50            |
| March      | 22,164         | 20,499.67            |
| April      | 23,055         | 21,305.33            |
| May        | 25,011         | 23,410.00            |
| June       | 26,118         | 24,728.00            |
| July       | 26,634         | 25,921.00            |
| August     | 28,909         | 27,220.33            |
| September  | 28,039         | 27,860.67            |
| October    | 23,305         | 26,751.00            |
| November   | 19,859         | 23,734.33            |
| December   | 20,194         | 21,119.33            |

<details>
  <summary>🧠 View SQL Code</summary>

```sql
WITH monthly_volume AS (
    SELECT
        DATE_TRUNC('month', open_dt) AS month,
        COUNT(*) AS total_requests
    FROM vw_cleaned_requests
    GROUP BY DATE_TRUNC('month', open_dt)
),
volume_with_rolling_avg AS (
    SELECT
        month,
        total_requests,
        ROUND(
            AVG(total_requests) OVER (
                ORDER BY month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ), 2
        ) AS rolling_3_month_avg
    FROM monthly_volume
)
SELECT
    TRIM(TO_CHAR(month, 'Month')) AS month_name,
    total_requests,
    rolling_3_month_avg
FROM volume_with_rolling_avg
ORDER BY month;
```

</details>
<br>

### 10. Were there any months in 2024 with unusually high complaint volumes compared to the typical pattern?

**Result:**  
| Month   | Total Requests | Z-Score |
|---------|----------------|---------|
| August  | 28,909         | 1.58    |

<details>
  <summary>🧠 View SQL Code</summary>

```sql
WITH monthly_volume AS (
    SELECT
        DATE_TRUNC('month', open_dt) AS month,
        COUNT(*) AS total_requests
    FROM vw_cleaned_requests
    GROUP BY DATE_TRUNC('month', open_dt)
),
volume_stats AS (
    SELECT
        AVG(total_requests) AS avg_volume,
        STDDEV(total_requests) AS stddev_volume
    FROM monthly_volume
),
volume_with_zscore AS (
    SELECT
        mv.month,
        mv.total_requests,
        ROUND((mv.total_requests - vs.avg_volume) / vs.stddev_volume, 2) AS z_score
    FROM monthly_volume mv
    CROSS JOIN volume_stats vs
)
SELECT
    TRIM(TO_CHAR(month, 'Month')) AS month_name,
    total_requests,
    z_score
FROM volume_with_zscore
WHERE ABS(z_score) >= 1.5
ORDER BY z_score DESC;
```

</details>
<br>

