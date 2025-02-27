# Generated by Django 4.2 on 2024-06-23 11:33

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Movie',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=255)),
                ('genre', models.CharField(max_length=255)),
                ('description', models.TextField()),
                ('cast', models.TextField()),
                ('director', models.CharField(max_length=255)),
                ('release_date', models.DateField()),
                ('imageurl', models.URLField()),
                ('language', models.CharField(max_length=255)),
                ('type', models.CharField(max_length=255)),
            ],
        ),
    ]
