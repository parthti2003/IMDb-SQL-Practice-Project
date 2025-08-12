-- Section 2 – Intermediate (10 Questions)
-- Purpose: Strengthen joins, aggregations, filtering, grouping.
-- Tables used: title_principals, title_crew, title_ratings.

-- 1. List all titles along with their directors’ names.

SELECT tb.primaryTitle, nb.primaryName AS director
FROM title_principals tp
JOIN name_basics nb USING (nconst)
JOIN title_basics tb USING (tconst)
WHERE tp.category = 'director';

-- 2. Find the top 5 highest-rated movies (only movies) with at least 1000 votes.

select primaryTitle from title_ratings join title_basics using(tconst)
where numvotes > 1000 and titletype = "movie"
order by averageRating desc
limit 5;

-- 3. Show the number of titles in each genre, sorted by count descending.

select count(tconst) number_title, genres from title_basics
group by genres
order by number_title desc;

-- 4. Find all actors (primaryProfession contains 'actor' or 'actress') who have worked in more than 5 titles.

select primaryname from name_basics join title_principals using (nconst)
where primaryProfession like "%actor%" or primaryProfession like "%actress%"
group by primaryName
having count(primaryname)>5;

-- 5. Count how many titles each director has worked on.

select count(nconst) num_of_title, nconst from title_principals
where category = "director"
group by nconst
order by num_of_title desc;

-- 6. List titles with multiple genres (where genres contains a comma).

select primarytitle from title_basics
where genres like '%,%';

-- 7. Show the total number of movies released each year from 2000 onwards.

select count(primarytitle) totalmovies, startYear from title_basics
where startYear > 2000
group by startYear;

-- 8. Get the average rating for each genre.

select round(avg(averagerating),2) avgrating, genres from title_basics join title_ratings using (tconst)
group by genres;

-- 9. Show all titles where the director has also acted in the same movie.

SELECT DISTINCT tb.primaryTitle, p1.category
FROM title_principals p1
JOIN title_principals p2
    ON p1.tconst = p2.tconst
   AND p1.nconst = p2.nconst
JOIN title_basics tb
    ON tb.tconst = p1.tconst
WHERE p1.category = 'director'
  AND (p2.category = 'actor' OR p2.category = 'actress');

-- 10. Find all titles that have the same primaryTitle but different startYear

SELECT primaryTitle
FROM title_basics
GROUP BY primaryTitle
HAVING COUNT(DISTINCT startYear) > 1;
