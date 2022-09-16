SELECT *
FROM PortfolioProject..CovidDeaths AS de
JOIN PortfolioProject..CovidVacc AS va
ON de.date=va.date AND de.location=va.location
WHERE de.continent IS NOT NULL AND de.location='United Arab Emirates'
ORDER BY de.LOCATION,de.date


--SELECT *
--FROM PortfolioProject..CovidVacc
--ORDER BY location,date

--SELECT location, date, total_cases, new_cases, total_deaths,population
--FROM PortfolioProject..CovidDeaths
--ORDER BY 1,2

--Looking at total cases vs total deaths for percent fatality
--Shows percentage of people infected in country
--Shows rough estimate of chance of death in country if infected by COVID

--DROP TABLE IF EXISTS #DeathPercent
--CREATE TABLE #DeathPercent
--(
--Location varchar(50),
--Date date,
--Total_Cases int,
--Percent_Infected float,
--Total_Deaths int,
--Death_Percent float
--)


--INSERT INTO #DeathPercent
SELECT location, date, total_cases, CAST((total_cases/population)*100 AS DECIMAL(6,4)) AS Percent_Infected, total_deaths, CAST((total_deaths/total_cases)*100 AS DECIMAL(6,3)) AS Percent_Mortality
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%' AND location NOT LIKE '%world%' AND location NOT LIKE '%union%' AND location NOT LIKE '%international%'
ORDER BY 1,2


--Shows the percentage of people infected per country at their peak

SELECT location, population, MAX(total_cases) AS Total_Cases, CAST((MAX(total_cases)/population)*100 AS DECIMAL(6,4)) AS Percent_Infected
FROM CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%' AND location NOT LIKE '%world%' AND location NOT LIKE '%union%' AND location NOT LIKE '%international%'
GROUP BY location, population
ORDER BY Percent_Infected DESC

--Show total deaths per country

SELECT location, population, MAX(CAST(total_deaths AS int)) AS Total_Death_Count
FROM CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%' AND location NOT LIKE '%world%' AND location NOT LIKE '%union%' AND location NOT LIKE '%international%'
GROUP BY location, population
ORDER BY Total_Death_Count DESC

--TOTALS BY CONTINENT

--Infected
SELECT location, population, MAX(Total_cases) AS Total_Infected, (MAX(total_cases)/population)*100 AS Percent_Infected
FROM CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%' AND location NOT LIKE '%world%' AND location NOT LIKE '%union%' AND location NOT LIKE '%international%'
GROUP BY location, population
ORDER BY Percent_Infected DESC

--Death
SELECT location, population, MAX(CAST(total_deaths as int)) AS Total_Deaths, (MAX(CAST(total_deaths as int))/population)*100 AS Percent_Death
FROM CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%' AND location NOT LIKE '%world%' AND location NOT LIKE '%union%' AND location NOT LIKE '%international%'
GROUP BY location, population
ORDER BY Percent_Death DESC

--TOTAL BY WORLD

SELECT location, population, 
 MAX(CAST(total_deaths as int)) AS Total_Deaths, 
(MAX(CAST(total_deaths as int))/population)*100 AS Percent_Death, 
 MAX(Total_cases) AS Total_Infected,
(MAX(total_cases)/population)*100 AS Percent_Infected,
 MAX(CAST(total_deaths as int))/MAX(Total_cases)*100 AS Percent_Mortaliity_Rate
FROM CovidDeaths
WHERE location ='world'
GROUP BY location, population
ORDER BY Percent_Death DESC

--GLOBAL NUMBERS

SELECT date, 
SUM(new_cases) as Global_New_Cases, 
SUM(CAST(new_deaths AS int)) AS Global_New_Deaths, 
FORMAT(SUM(CAST(new_deaths AS int))/SUM(new_cases)*100, 'N2') AS Global_Mortality_Percent
FROM CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%' AND location NOT LIKE '%world%' AND location NOT LIKE '%union%' AND location NOT LIKE '%international%'
GROUP BY date
ORDER by date

--HOW MANY PEOPLE HAVE BEEN VACCINATED

With POPvsVAC(location, date, population, new_vacc, total_vacc)
AS
(
SELECT de.location, de.date, de.population, va.new_vaccinations,
SUM(CAST(va.new_vaccinations AS float)) OVER (PARTITION BY de.location ORDER BY de.date) AS Rolling_Total_Vaccination_by_Country
FROM PortfolioProject..CovidDeaths AS de
JOIN PortfolioProject..CovidVacc AS va
	ON de.date=va.date AND de.location=va.location
WHERE de.continent IS NOT NULL AND de.location NOT LIKE '%income%' AND de.location NOT LIKE '%world%' AND de.location NOT LIKE '%union%' AND de.location NOT LIKE '%international%'
--ORDER BY de.continent, de.location, de.date 
)
SELECT *,  (total_vacc/population)*100 AS PercentVacc
FROM POPvsVAC
WHERE location='Argentina'
ORDER BY location, date

--MAX VAX PERCENT PER COUNTRY

With POPvsVAC(location, date, population, new_vacc, total_vacc)
AS
(
SELECT de.location, de.date, de.population, va.new_vaccinations,
va.people_vaccinated
FROM PortfolioProject..CovidDeaths AS de
JOIN PortfolioProject..CovidVacc AS va
	ON de.date=va.date AND de.location=va.location
WHERE de.continent IS NOT NULL AND de.location NOT LIKE '%income%' AND de.location NOT LIKE '%world%' AND de.location NOT LIKE '%union%' AND de.location NOT LIKE '%international%'
--ORDER BY de.continent, de.location, de.date 
)
SELECT location, MAX(total_vacc) AS Highest_Vacc_Count, MAX(total_vacc/population)*100 AS PercentVacc
FROM POPvsVAC
GROUP BY location
ORDER BY location

--MAX FULLY VAX PERCENT PER COUNTRY

With POPvsVAC(location, date, population, total_vacc, complete_total_vacc)
AS
(
SELECT 
de.location, 
de.date, 
de.population, 
CAST(va.people_vaccinated AS float),
CAST(va.people_fully_vaccinated AS float)
FROM PortfolioProject..CovidDeaths AS de
JOIN PortfolioProject..CovidVacc AS va
	ON de.date=va.date AND de.location=va.location
WHERE de.continent IS NOT NULL AND de.location NOT LIKE '%income%' AND de.location NOT LIKE '%world%' AND de.location NOT LIKE '%union%' AND de.location NOT LIKE '%international%'
--ORDER BY de.continent, de.location, de.date 
)
SELECT location, 
MAX(total_vacc) AS Highest_Vacc_Count,
MAX(total_vacc/population)*100 AS PercentVacc,
MAX(complete_total_vacc) AS Highest_Complete_Vacc_Count,
MAX(complete_total_vacc/population)*100 AS PercentCompleteVacc
FROM POPvsVAC
GROUP BY location
ORDER BY location

--CREATE VIEW TO STORE DATA FOR LATER VISUALIZATION
CREATE VIEW PercentPopulationVacc AS
SELECT location, population, 
 MAX(CAST(total_deaths as int)) AS Total_Deaths, 
(MAX(CAST(total_deaths as int))/population)*100 AS Percent_Death, 
 MAX(Total_cases) AS Total_Infected,
(MAX(total_cases)/population)*100 AS Percent_Infected,
 MAX(CAST(total_deaths as int))/MAX(Total_cases)*100 AS Percent_Mortaliity_Rate
FROM CovidDeaths
WHERE location ='world'
GROUP BY location, population
--ORDER BY Percent_Death DESC