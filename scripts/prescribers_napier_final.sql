SELECT *
FROM prescriber

ORDER BY nppes_provider_city DESC


SELECT *
FROM prescription
ORDER BY npi

SELECT *
FROM drug

SELECT *
FROM zip_fips

SELECT *
FROM population

SELECT * 
FROM fips_county

SELECT * 
FROM cbsa


--1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT 	p.npi, 
		SUM(rx.total_claim_count) AS total_count
FROM prescriber AS p
INNER JOIN prescription AS rx
USING (npi)
GROUP BY npi
ORDER BY total_count DESC;
--NPI 1881634483 has the highest claim count.

--1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT 	p.nppes_provider_first_name, 
		p.nppes_provider_last_org_name, 
		p.specialty_description, 
		SUM(rx.total_claim_count) AS total_count
FROM prescriber AS p
INNER JOIN prescription AS rx
USING (npi)
GROUP BY p.nppes_provider_first_name, 
		 p.nppes_provider_last_org_name, 
		 p.specialty_description
ORDER BY total_count DESC;
--Bruce Pendley, a Family Practice, has the highest claim count


--2a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT 	p.specialty_description,  
		SUM(rx.total_claim_count) AS total_count
FROM prescriber AS p
INNER JOIN prescription AS rx
USING (npi)
GROUP BY p.specialty_description
ORDER BY total_count DESC;
--Family Practices had the most number of claims

--2b. Which specialty had the most total number of claims for opioids?
SELECT 	p.specialty_description,  
		SUM(rx.total_claim_count) AS total_count
FROM prescriber AS p
INNER JOIN prescription AS rx
USING (npi)
INNER JOIN drug AS d
USING(drug_name)
WHERE d.opioid_drug_flag='Y'
GROUP BY p.specialty_description
ORDER BY total_count DESC;
--Nurse Practitioners had the highest claims count for opioids


--3a. Which drug (generic_name) had the highest total drug cost?
SELECT 	d.generic_name, 
		MAX(rx.total_drug_cost) AS max_cost
FROM prescription AS rx
INNER JOIN drug AS d
USING(drug_name)
GROUP by d.generic_name
ORDER BY max_cost DESC;
--Pirfenidone had the highest drug cost

--3b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. 
SELECT 	d.generic_name, 
		ROUND(rx.total_drug_cost/rx.total_day_supply,2) AS cost_per_day
FROM prescription AS rx
INNER JOIN drug AS d
USING(drug_name)
ORDER BY cost_per_day DESC;
--IMMUNE GLOBULIN has the highest cost per day


--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this.
SELECT 	drug_name, 
		CASE WHEN opioid_drug_flag='Y' THEN 'opioid' 
			 WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
			 ELSE 'neither'
		END AS drug_type
		FROM drug

--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision
SELECT 	SUM(rx.total_drug_cost) AS total_cost,
		CASE WHEN d.opioid_drug_flag='Y' THEN 'opioid' 
			 WHEN d.antibiotic_drug_flag='Y' THEN 'antibiotic'
			 ELSE 'neither'
		END AS drug_type
	FROM drug as d
INNER JOIN prescription AS rx
USING(drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;
--More was spent on opioids


--5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
SELECT 	COUNT(cbsaname)
FROM cbsa 
WHERE cbsaname LIKE '%TN';
--33 CBSAs in TN

--5b.Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT 	c.cbsaname, SUM(p.population) AS total_pop
FROM cbsa as c
INNER JOIN fips_county AS f
USING(fipscounty)
INNER JOIN population AS p
USING (fipscounty)
GROUP BY c.cbsaname
ORDER BY total_pop DESC;
--Nashville has the highest population: 1,830,410.  Morristown has the lowest population: 116,352

--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT 	f.county, f.state, SUM(p.population) AS total_pop
FROM population AS p
INNER JOIN fips_county AS f
USING(fipscounty)
LEFT JOIN cbsa as c 
USING (fipscounty)
WHERE c.cbsaname IS NULL
GROUP BY f.county, f.state
ORDER BY total_pop DESC;
--Sevier, TN has the highest population that is not included in a CBSA: 95,523


--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT 	drug_name, 
		total_claim_count
FROM prescription
WHERE total_claim_count>=3000
ORDER BY total_claim_count DESC;

--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT 	p.drug_name, 
		p.total_claim_count,
		CASE WHEN d.opioid_drug_flag='Y' THEN 'Y' 
			 ELSE 'N'
		END AS opioid_indicator
		FROM prescription as p
INNER JOIN drug AS d
USING(drug_name)
WHERE p.total_claim_count>=3000
ORDER BY p.total_claim_count DESC;

--6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT 	rx.drug_name, 
		rx.total_claim_count,
		p.nppes_provider_first_name, 
		p.nppes_provider_last_org_name,
		CASE WHEN d.opioid_drug_flag='Y' THEN 'Y' 
			 ELSE 'N'
		END AS opioid_indicator
		FROM prescription as rx
INNER JOIN drug AS d
USING(drug_name)
INNER JOIN prescriber AS p
USING(npi)
WHERE rx.total_claim_count>=3000
ORDER BY rx.total_claim_count DESC;


--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.  
--7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT 	p.npi,
		d.drug_name
FROM  prescriber AS p 
CROSS JOIN drug AS d
WHERE 	p.nppes_provider_city = 'NASHVILLE'
	AND p.specialty_description = 'Pain Management'
	AND d.opioid_drug_flag = 'Y'
ORDER BY p.npi, d.drug_name;

--7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT 	p.npi,
		d.drug_name,
		SUM(rx.total_claim_count) AS total_count
FROM  prescriber AS p 
CROSS JOIN drug AS d
LEFT JOIN prescription AS rx
USING(drug_name)
WHERE 	p.nppes_provider_city = 'NASHVILLE'
	AND p.specialty_description = 'Pain Management'
	AND d.opioid_drug_flag = 'Y'
GROUP BY p.npi, d.drug_name
ORDER BY p.npi, d.drug_name

--7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT 	p.npi,
		d.drug_name,
		COALESCE(SUM(rx.total_claim_count),0) AS total_count
FROM  prescriber AS p 
CROSS JOIN drug AS d
LEFT JOIN prescription AS rx
USING(drug_name)
WHERE 	p.nppes_provider_city = 'NASHVILLE'
	AND p.specialty_description = 'Pain Management'
	AND d.opioid_drug_flag = 'Y'
GROUP BY p.npi, d.drug_name
ORDER BY p.npi, d.drug_name