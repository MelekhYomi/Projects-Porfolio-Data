/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject..yCovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

--SELECT *
--FROM PortfolioProject..yCovidVaccinations
--ORDER BY 3, 4;

-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..yCovidDeaths
ORDER BY 1, 2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / CONVERT(float, total_cases)) * 100 AS DeathPercentage
FROM PortfolioProject..yCovidDeaths
WHERE location like '%Nigeria%'
ORDER BY 1, 2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
	
SELECT location, date, total_cases, Population, (CONVERT(float, total_cases) / CONVERT(float, population)) * 100 AS InfectedPopulationPercentage
FROM PortfolioProject..yCovidDeaths
WHERE location like '%Nigeria%'
ORDER BY 1, 2


-- Countries with Highest Infection Rate compared to Population
	
SELECT location, Population, MAX(total_cases) AS Highest_Infection_Count, MAX((CAST(total_cases AS integer) / CAST(population AS float))) * 100 AS InfectedPopulationPercentage
FROM PortfolioProject..yCovidDeaths
WHERE location like '%%'
GROUP BY location, Population
ORDER BY InfectedPopulationPercentage DESC


-- Countries with Highest Death Count per Population
	
SELECT location, MAX(CAST(total_deaths as INT)) AS Highest_Death_Count
FROM PortfolioProject..yCovidDeaths
--WHERE location like '%%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Highest_Death_Count DESC

	
-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
	
SELECT continent, MAX(CAST(total_deaths as INT)) AS Highest_Death_Count
FROM PortfolioProject..yCovidDeaths
--WHERE location like '%%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Highest_Death_Count DESC

-- Global numbers
	
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, NULLIF(SUM(CAST(new_deaths AS float)), 0) / NULLIF(SUM(CAST(new_cases AS float)), 0) * 100 AS death_percentage
FROM PortfolioProject..yCovidDeaths
--WHERE location like '%Nigeria%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, NULLIF(SUM(CAST(new_deaths AS float)), 0) / NULLIF(SUM(CAST(new_cases AS float)), 0) * 100 AS death_percentage
FROM PortfolioProject..yCovidDeaths
--WHERE location like '%Nigeria%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT *
FROM PortfolioProject..yCovidDeaths dea
JOIN PortfolioProject..yCovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
--WHERE continent IS NOT NULL
--ORDER BY 3, 4;

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..yCovidDeaths dea
JOIN PortfolioProject..yCovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, NULLIF(SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) AS rolling_people_vaccinated
FROM PortfolioProject..yCovidDeaths dea
JOIN PortfolioProject..yCovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;


-- Using CTE to perform Calculation on Partition By in previous query

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, NULLIF(SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) AS rolling_people_vacinated
FROM PortfolioProject..yCovidDeaths dea
JOIN PortfolioProject..yCovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (rolling_people_vaccinated / population) * 100
FROM pop_vs_vac

-- Using Temp Table to perform Calculation on Partition By in previous query
--Temp table

DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)
INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, NULLIF(SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) AS rolling_people_vaccinated
FROM PortfolioProject..yCovidDeaths dea
JOIN PortfolioProject..yCovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3;

SELECT *, (rolling_people_vaccinated / population) * 100
FROM #percent_population_vaccinated


-- Creating View to store data for later visualizations

CREATE View percentpopulationvaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, NULLIF(SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) AS rolling_people_vaccinated
FROM PortfolioProject..yCovidDeaths dea
JOIN PortfolioProject..yCovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3;
