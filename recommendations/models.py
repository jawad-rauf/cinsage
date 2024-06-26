from django.db import models

class Movie(models.Model):
    title = models.CharField(max_length=255)
    genre = models.CharField(max_length=255)
    description = models.TextField()
    cast = models.TextField()
    director = models.CharField(max_length=255)
    release_date = models.DateField()
    imageurl = models.URLField()
    language = models.CharField(max_length=255)
    type = models.CharField(max_length=255)
    
    def __str__(self):
        return self.title
