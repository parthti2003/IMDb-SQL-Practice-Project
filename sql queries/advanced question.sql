-- Section 3 – Advanced (10 Questions)
-- Purpose: Master subqueries, CTEs, window functions.
-- Tables used: All.

/* ADV 1: Top 3 actors with the highest average movie rating (actors+actresses). */
WITH actor_avg AS (
  SELECT
    p.nconst,
    nb.primaryName,
    AVG(tr.averageRating) AS avg_rating,
    COUNT(*) AS movies_count
  FROM title_principals p
  JOIN name_basics nb ON p.nconst = nb.nconst
  JOIN title_ratings tr ON p.tconst = tr.tconst
  JOIN title_basics tb ON p.tconst = tb.tconst
  WHERE p.category IN ('actor','actress') AND tb.titleType = 'movie'
  GROUP BY p.nconst, nb.primaryName
  HAVING COUNT(*) >= 1
)
SELECT nconst, primaryName, ROUND(avg_rating,3) AS avg_rating, movies_count
FROM actor_avg
ORDER BY avg_rating DESC
LIMIT 3;


-- ADV 2: Movies where runtimeMinutes is above the 90th percentile (by runtime).
/* Use PERCENT_RANK() over ordered runtime and keep rows with percentile >= 0.9 */
WITH runtime_ranks AS (
  SELECT
    tconst, primaryTitle, runtimeMinutes,
    PERCENT_RANK() OVER (ORDER BY runtimeMinutes) AS pct_rank
  FROM title_basics
  WHERE runtimeMinutes IS NOT NULL
)
SELECT tconst, primaryTitle, runtimeMinutes
FROM runtime_ranks
WHERE pct_rank >= 0.9
ORDER BY runtimeMinutes DESC;


-- ADV 3: For each genre, find the highest-rated movie and its rating.
-- We split genres using a small sequence CTE and SUBSTRING_INDEX.
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n+1 FROM seq WHERE n < 20
),
genre_split AS (
  SELECT
    tb.tconst,
    tb.primaryTitle,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tb.genres, ',', seq.n), ',', -1)) AS genre,
    tr.averageRating
  FROM title_basics tb
  JOIN title_ratings tr USING (tconst)
  JOIN seq ON seq.n <= 1 + (LENGTH(tb.genres) - LENGTH(REPLACE(tb.genres, ',', '')))
  WHERE tb.genres IS NOT NULL AND tb.genres <> ''
),
ranked AS (
  SELECT
    genre, primaryTitle, averageRating,
    RANK() OVER (PARTITION BY genre ORDER BY averageRating DESC) AS rnk
  FROM genre_split
)
SELECT genre, primaryTitle, averageRating
FROM ranked
WHERE rnk = 1
ORDER BY genre;


-- ADV 4: Rank all movies by averageRating within their genre using RANK().
WITH RECURSIVE seq AS (
  SELECT 1 AS n UNION ALL SELECT n+1 FROM seq WHERE n < 20
),
genre_split AS (
  SELECT
    tb.tconst,
    tb.primaryTitle,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tb.genres, ',', seq.n), ',', -1)) AS genre,
    tr.averageRating
  FROM title_basics tb
  JOIN title_ratings tr USING (tconst)
  JOIN seq ON seq.n <= 1 + (LENGTH(tb.genres) - LENGTH(REPLACE(tb.genres, ',', '')))
  WHERE tb.genres IS NOT NULL AND tb.genres <> ''
)
SELECT genre, primaryTitle, averageRating,
       RANK() OVER (PARTITION BY genre ORDER BY averageRating DESC) AS rank_in_genre
FROM genre_split
ORDER BY genre, rank_in_genre;


-- ADV 5: Cumulative number of movies released per year (running total).
SELECT
  startYear,
  COUNT(*) AS movies_this_year,
  SUM(COUNT(*)) OVER (ORDER BY startYear) AS cumulative_movies
FROM title_basics
WHERE titleType = 'movie' AND startYear IS NOT NULL AND startYear <> '\N'
GROUP BY startYear
ORDER BY startYear;


-- ADV 6: Top 5 directors based on total votes across all their movies.
SELECT
  nb.nconst,
  nb.primaryName AS director,
  SUM(tr.numVotes) AS total_votes,
  COUNT(DISTINCT p.tconst) AS movies_count
FROM title_principals p
JOIN name_basics nb ON p.nconst = nb.nconst
JOIN title_ratings tr ON p.tconst = tr.tconst
JOIN title_basics tb ON p.tconst = tb.tconst
WHERE p.category = 'director' AND tb.titleType = 'movie'
GROUP BY nb.nconst, nb.primaryName
ORDER BY total_votes DESC
LIMIT 5;


-- ADV 7: List all titles where max(runtimeMinutes) - min(runtimeMinutes) per genre > 60,
-- and return the titles for those genres.
WITH RECURSIVE seq AS (
  SELECT 1 AS n UNION ALL SELECT n+1 FROM seq WHERE n < 20
),
genre_stats AS (
  SELECT
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tb.genres, ',', seq.n), ',', -1)) AS genre,
    MAX(tb.runtimeMinutes) AS max_rt,
    MIN(tb.runtimeMinutes) AS min_rt
  FROM title_basics tb
  JOIN seq ON seq.n <= 1 + (LENGTH(tb.genres) - LENGTH(REPLACE(tb.genres, ',', '')))
  WHERE tb.genres IS NOT NULL AND tb.runtimeMinutes IS NOT NULL AND tb.genres <> ''
  GROUP BY genre
  HAVING (MAX(tb.runtimeMinutes) - MIN(tb.runtimeMinutes)) > 60
)
SELECT gs.genre, tb.tconst, tb.primaryTitle, tb.runtimeMinutes
FROM genre_stats gs
JOIN title_basics tb ON tb.genres LIKE CONCAT('%', gs.genre, '%')
ORDER BY gs.genre, tb.primaryTitle;


-- ADV 8: Percentage of titles per titleType relative to all titles.
SELECT
  titleType,
  COUNT(*) AS type_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_of_total
FROM title_basics
GROUP BY titleType
ORDER BY percentage_of_total DESC;


-- ADV 9: Top 10 most frequently collaborating actor–director pairs.
SELECT
  a.nconst AS actor_nconst,
  a.primaryName AS actor_name,
  d.nconst AS director_nconst,
  d.primaryName AS director_name,
  COUNT(*) AS collaborations
FROM title_principals pa
JOIN name_basics a ON pa.nconst = a.nconst
JOIN title_principals pd ON pa.tconst = pd.tconst
JOIN name_basics d ON pd.nconst = d.nconst
WHERE pa.category IN ('actor','actress') AND pd.category = 'director'
GROUP BY actor_nconst, actor_name, director_nconst, director_name
ORDER BY collaborations DESC
LIMIT 10;


-- ADV 10: Identify the year with the highest average IMDb rating.
SELECT startYear, ROUND(AVG(tr.averageRating),3) AS avg_rating
FROM title_basics tb
JOIN title_ratings tr USING (tconst)
WHERE startYear IS NOT NULL AND startYear <> '\N'
GROUP BY startYear
ORDER BY avg_rating DESC
LIMIT 1;




