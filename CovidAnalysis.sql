USE CovidAnalysis;

SELECT *
FROM CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

-- Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

-- Looking at total cases vs total deaths
-- Shows likelihood of dying of you contract covid in USA
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Looking at total cases vs population
-- Shows what percentage of population got covid in USA
SELECT location, date,  population, total_cases, (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT))*100 AS InfectionPercentage
FROM CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Shows what percentage of population got covid nationwide
SELECT location, date,  population, total_cases, (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT))*100 AS InfectionPercentage
FROM CovidDeaths
ORDER BY 1,2

-- Showing countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS FLOAT)) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing continents with Highest Death Count
SELECT continent, MAX(CAST(total_deaths AS FLOAT)) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global number
SELECT SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_Deaths, SUM(new_deaths) / SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Joining Tables of CovidDeaths and CovidPercentage
SELECT *
FROM CovidDeaths dea
JOIN CovidVaccinations vax
	ON dea.location = vax.location AND
	dea.date = vax.date

-- Looking at Total Population vs Vaccinations
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
	SUM(CAST(vax.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	--,(RollingPeopleVaccinated / CAST(population AS FLOAT))*100 
FROM CovidDeaths dea
JOIN CovidVaccinations vax
	ON dea.location = vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- use CTE
WITH PopVsVax (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS(
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
	SUM(CAST(vax.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vax
	ON dea.location = vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopVsVax

-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated -- always put this(best practice)
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population nvarchar(255),
new_vaccination nvarchar(255),
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
	SUM(CAST(vax.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vax
	ON dea.location = vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/CAST(population AS FLOAT))*100
FROM #PercentPopulationVaccinated

-- Creating View to store for later visualizations (usefull in order to create a visualization in Tableau)
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
	SUM(CAST(vax.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vax
	ON dea.location = vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated