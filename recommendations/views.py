from django.http import JsonResponse
from django.shortcuts import render
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Load data and preprocess
movies_data = pd.read_csv('data.csv')
selected_features = ['title', 'genre', 'description', 'cast', 'director', 'type', 'language', 'release_date']
for feature in selected_features:
    movies_data[feature] = movies_data[feature].fillna('')

movies_data['combined_features'] = movies_data['title'] + ' ' + movies_data['genre'] + ' ' + movies_data['description'] + ' ' + movies_data['cast'] + ' ' + movies_data['director']
vectorizer = TfidfVectorizer()
feature_vectors = vectorizer.fit_transform(movies_data['combined_features'])
similarity = cosine_similarity(feature_vectors)

def recommend_by_genre_type_language(genre, type_choice, language):
    genre_list = [g.strip().lower() for g in genre.split(',')]
    filtered_movies = movies_data[
        (movies_data['type'].str.contains(type_choice, case=False)) &
        (movies_data['language'].str.contains(language, case=False))
    ]
    for g in genre_list:
        filtered_movies = filtered_movies[filtered_movies['genre'].str.lower().str.contains(g)]
    filtered_movies = filtered_movies.dropna(subset=['release_date']).drop_duplicates(subset='title').sort_values(by='release_date', ascending=False)
    return filtered_movies

def recommend(request):
    genre = request.GET.get('genre', '')
    type_choice = request.GET.get('type_choice', '').capitalize()
    language = request.GET.get('language', '').capitalize()

    if genre and type_choice and language:
        recommendations = recommend_by_genre_type_language(genre, type_choice, language)
    else:
        recommendations = pd.DataFrame()

    return JsonResponse(recommendations.to_dict('records'), safe=False)

def index(request):
    return render(request, 'index.html')

def eng_movies(request):
    genre = request.GET.get('genre', '')
    type_choice = 'Movies'
    language = 'English'
    recommended_movies = recommend_by_genre_type_language(genre, type_choice, language)
    return JsonResponse(recommended_movies.to_dict('records'), safe=False)

def eng_shows(request):
    genre = request.GET.get('genre', '')
    type_choice = 'Shows'
    language = 'English'
    recommended_shows = recommend_by_genre_type_language(genre, type_choice, language)
    return JsonResponse(recommended_shows.to_dict('records'), safe=False)

def urdu_movies(request):
    genre = request.GET.get('genre', '')
    type_choice = 'Movies'
    language = 'Urdu'
    recommended_movies = recommend_by_genre_type_language(genre, type_choice, language)
    return JsonResponse(recommended_movies.to_dict('records'), safe=False)

def urdu_shows(request):
    genre = request.GET.get('genre', '')
    type_choice = 'Shows'
    language = 'Urdu'
    recommended_shows = recommend_by_genre_type_language(genre, type_choice, language)
    return JsonResponse(recommended_shows.to_dict('records'), safe=False)
