import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import logging

logger = logging.getLogger(__name__)

def recommend_by_genre_type_language(genre, type_choice, language, movies_data, similarity):
    logger.info(f"Genre: {genre}, Type: {type_choice}, Language: {language}")
    
    try:
        # Split the input genre string into a list of genres
        genre_list = [g.strip().lower() for g in genre.split(',')]
        logger.info(f"Genre List: {genre_list}")
        
        # Filter movies by type and language first
        filtered_movies = movies_data[
            (movies_data['type'].str.contains(type_choice, case=False)) &
            (movies_data['language'].str.contains(language, case=False))
        ]
        logger.info(f"Filtered Movies Data by Type and Language: {filtered_movies.head()}")
        
        # Further filter by genre (all specified genres must be present)
        for g in genre_list:
            filtered_movies = filtered_movies[filtered_movies['genre'].str.lower().str.contains(g)]
            logger.info(f"Filtered Movies Data by Genre '{g}': {filtered_movies.head()}")
        
        if filtered_movies.empty:
            logger.info(f"No results found for the genre(s) '{genre}' with type '{type_choice}' and language '{language}'.")
            return []

        # Convert the 'release_date' to datetime format to enable sorting
        filtered_movies['release_date'] = pd.to_datetime(filtered_movies['release_date'], errors='coerce')

        # Drop rows with invalid release dates
        filtered_movies = filtered_movies.dropna(subset=['release_date'])

        # Remove duplicate movies
        filtered_movies = filtered_movies.drop_duplicates(subset='title')

        # Sort movies by release date in descending order (latest movies first)
        sorted_movies = filtered_movies.sort_values(by='release_date', ascending=False)
        logger.info(f"Sorted Movies: {sorted_movies.head()}")

        # Format recommendations to JSON-like dictionary
        recommendations = sorted_movies[['title', 'genre', 'description', 'cast', 'director', 'type', 'language', 'release_date', 'imageurl']].to_dict(orient='records')
        
        return recommendations
    except Exception as e:
        logger.error(f"Error in recommend_by_genre_type_language: {str(e)}")
        return []
