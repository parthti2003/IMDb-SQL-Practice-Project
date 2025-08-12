-- 	Section 4 – Interview Level (10 Questions)
-- 	Purpose: Complex joins, multi-level aggregation, tricky filters, data cleaning.

/* INT 1: Most common profession among people born before 1950.
   primaryProfession is comma-separated; split and count. */
WITH RECURSIVE seq AS (
  SELECT 1 AS n UNION ALL SELECT n+1 FROM seq WHERE n < 10
),
prof_split AS (
  SELECT
    nb.nconst,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(nb.primaryProfession, ',', seq.n), ',', -1)) AS profession
  FROM name_basics nb
  JOIN seq ON seq.n <= 1 + (LENGTH(nb.primaryProfession) - LENGTH(REPLACE(nb.primaryProfession, ',', '')))
  WHERE nb.birthYear IS NOT NULL AND nb.birthYear <> '\N' AND nb.birthYear < 1950
    AND nb.primaryProfession IS NOT NULL AND nb.primaryProfession <> ''
)
SELECT profession, COUNT(*) AS cnt
FROM prof_split
GROUP BY profession
ORDER BY cnt DESC
LIMIT 1;


-- INT 2: Find actors who have acted in both movies and TV series.
SELECT DISTINCT nb.nconst, nb.primaryName
FROM name_basics nb
WHERE EXISTS (
  SELECT 1 FROM title_principals p
  JOIN title_basics tb ON p.tconst = tb.tconst
  WHERE p.nconst = nb.nconst AND p.category IN ('actor','actress') AND tb.titleType = 'movie'
)
AND EXISTS (
  SELECT 1 FROM title_principals p2
  JOIN title_basics tb2 ON p2.tconst = tb2.tconst
  WHERE p2.nconst = nb.nconst AND p2.category IN ('actor','actress') AND tb2.titleType IN ('tvSeries','tvMiniSeries','tvMovie')
);


-- INT 3: Identify directors who have only directed movies with ratings above 7.0.
SELECT d.nconst, d.primaryName
FROM name_basics d
JOIN title_principals p ON d.nconst = p.nconst
JOIN title_basics tb ON p.tconst = tb.tconst
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE p.category = 'director'
GROUP BY d.nconst, d.primaryName
HAVING MIN(tr.averageRating) > 7
   AND SUM(CASE WHEN tb.titleType <> 'movie' THEN 1 ELSE 0 END) = 0;


-- INT 4: Find the title(s) with the largest cast size (count of distinct cast members).
SELECT tb.tconst, tb.primaryTitle, COUNT(DISTINCT p.nconst) AS cast_size
FROM title_basics tb
JOIN title_principals p ON tb.tconst = p.tconst
WHERE p.category IN ('actor','actress')
GROUP BY tb.tconst, tb.primaryTitle
ORDER BY cast_size DESC
LIMIT 1;


-- INT 5: For each decade, find the highest-rated movie.
WITH ranked_by_decade AS (
  SELECT
    FLOOR(tb.startYear/10)*10 AS decade,
    tb.tconst,
    tb.primaryTitle,
    tr.averageRating,
    RANK() OVER (PARTITION BY FLOOR(tb.startYear/10)*10 ORDER BY tr.averageRating DESC) AS rnk
  FROM title_basics tb
  JOIN title_ratings tr ON tb.tconst = tr.tconst
  WHERE tb.titleType = 'movie' AND tb.startYear IS NOT NULL AND tb.startYear <> '\N'
)
SELECT decade, tconst, primaryTitle, averageRating
FROM ranked_by_decade
WHERE rnk = 1
ORDER BY decade;


-- INT 6: Detect duplicate records (same primaryTitle and startYear).
SELECT primaryTitle, startYear, COUNT(*) AS dup_count
FROM title_basics
GROUP BY primaryTitle, startYear
HAVING COUNT(*) > 1
ORDER BY dup_count DESC;


-- INT 7: Find the genre with the largest average runtime.
WITH RECURSIVE seq AS (
  SELECT 1 AS n UNION ALL SELECT n+1 FROM seq WHERE n < 20
),
genre_split AS (
  SELECT
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tb.genres, ',', seq.n), ',', -1)) AS genre,
    tb.runtimeMinutes
  FROM title_basics tb
  JOIN seq ON seq.n <= 1 + (LENGTH(tb.genres) - LENGTH(REPLACE(tb.genres, ',', '')))
  WHERE tb.genres IS NOT NULL AND tb.runtimeMinutes IS NOT NULL AND tb.genres <> ''
)
SELECT genre, ROUND(AVG(runtimeMinutes),2) AS avg_runtime
FROM genre_split
GROUP BY genre
ORDER BY avg_runtime DESC
LIMIT 1;


-- INT 8: Get the median runtime for movies in each genre.
-- Approach: compute row_number per genre ordered by runtime and choose the middle element.
WITH RECURSIVE seq AS (
  SELECT 1 AS n UNION ALL SELECT n+1 FROM seq WHERE n < 20
),
genre_values AS (
  SELECT
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tb.genres, ',', seq.n), ',', -1)) AS genre,
    tb.runtimeMinutes
  FROM title_basics tb
  JOIN seq ON seq.n <= 1 + (LENGTH(tb.genres) - LENGTH(REPLACE(tb.genres, ',', '')))
  WHERE tb.genres IS NOT NULL AND tb.runtimeMinutes IS NOT NULL AND tb.genres <> '' AND tb.titleType = 'movie'
),
with_rank AS (
  SELECT
    genre,
    runtimeMinutes,
    ROW_NUMBER() OVER (PARTITION BY genre ORDER BY runtimeMinutes) AS rn,
    COUNT(*) OVER (PARTITION BY genre) AS cnt
  FROM genre_values
)
SELECT
  genre,
  ROUND(
    AVG(CASE
      WHEN cnt % 2 = 1 AND rn = (cnt+1)/2 THEN runtimeMinutes
      WHEN cnt % 2 = 0 AND (rn = (cnt/2) OR rn = (cnt/2)+1) THEN runtimeMinutes
      ELSE NULL END
    ),2) AS median_runtime
FROM with_rank
GROUP BY genre
ORDER BY genre;


-- INT 9: Identify actors who have never worked with a specific director (Christopher Nolan).
-- (Find actors who have acted in at least one title, but not in any title directed by Christopher Nolan)
WITH nolan AS (
  SELECT p.tconst
  FROM title_principals p
  JOIN name_basics n ON p.nconst = n.nconst
  WHERE p.category = 'director' AND n.primaryName = 'Christopher Nolan'
),
actors_with_nolan AS (
  SELECT DISTINCT p.nconst
  FROM title_principals p
  WHERE p.category IN ('actor','actress') AND p.tconst IN (SELECT tconst FROM nolan)
)
SELECT DISTINCT nb.nconst, nb.primaryName
FROM name_basics nb
JOIN title_principals p ON nb.nconst = p.nconst
WHERE p.category IN ('actor','actress')
  AND nb.nconst NOT IN (SELECT nconst FROM actors_with_nolan);


-- INT 10: Pivot genres into columns (example for a few popular genres) for the last 10 years.
-- Adjust genre list as needed. This shows counts per genre per year.
WITH RECURSIVE seq AS (
  SELECT 1 AS n UNION ALL SELECT n+1 FROM seq WHERE n < 20
),
genre_split AS (
  SELECT
    tb.startYear,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tb.genres, ',', seq.n), ',', -1)) AS genre
  FROM title_basics tb
  JOIN seq ON seq.n <= 1 + (LENGTH(tb.genres) - LENGTH(REPLACE(tb.genres, ',', '')))
  WHERE tb.startYear IS NOT NULL
    AND tb.startYear <> '\N'
    AND tb.startYear >= (YEAR(CURDATE()) - 10)
)
SELECT
  startYear,
  SUM(genre = 'Action')   AS action_count,
  SUM(genre = 'Drama')    AS drama_count,
  SUM(genre = 'Comedy')   AS comedy_count,
  SUM(genre = 'Thriller') AS thriller_count,
  SUM(genre = 'Romance')  AS romance_count
FROM genre_split
GROUP BY startYear
ORDER BY startYear;