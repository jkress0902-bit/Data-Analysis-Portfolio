-- Beginner / General Laid Off Exploration

SELECT *
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC; # Largest companies that had 100% layoffs, a.k.a. went under.

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;    # Largest layoffs, mostly well-known companies.

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;  # Date range for this table. March 2020 - March 2023

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;   # Industry Layoffs. **INSIGHT** Finance was hit hard with 28k layoffs, but Fin-Tech barely did with 215 layoffs. Scale-wise, traditional finance (banks, insurance, asset management) employs millions
# globally compared to Fintech's thousands. This could also be because Fintech experiences layoffs more often in response to funding constraints rather than business cycles. Finance is more heavily 
# tied to interest rate cycles and are more impacted by a macroeconomic shock. 

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- Intermediate / CTEs, Subqueries

SELECT `MONTH`, total_layoff,
SUM(total_layoff) OVER(ORDER BY `MONTH`) AS rolling_total
FROM
(SELECT SUBSTRING(`date`,1,7) as `Month`, SUM(total_laid_off) AS total_layoff
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC) as total             
;                             # This is using a subquery. I can get the same thing with a much clearer option below; a CTE.

WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`,1,7) as `Month`, SUM(total_laid_off) AS total_layoff
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_layoff,
SUM(total_layoff) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;                   # Rolling Total of total layoffs ordered by month starting from 2020 to 2023.

-- Advanced / Multiple CTEs

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;   # Pulled this query from the beginner section.

SELECT company, YEAR(`date`) AS `Year`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;   # Shows total layoffs, from highest to lowest, per company per year.

WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`) AS `Year`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), 
Company_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;         
# The first CTE just turns the query above it into a CTE. 
# The second CTE references the first one by ranking the top 5 companies each year with the most total layoffs.




