DROP DATABASE IF EXISTS imdb;
CREATE DATABASE imdb;
USE imdb;

SET GLOBAL local_infile = 1;

DROP TABLE IF EXISTS title_ratings;
DROP TABLE IF EXISTS title_principals;
DROP TABLE IF EXISTS title_crew;
DROP TABLE IF EXISTS title_akas;
DROP TABLE IF EXISTS title_basics;
DROP TABLE IF EXISTS name_basics;
DROP TABLE IF EXISTS title_episode;

CREATE TABLE name_basics (
    nconst VARCHAR(20) PRIMARY KEY,
    primaryName VARCHAR(255),
    birthYear INT NULL,
    deathYear INT NULL,
    primaryProfession VARCHAR(255),
    knownForTitles VARCHAR(255)
);

CREATE TABLE title_basics (
    tconst VARCHAR(20) PRIMARY KEY,
    titleType VARCHAR(50),
    primaryTitle VARCHAR(255),
    originalTitle VARCHAR(255),
    isAdult BOOLEAN,
    startYear INT NULL,
    endYear INT NULL,
    runtimeMinutes INT NULL,
    genres VARCHAR(255)
);

CREATE TABLE title_akas (
    titleId VARCHAR(20),
    ordering INT,
    title VARCHAR(255),
    region VARCHAR(50),
    language VARCHAR(50),
    types VARCHAR(255),
    attributes VARCHAR(255),
    isOriginalTitle BOOLEAN,
    PRIMARY KEY (titleId, ordering),
    FOREIGN KEY (titleId) REFERENCES title_basics(tconst)
);

CREATE TABLE title_crew (
    tconst VARCHAR(20) PRIMARY KEY,
    directors VARCHAR(255),
    writers VARCHAR(255),
    FOREIGN KEY (tconst) REFERENCES title_basics(tconst)
);

CREATE TABLE title_principals (
    tconst VARCHAR(20),
    ordering INT,
    nconst VARCHAR(20),
    category VARCHAR(50),
    job VARCHAR(255),
    characters VARCHAR(255),
    PRIMARY KEY (tconst, ordering),
    FOREIGN KEY (tconst) REFERENCES title_basics(tconst),
    FOREIGN KEY (nconst) REFERENCES name_basics(nconst)
);

CREATE TABLE title_ratings (
    tconst VARCHAR(20) PRIMARY KEY,
    averageRating DECIMAL(3,1),
    numVotes INT,
    FOREIGN KEY (tconst) REFERENCES title_basics(tconst)
);

CREATE TABLE title_episode (
    tconst VARCHAR(20) PRIMARY KEY,
    parentTconst VARCHAR(20),
    seasonNumber INT NULL,
    episodeNumber INT NULL,
    FOREIGN KEY (parentTconst) REFERENCES title_basics(tconst)
);

LOAD DATA LOCAL INFILE 'C:\\great learning self paced\\1_sql\\revising sql\\imdb\\dataset\\title.basics.tsv'
INTO TABLE title_basics
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes, genres);

LOAD DATA LOCAL INFILE 'C:\\great learning self paced\\1_sql\\revising sql\\imdb\\dataset\\name.basics.tsv'
INTO TABLE name_basics
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(nconst, primaryName, birthYear, deathYear, primaryProfession, knownForTitles);

LOAD DATA LOCAL INFILE 'C:\\great learning self paced\\1_sql\\revising sql\\imdb\\dataset\\title.akas.tsv'
INTO TABLE title_akas
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(titleId, ordering, title, region, language, types, attributes, isOriginalTitle);

LOAD DATA LOCAL INFILE 'C:\\great learning self paced\\1_sql\\revising sql\\imdb\\dataset\\title.principals.tsv'
INTO TABLE title_principals
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, ordering, nconst, category, job, characters);

LOAD DATA LOCAL INFILE 'C:\\great learning self paced\\1_sql\\revising sql\\imdb\\dataset\\title.crew.tsv'
INTO TABLE title_crew
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, directors, writers);

LOAD DATA LOCAL INFILE 'C:\\great learning self paced\\1_sql\\revising sql\\imdb\\dataset\\title.episode.tsv'
INTO TABLE title_episode
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, parentTconst, seasonNumber, episodeNumber);

LOAD DATA LOCAL INFILE 'C:\\great learning self paced\\1_sql\\revising sql\\imdb\\dataset\\title.ratings.tsv'
INTO TABLE title_ratings
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, averageRating, numVotes);

