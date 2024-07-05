import pandas as pd
import tensorflow as tf
import tensorflow_recommenders as tfrs
from sklearn.model_selection import train_test_split
from IPython.display import Image, display

# Load the data
data = pd.read_csv('data.csv')

# Display the column names to verify
print(data.columns)

# Prepare the data (using 'index' for user_id and 'Movie ID' for movie_id)
data['index'] = data['index'].astype(str)
data['Movie ID'] = data['Movie ID'].astype(str)

# Ensure all relevant columns are of the correct type
data['rating'] = data['rating'].astype(float)
data['release_date'] = pd.to_datetime(data['release_date'], errors='coerce')
data['popularity'] = data['popularity'].astype(float)


train, test = train_test_split(data, test_size=0.2)


train_ds = tf.data.Dataset.from_tensor_slices({
    'index': train['index'].values,
    'Movie ID': train['Movie ID'].values
})

test_ds = tf.data.Dataset.from_tensor_slices({
    'index': test['index'].values,
    'Movie ID': test['Movie ID'].values
})


class UserModel(tf.keras.Model):
    def __init__(self):
        super().__init__()
        self.embedding = tf.keras.Sequential([
            tf.keras.layers.StringLookup(vocabulary=train['index'].unique(), mask_token=None),
            tf.keras.layers.Embedding(len(train['index'].unique()) + 1, 32)
        ])

    def call(self, inputs):
        return self.embedding(inputs)

class MovieModel(tf.keras.Model):
    def __init__(self):
        super().__init__()
        self.embedding = tf.keras.Sequential([
            tf.keras.layers.StringLookup(vocabulary=train['Movie ID'].unique(), mask_token=None),
            tf.keras.layers.Embedding(len(train['Movie ID'].unique()) + 1, 32)
        ])

    def call(self, inputs):
        return self.embedding(inputs)


class MovielensModel(tfrs.Model):
    def __init__(self):
        super().__init__()
        self.user_model = UserModel()
        self.movie_model = MovieModel()
        self.task = tfrs.tasks.Retrieval(
            metrics=tfrs.metrics.FactorizedTopK(
                candidates=tf.data.Dataset.from_tensor_slices(
                    data['Movie ID'].astype(str).values
                ).batch(128).map(self.movie_model)
            )
        )

    def compute_loss(self, features, training=False):
        user_embeddings = self.user_model(features['index'])
        movie_embeddings = self.movie_model(features['Movie ID'])
        return self.task(user_embeddings, movie_embeddings)

model = MovielensModel()
model.compile(optimizer=tf.keras.optimizers.Adagrad(learning_rate=0.1))


cached_train = train_ds.batch(8192).cache()
cached_test = test_ds.batch(4096).cache()
model.fit(cached_train, epochs=3)


def display_movie_details(movies):
    for i, movie in enumerate(movies.iterrows(), 1):
        index, data = movie
        print(f"   Title: {data['title']}")
        print(f"   Genre: {data['genre']}")
        release_date = pd.to_datetime(data['release_date'], errors='coerce').date() if data['release_date'] else 'Unknown'
        print(f"   Release Date: {release_date}")
        print(f"   Cast: {data['cast']}")
        print(f"   Director: {data['director']}")
        print(f"   Description: {data['description']}")
        print(f"   User Rating: {data['rating']}")
        print(f"   Popularity: {data['popularity']}")
        print(f"   Movie ID: {data['Movie ID']}")
        print()  # Empty line for readability
        
        image_url = data['imageurl'] if isinstance(data['imageurl'], str) else 'https://via.placeholder.com/150'
        print(f"   Image URL: {image_url}")
        display(Image(url=image_url))
        print()


def recommend_movies(user_id, model, movies_data, k=10):
    user_embedding = model.user_model(tf.convert_to_tensor([str(user_id)]))
    candidate_embeddings = model.movie_model.embeddings
    scores = tf.matmul(user_embedding, candidate_embeddings, transpose_b=True)
    top_k = tf.math.top_k(scores, k=k).indices.numpy()

    recommended_movie_ids = [model.movie_model.embeddings.numpy()[i] for i in top_k[0]]
    recommended_movies = movies_data[movies_data['Movie ID'].isin(recommended_movie_ids)]
    display_movie_details(recommended_movies)


def evaluate_model(model, test_data, k=10):
    test_ratings = []
    for test_sample in test_data:
        user_id = test_sample['index'].numpy().decode('utf-8')
        true_movie_id = test_sample['Movie ID'].numpy().decode('utf-8')
        user_embedding = model.user_model(tf.convert_to_tensor([str(user_id)]))
        candidate_embeddings = model.movie_model.embeddings
        scores = tf.matmul(user_embedding, candidate_embeddings, transpose_b=True)
        top_k = tf.math.top_k(scores, k=k).indices.numpy()
        recommended_movie_ids = [model.movie_model.embeddings.numpy()[i] for i in top_k[0]]
        test_ratings.append((true_movie_id in recommended_movie_ids))
    
    accuracy = sum(test_ratings) / len(test_ratings)
    return accuracy


user_id = input('Enter your user ID: ')
recommend_movies(user_id, model, data, k=10)
