-- Data Cleaning

-- 1. Create a copy of the raw data table, and do all data cleaning processes on the copied table. 
-- 2. Remove Duplicates
-- 3. Standardize the Data (Spelling Errors, trailing spaces, etc.)
-- 4. Null Values or Blank Values
-- 5. Remove Any Irrelevant/Unused Columns or Rows


-- 1. Create Copy Table

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;



-- 2. Remove Duplicates

SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) as row_num
FROM layoffs_staging;      # Creates extra column for duplicate rows, but it's showing incorrect duplicates b/c not all columns have been named in the window function.

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
	country, funds_raised_millions) as row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;  # This CTE is the same as the query above, but it includes all columns and looks cleaner. It shows duplicate rows.

SELECT *
FROM layoffs_staging
WHERE company = 'Casper';  # Checks to make sure they are actually duplicate rows.

WITH duplicate_cte as
(
SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
	country, funds_raised_millions) as row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;   # Deletes all the duplicate rows.


CREATE TABLE `layoffs_staging2` (         # Right-click layoffs_staging table in sidebar > copy to clipboard > Create Statement
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2; 

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
	country, funds_raised_millions) as row_num
FROM layoffs_staging;   # Inserts the cleaned staging table from above into a second copied table. 
# Not a necessary step, but helpful for clarity.

SELECT * 
FROM layoffs_staging2;



-- 3. Standardizing Data

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);     # Trims company column and sets it in the table.

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';     # Sets all Crypto names (CryptoCurrency, Crypto Currency) as just 'Crypto'.

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) # Advanced trim that removes the '.'
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';     # Sets rows that said 'United States.' before to just 'United States'

SELECT `date`,
str_to_date(`date`, '%m/%d/%Y') # Proper way to transform date column from text to date/time formatting.
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y'); 

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;       # Never alter your raw table, only staging tables. 
# Also, this step isn't necessary if you change the data type in the import wizard at the beginning. This was done for learning purposes.



-- 4. Null/Blank Values

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;  # This just shows how to pull up null columns.

UPDATE layoffs_staging2 
SET industry = NULL
WHERE industry = '';    # This was done after troubleshooting everything up until the 'UPDATE' query below.
# Industry had to be changed from blanks to null for the below steps to work.

SELECT *
FROM layoffs_staging2
WHERE industry is null
OR industry = '';   # Finds the companies that have null or blank industries.

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;  # This joins the same table, but is a way to identify companies with rows that have both a null industry and a listed industry.

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;     # This updates the first table to list the same industry that's mentioned from the second table.

## The other columns with null values can't be filled in by us because there's Not Enough Information. It's like Stata where I just left some rows with nulls/blanks.



-- 5. Remove Columns or Rows

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;   # These are being deleted b/c finding trends in the data uses these columns a lot.
# It's questionable to delete them when most of the other columns have data in them, however, for these purposes, we are deleting them.

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;   # Different syntax to drop a column, rather than specific values.