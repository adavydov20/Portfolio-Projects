SELECT *
FROM CovidDeaths
ORDER BY 3,4;

-- Select data that will be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Cases Vs. Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Cases Vs. Population (US)
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL AND location LIKE '%states%'
ORDER BY 1,2;

-- Countries w/ Highest Infection Rate vs. Population
SELECT location, MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population)) * 100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Countries w/ Highest Death Rate per Capita
SELECT location, MAX(total_deaths) AS TotalDeathCount, population, MAX((total_deaths/population)) * 100 AS PercentPopulationDied
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationDied DESC;


-- Deaths by Continent / Region
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global Numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths) / SUM(new_cases)  * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- Total Population Vs. Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
WHERE dea.continent IS NOT NULL
    AND dea.date = vac.date
ORDER BY 2,3;

-- Utilizing CTE
WITH PopulationVsVaccination (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations)
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
WHERE dea.continent IS NOT NULL
    AND dea.date = vac.date
)

SELECT *, (RollingVaccinations / Population) * 100 AS PopulationPercentVaccinated
FROM PopulationVsVaccination;

-- Utilizing Temp Table

DROP TEMPORARY TABLE IF EXISTS PopulationPercentVaccinated; -- Drop the temporary table if it exists

CREATE TEMPORARY TABLE PopulationPercentVaccinated (
    Continent nvarchar(255),
    Location nvarchar(255),
    Date date,
    Population numeric,
    New_Vaccinations numeric,
    RollingVaccinations numeric
);

INSERT INTO PopulationPercentVaccinated
SELECT dea.continent, dea.location, STR_TO_DATE(dea.date, '%m/%d/%Y') AS date, 
    dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, STR_TO_DATE(dea.date, '%m/%d/%Y')) AS RollingVaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
WHERE dea.continent IS NOT NULL
    AND STR_TO_DATE(dea.date, '%m/%d/%Y') = STR_TO_DATE(vac.date, '%m/%d/%Y');

SELECT *, (RollingVaccinations / Population) * 100 AS PopulationPercentVaccinated
FROM PopulationPercentVaccinated;

-- Creating View to Store Data fopr Future Visualizations
CREATE VIEW PopulationPercentVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
WHERE dea.continent IS NOT NULL
    AND dea.date = vac.date;
    
SELECT *
FROM PopulationPercentVaccinated;