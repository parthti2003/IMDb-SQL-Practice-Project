-- Section 1 – Basics (10 Questions)
-- Purpose: Warm-up, ensure all syntax fundamentals are rock solid.
-- Tables used: name_basics, title_basics, title_ratings.
use imdb;
-- 1. List the first 20 rows from name_basics.
select * from name_basics
limit 20;

-- 2. Find all distinct primaryProfession values.

select distinct primaryProfession from name_basics;

-- 3. Count how many people were born in each birthYear (ignore NULLs).
select count(birthyear), birthyear from name_basics
where birthyear is not null
group by birthYear
order by birthyear;

-- 4. Show all movies (titleType = 'movie') released after 2015 with their primaryTitle and startYear.

select * from title_basics 
where titleType = 'movie' and startYear > 2015;

-- 5. Get all movies with runtimeMinutes > 120, sorted from longest to shortest.

select * from title_basics
where runtimeMinutes > 120
and titleType = 'movie'
order by runtimeMinutes desc;

-- 6. Find the number of titles per titleType.

select count(titletype) number_title, titletype from title_basics
group by titleType;

-- 7. Get the average runtimeMinutes of all movies.

select avg(runtimeminutes) avgRuntime from title_basics
where titleType= 'movie';

-- 8. Show the top 10 oldest people in name_basics (based on birthYear).

select (deathyear - birthyear) as age, primaryname from name_basics
where (deathyear - birthyear) is not null
order by age desc
limit 10;

-- 9. Find all titles where genres contains 'Comedy'.

select primarytitle from title_basics
where genres like "%comedy%";

-- 10. Get the tconst and averageRating of all titles rated above 8.0.

select tconst, averagerating from title_ratings
where averageRating > 8.0;