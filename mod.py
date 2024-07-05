import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from IPython.display import Image, display
import itertools

# Loading the data from the combined CSV file into a pandas DataFrame
movies_data = pd.read_csv('data.csv')

# Selecting the relevant features for recommendation
selected_features = ['title', 'genre', 'description', 'cast', 'director', 'type', 'language', 'release_date']

# Fill NaN values with empty strings in the selected features
for feature in selected_features:
    movies_data[feature] = movies_data[feature].fillna('')

# Combining all the selected features into a single text string
movies_data['combined_features'] = movies_data['title'] + ' ' + movies_data['genre'] + ' ' + movies_data['description'] + ' ' + movies_data['cast'] + ' ' + movies_data['director']

# Converting the text data to feature vectors using TF-IDF
vectorizer = TfidfVectorizer()
feature_vectors = vectorizer.fit_transform(movies_data['combined_features'])

# Calculate cosine similarity
similarity = cosine_similarity(feature_vectors)

def display_movie_details(movies):
    for _, data in movies.iterrows():
        print(f"   Title: {data['title']}")
        print(f"   Genre: {data['genre']}")
        release_date = pd.to_datetime(data['release_date'], errors='coerce').date() if data['release_date'] else 'Unknown'
        print(f"   Release Date: {release_date}")
        print(f"   Cast: {data['cast']}")
        print(f"   Director: {data['director']}")
        print(f"   Description: {data['description']}")
        print(f"   Movie ID: {data['Movie ID']}")
        print()  # Empty line for readability
        
        image_url = data['imageurl'] if isinstance(data['imageurl'], str) else 'https://via.placeholder.com/150'
        print(f"   Image URL: {image_url}")
        display(Image(url=image_url))
        print()

def recommend_by_genre_type_language(genre, type_choice, language, movies_data, similarity):
    genre_list = [g.strip().lower() for g in genre.split(',')]
    filtered_movies = movies_data[
        (movies_data['type'].str.contains(type_choice, case=False)) &
        (movies_data['language'].str.contains(language, case=False))
    ]
    
    found_movies = pd.DataFrame()
    
    for i in range(len(genre_list), 0, -1):
        for subset in itertools.combinations(genre_list, i):
            subset_str = '|'.join(subset)
            subset_movies = filtered_movies[filtered_movies['genre'].str.lower().str.contains(subset_str)]
            
            # Check that the movie has all genres in the subset
            subset_movies = subset_movies[subset_movies['genre'].apply(lambda x: all(g in x.lower() for g in subset))]
            
            if not subset_movies.empty:
                subset_movies = subset_movies.copy()  # Ensure we're working on a copy
                subset_movies.loc[:, 'release_date'] = pd.to_datetime(subset_movies['release_date'], errors='coerce')
                subset_movies = subset_movies.dropna(subset=['release_date'])
                subset_movies = subset_movies.drop_duplicates(subset='title')
                sorted_movies = subset_movies.sort_values(by='release_date', ascending=False)
                found_movies = pd.concat([found_movies, sorted_movies])
                
                if not found_movies.empty:
                    found_movies = found_movies.drop_duplicates(subset='title')
                    print(f"Recommendations for the genre(s) '{', '.join(subset)}' with type '{type_choice}' and language '{language}':\n")
                    display_movie_details(found_movies[:20])
                    return

def get_similar_movies(movie_title, movies_data, similarity):
    if not movie_title.strip():
        return pd.DataFrame()  # Return an empty DataFrame if the movie title is empty
    
    try:
        movie_index = movies_data[movies_data['title'].str.lower() == movie_title.lower()].index[0]
    except IndexError:
        print(f"No movie found with the title '{movie_title}'")
        return pd.DataFrame()
        
    similarity_scores = list(enumerate(similarity[movie_index]))
    sorted_similar_movies = sorted(similarity_scores, key=lambda x: x[1], reverse=True)
    similar_movie_indices = [movie[0] for movie in sorted_similar_movies[1:11]]
    similar_movies = movies_data.iloc[similar_movie_indices]
    similar_movies = similar_movies.drop_duplicates(subset='title')
    similar_movies['release_date'] = pd.to_datetime(similar_movies['release_date'], errors='coerce')
    entered_movie = movies_data.iloc[movie_index]
    similar_movies = pd.concat([pd.DataFrame([entered_movie]), similar_movies])

    return similar_movies

# Getting inputs from the user
genre = input('Enter your favorite movie/show genre (comma separated for multiple): ')
type_choice = input('Are you interested in Movies or Shows? ').capitalize()
language = input('Which language do you prefer (English/Urdu)? ').capitalize()
movie_title = input('Enter a movie title you like (for better recommendations): ')

# Recommend movies or shows based on user input
recommend_by_genre_type_language(genre, type_choice, language, movies_data, similarity)

# Recommend similar movies based on a liked movie title
if movie_title.strip():  # Only try to find similar movies if a title is provided
    similar_movies = get_similar_movies(movie_title, movies_data, similarity)
    if not similar_movies.empty:
        print(f"\nMovies similar to '{movie_title}':\n")
        display_movie_details(similar_movies)
