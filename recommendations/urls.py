
from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('recommend/', views.recommend, name='recommend'),
    path('eng_movies/', views.eng_movies, name='eng_movies'),
    path('eng_shows/', views.eng_shows, name='eng_shows'),
    path('urdu_movies/', views.urdu_movies, name='urdu_movies'),
    path('urdu_shows/', views.urdu_shows, name='urdu_shows'),
]