
SELECT *
FROM CovidDeaths
ORDER BY 3,4

-- Check number of rows mathces to excel file

SELECT COUNT(iso_code)
FROM CovidDeaths

--SELECT *
--FROM CovidHealth
--order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

-- Calculating Deaths per Case (How likely are you to die once Covid once contracted, over time?)

SELECT location, date, total_cases, total_deaths, TRY_CAST(total_deaths AS float)/TRY_CAST(total_cases AS float)*100 AS DeathChance
FROM CovidDeaths
WHERE location = 'United Kingdom'
ORDER BY 1,2


-- Calculating Cases per Population (How much of the population contracted Covid?)

SELECT location, date, total_cases, population, TRY_CAST(total_cases AS float)/TRY_CAST(population AS float)*100 AS CasesPerPerson
FROM CovidDeaths
WHERE location = 'United Kingdom'
ORDER BY 1,2

-- Ranking countries by CasesPerPerson

SELECT location, MAX(total_cases) AS OverallCases, population, MAX(TRY_CAST((total_cases) AS float)/TRY_CAST(population AS float))*100 AS CasesPerPerson
FROM CovidDeaths
GROUP BY location, population
ORDER BY CasesPerPerson DESC

-- Ranking Countries by Deaths

SELECT location, MAX(CAST(total_deaths AS float)) AS OverallDeaths
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY OverallDeaths DESC

-- Ranking Continents by Deaths

SELECT continent, MAX(CAST(total_deaths AS float)) AS OverallDeaths
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY OverallDeaths DESC

-- WORLDWIDE DATA

--Cases

SELECT date, SUM(new_cases) as TotalCases
FROM CovidDeaths
WHERE location = 'World'
GROUP BY date
ORDER BY date

-- Deaths
-- What day had the most deaths from Covid, worldwide?

SELECT date, SUM(new_deaths) as GLobalDeaths
FROM CovidDeaths
WHERE location = 'World'
GROUP BY date
ORDER BY GLobalDeaths Desc


-- Worldwide Deaths per Case

SELECT location, date, total_cases, total_deaths, TRY_CAST(total_deaths AS float)/TRY_CAST(total_cases AS float)*100 AS DeathsPerCase
FROM CovidDeaths
WHERE location = 'World'
ORDER BY 1,2



-- JOIN Death and Health tables together

SELECT *
FROM CovidDeaths dea join CovidHealth hea
	on dea.location = hea.location
	and dea.date = hea.date

-- Calculating total vaccinations per day per person

SELECT dea.continent, dea.location, dea.date, dea.population, hea.new_vaccinations
FROM CovidDeaths dea join CovidHealth hea
	on dea.location = hea.location
	and dea.date = hea.date
WHERE dea.continent is not null
ORDER BY 2, 3

-- Creating Rolling Count of Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, hea.new_vaccinations, SUM(cast(hea.new_vaccinations as float)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVaccinationCount
FROM CovidDeaths dea join CovidHealth hea
	on dea.location = hea.location
	and dea.date = hea.date
WHERE dea.continent is not null
order by 2,3

-- CTE

With PercentVac (Continent, location, date, population, new_vaccinations, RollingVaccinationCount)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, hea.new_vaccinations, SUM(cast(hea.new_vaccinations as float)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVaccinationCount
FROM CovidDeaths dea join CovidHealth hea
	on dea.location = hea.location
	and dea.date = hea.date
WHERE dea.continent is not null
)
SELECT *, (RollingVaccinationCount/population)*100
FROM PercentVac


-- Creating a view for tableau viz (Chance of death from Covid by country, with human development index (Removing France due to inaccurate data)

CREATE VIEW HumanIndexVSDeathsPerCaseVsPercentVac as
SELECT dea.location, MAX(hea.human_development_index) as HumanDevelopmentIndex, CAST(AVG((TRY_CAST(total_deaths AS float)/TRY_CAST(total_cases AS float)*100)) as float) as AvgDeathsPerCase, MAX(CAST(people_vaccinated_per_hundred as float)) as PercentVacinated
FROM CovidDeaths dea join CovidHealth hea
	on dea.location = hea.location
	and dea.date = hea.date
WHERE dea.total_cases is not null AND dea.continent is not null AND hea.human_development_index is not null AND dea.total_deaths is not null AND dea.location <> 'France'
GROUP BY dea.location
--ORDER BY 3 DESC

CREATE VIEW NewCasesOverTime as
SELECT location, date, new_cases
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, date, new_cases
--Order by location, date
