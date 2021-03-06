-- create table to import data from coviddeath file
CREATE TABLE coviddeath
(
    iso_code varchar,
    continent varchar,
    location varchar,
    date DATE,
    population BIGINT,
    total_cases Integer,
    new_cases Integer,
    new_cases_smoothed decimal,
    total_deaths Integer,
    new_deaths Integer,
    new_deaths_smoothed decimal,
    total_cases_per_million decimal,
    new_cases_per_million decimal,
    new_cases_smoothed_per_million decimal,
    total_deaths_per_million decimal,
    new_deaths_per_million decimal,
    new_deaths_smoothed_per_million decimal,
    reproduction_rate decimal,
    icu_patients integer,
    icu_patients_per_million decimal,
    hosp_patients integer,
    hosp_patients_per_million decimal,
    weekly_icu_admissions decimal,
    weekly_icu_admissions_per_million decimal,
    weekly_hosp_admissions decimal,
    weekly_hosp_admissions_per_million decimal
)

-- create table to import data from covidVaccinations file

CREATE TABLE covidvacs(
	iso_code varchar,
	continent varchar,
	location varchar,
	date date,
	new_tests integer,
	total_tests integer,
	total_tests_per_thousand decimal,
	new_tests_per_thousand integer,
	new_tests_smoothed integer,
	new_tests_smoothed_per_thousand decimal,
	positive_rate decimal,
	tests_per_case decimal,
	tests_units varchar,
	total_vaccinations integer,
	people_vaccinated integer,
	people_fully_vaccinated integer,
	new_vaccinations integer,
	new_vaccinations_smoothed integer,
	total_vaccinations_per_hundred decimal,
	people_vaccinated_per_hundred decimal,
	people_fully_vaccinated_per_hundred decimal,
	new_vaccinations_smoothed_per_million integer,
	stringency_index decimal,
	population_density decimal,
	median_age decimal,
	aged_65_older decimal,
	aged_70_older decimal,
	gdp_per_capita decimal,
	extreme_poverty decimal,
	cardiovasc_death_rate decimal,
	diabetes_prevalence decimal,
	female_smokers decimal,
	male_smokers decimal,
	handwashing_facilities decimal,
	hospital_beds_per_thousand decimal,
	life_expectancy decimal,
	human_development_index decimal,
	excess_mortality decimal

)

-- Testing if upload was successful
SELECT *
FROM covidVacs

SELECT * 
FROM coviddeath

-- Select Data we're gonna use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeath
order by 1, 2

--altering the data types for easier table values calculations 
ALTER TABLE coviddeath
ALTER COLUMN total_cases TYPE decimal

ALTER TABLE coviddeath
ALTER COLUMN total_deaths TYPE decimal

ALTER TABLE coviddeath 
ALTER COLUMN population TYPE BIGINT


-- Total Cases Vs Total deaths in germany 
--likelihood of dying if you contract covid in germany
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM coviddeath
WHERE location like 'Germany' 
ORDER BY 5 DESC


-- Total Cases Vs Total deaths in my Country Cameroon
--likelihood of dying if you contract covid in Cameroon
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM coviddeath
WHERE location like 'Cameroon'
ORDER BY 5 DESC

-- Total cases vs population Cameroon(Infected) 

SELECT location, date, total_cases, population, ((total_cases/population)*100) as InfectedPercentage
FROM coviddeath
WHERE location like 'Cameroon'
ORDER BY 5 DESC

-- Total cases vs population Germany (Infected)

SELECT location, date, total_cases, population, ((total_cases/population)*100) as InfectedPercentage
FROM coviddeath
WHERE location like 'Germany'
ORDER BY 5 DESC

-- Total cases Infected Globally (without null values) 
SELECT location, MAX(((total_cases/population)*100)) as InfectedPercentage
FROM coviddeath
WHERE (continent IS NOT NULL) AND (total_cases IS NOT NULL) AND (population IS NOT NULL)
GROUP BY location
ORDER BY 2 DESC 


--Looking at coutries with highest Infection rate compared to population (same as previous but with null values)
SELECT location, Max((total_cases/population)*100) as InfectedPercentage
FROM coviddeath
GROUP BY location
order by InfectedPercentage desc


-- random queries 
SELECT location, continent, total_deaths 
FROM coviddeath
WHERE continent LIKE '%America%' AND location = 'Canada'

-- Show countries with the highest death count per population 
SELECT location, MAX(total_deaths) AS totalDeathCount
FROM coviddeath 
WHERE (continent IS NOT NULL) AND (total_deaths IS NOT NULL) 
GROUP BY location
ORDER BY totalDeathCount DESC 


----- Looking at statistics by continents ------------


-- Continents with highest deathCount
SELECT continent, MAX(total_deaths) totalDeathCount
FROM coviddeath
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC


-- Global Numbers  (new deaths vs new cases per date) 

SELECT date, SUM(new_cases) new_cases, SUM(new_deaths) new_deaths, (SUM(new_deaths)/SUM(new_cases))*100 as Global_DeathPercentage
FROM coviddeath
WHERE continent IS NOT NULL --AND date = '2020-01-23'
GROUP BY date
ORDER BY date DESC


-- ALTERING new_deaths and new_cases data types, because of invalid results in calculations bigint to decimal/float
ALTER TABLE coviddeath
ALTER COLUMN new_deaths TYPE float 

ALTER TABLE coviddeath
ALTER COLUMN new_cases TYPE float 


-- Looking at the number of people who got Vaccinated per population/location

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(v.new_vaccinations) OVER (PARTITION BY v.location ORDER BY v.date) rollingPeopleVaccinated
FROM coviddeath d JOIN covidVacs v
ON d.date = v.date 
AND d.location = v.location
WHERE d.continent IS NOT NULL AND new_vaccinations IS NOT NULL 
ORDER BY 2,3
 

-- Looking at the percentage of people vaccinated (using previous table's last column)
--- also using CTE ( because using the previous table's last column is impossible ....as it's just a query )

WITH PopVsVac(continent, location, date, population, new_vaccinations, rollingPeopleVaccinated) 
AS
(SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,  SUM(v.new_vaccinations) OVER (PARTITION BY v.location ORDER BY v.date)rollingPeopleVaccinated
FROM coviddeath d JOIN covidVacs v
ON d.date = v.date 
AND d.location = v.location
WHERE d.continent IS NOT NULL AND new_vaccinations IS NOT NULL 
--ORDER BY 2,3
) 
SELECT *, ((cast(rollingPeoplevaccinated AS float))/population) * 100 rollingPercentage
FROM PopVsVac


-- creating a new/temp table(rolling Column) and transferring the data from previous querry into it

DROP TABLE IF EXISTS PercentPopVac;
CREATE TABLE PercentPopVac
(
	continent varchar,
	location varchar, 
	date date, 
	population numeric, 
	new_vaccinations numeric, 
	rollingpeopleVaccinated numeric 
	--rollingpercentage numeric
);
INSERT INTO PercentPopVac
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,  SUM(v.new_vaccinations) OVER (PARTITION BY v.location ORDER BY v.date)rollingPeopleVaccinated
FROM coviddeath d JOIN covidVacs v
ON d.date = v.date 
AND d.location = v.location
WHERE d.continent IS NOT NULL AND new_vaccinations IS NOT NULL 
ORDER BY 2,3



SELECT *, ROUND((rollingpeoplevaccinated/population)*100, 3) as "rolling Percentage"
FROM PercentPopVac



-- Creating views for later use in Tableau ( for the visualization)

CREATE VIEW VaccinatedVSPopulation 
AS
(SELECT *, ROUND((rollingpeoplevaccinated/population)*100, 3) as "rolling Percentage"
FROM PercentPopVac)


DROP VIEW IF EXISTS deathsVStotalcases_germany;
CREATE VIEW deathsVStotalcases_germany
AS (SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM coviddeath
WHERE (location like 'Germany') AND (total_cases IS NOT NULL) AND (total_deaths IS NOT NULL)
ORDER BY 5 DESC)



DROP VIEW IF EXISTS deathsVStotalcases_cameroon;
CREATE VIEW deathsVStotalcases_cameroon
AS (SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM coviddeath
WHERE (location like 'Cameroon') AND (total_cases IS NOT NULL) AND (total_deaths IS NOT NULL)
ORDER BY 5 DESC)


CREATE VIEW InfectedPercentageGlobal --global ie for all coutries 
AS(
SELECT location country, MAX(((total_cases/population)*100)) as InfectedPercentage
FROM coviddeath
WHERE (continent IS NOT NULL) AND (total_cases IS NOT NULL) AND (population IS NOT NULL)
GROUP BY location
ORDER BY 2 DESC 
)


