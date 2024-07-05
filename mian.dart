import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cinsage/Chat.dart';
import 'package:cinsage/Chatbot.dart';
import 'package:cinsage/Survey.dart';
import 'package:cinsage/accounts.dart';
import 'package:csv/csv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cinsage/firebase_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'const.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Gemini.init(apiKey: GEMINI_API_KEY);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TMDB Flutter App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        secondaryHeaderColor: Colors.black,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Colors.blue,
          onPrimary: Colors.red,
          secondary: Colors.red,
          onSecondary: Colors.lightBlueAccent,
          error: Colors.red,
          onError: Colors.redAccent,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
      ),
      home: const MovieListScreen(),
    );
  }
}

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  _MovieListScreenState createState() => _MovieListScreenState();

  void onApplyFilters(
      List<String> selectedGenres,
      DateTime? selectedReleaseDate,
      String? selectedLanguage,
      double? selectedRating) {}
}

class _MovieListScreenState extends State<MovieListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DrawerController _drawerController;
  bool isLoading = true;
  bool hasError = false;

  List<dynamic> movies = [];
  List<dynamic> tvShows = [];
  List<dynamic> Umovies = [];
  List<dynamic> UtvShows = [];

  List<dynamic> movieRatings = [];
  List<dynamic> tvShowRatings = [];
  List<dynamic> umovieRatings = [];
  List<dynamic> utvShowRatings = [];
  List<String> selectedGenres = [];
  DateTime? selectedReleaseDate;
  String? selectedLanguage;
  double? selectedRating;
  int _selectedIndex = 0;

  void navToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          fetchMovies();
          fetchUrduMovies();
        } else if (_tabController.index == 1) {
          fetchTvShows();
          fetchUrduTvShows();
        }
      }
    });
    fetchMovies();
    fetchUrduMovies();
    fetchTvShows();
    fetchUrduTvShows();
  }

  Future<List<String>> fetchGenres() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final DatabaseReference genreRef = FirebaseDatabase.instance
        .ref()
        .child('user')
        .child(user.uid)
        .child('genre');

    final DatabaseEvent event = await genreRef.once();

    if (event.snapshot.value == null) {
      return [];
    }

    return List<String>.from(event.snapshot.value as List<dynamic>);
  }

  Future<void> fetchMovies() async {
    final url =
        'http://127.0.0.1:8000/recommend/?genre=Action&comedy&type_choice=movies&language=English';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          movies = data;
          movieRatings =
              data.map((movie) => movie['rating'].toDouble()).toList();
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> fetchTvShows() async {
    final url =
        'http://127.0.0.1:8000/recommend/?genre=action+%2C+Sci-Fi&type_choice=shows&language=English';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          tvShows = data;
          tvShowRatings =
              data.map((show) => show['rating'].toDouble()).toList();
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> fetchUrduMovies() async {
    final url =
        'http://127.0.0.1:8000/recommend/?genre=Romance&type_choice=MOVIE&language=urdu';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          Umovies = data;
          umovieRatings =
              data.map((movie) => movie['rating'].toDouble()).toList();
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> fetchUrduTvShows() async {
    final url =
        'http://127.0.0.1:8000/recommend/?genre=Drama&type_choice=shows&language=urdu';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          UtvShows = data;
          utvShowRatings =
              data.map((show) => show['rating'].toDouble()).toList();
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _openFiltersMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildGenresFilter(setState),
                    SizedBox(height: 16),
                    _buildReleaseDateFilter(context),
                    SizedBox(height: 16),
                    _buildLanguageFilter(setState),
                    SizedBox(height: 16),
                    _buildRatingFilter(setState),
                    SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilters(); // Apply the filters and fetch data
                          Navigator.pop(context); // Close the Filters menu
                        },
                        child: Text(
                          'Apply Filters',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    String genre = selectedGenres.join(','); // Join selected genres with commas
    String language = selectedLanguage ?? 'English';
    String type = _selectedIndex == 0 ? 'movies' : 'shows';
    String releaseDate = selectedReleaseDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedReleaseDate!)
        : '';
    double rating = selectedRating ?? 0.0;

    String url =
        'http://127.0.0.1:8000/recommend/?genre=$genre&type_choice=$type&language=$language';
    if (releaseDate.isNotEmpty) {
      url += '&release_date=$releaseDate';
    }
    if (rating > 0) {
      url += '&rating=$rating';
    }

    // Fetch filtered data based on type (movies or shows)
    if (_selectedIndex == 0) {
      fetchFilteredMovies(url);
    } else {
      fetchFilteredTvShows(url);
    }
  }

  Future<void> fetchFilteredMovies(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          movies = data;
          movieRatings =
              data.map((movie) => movie['rating'].toDouble()).toList();
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> fetchFilteredTvShows(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          tvShows = data;
          tvShowRatings =
              data.map((show) => show['rating'].toDouble()).toList();
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Widget _buildReleaseDateFilter(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Release Date'),
      subtitle: Text(selectedReleaseDate != null
          ? '${selectedReleaseDate!.toLocal()}'.split(' ')[0]
          : 'Any'),
      trailing: Icon(Icons.calendar_today),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedReleaseDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (picked != null) {
          setState(() {
            selectedReleaseDate = picked;
          });
        }
      },
    );
  }

  Widget _buildGenresFilter(StateSetter setState) {
    final genres = ['Action', 'Comedy', 'Drama', 'Horror', 'Romance', 'Sci-Fi'];

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: genres.map((genre) {
        final isSelected = selectedGenres.contains(genre);
        return FilterChip(
          label: Text(genre),
          selected: isSelected,
          selectedColor: Colors.blue,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                selectedGenres.add(genre);
              } else {
                selectedGenres.remove(genre);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildLanguageFilter(StateSetter setState) {
    final languages = ['English', 'Urdu'];

    return DropdownButtonFormField<String>(
      value: selectedLanguage,
      decoration: InputDecoration(
        labelText: 'Language',
        border: OutlineInputBorder(),
      ),
      items: languages.map((String language) {
        return DropdownMenuItem<String>(
          value: language,
          child: Text(language),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedLanguage = newValue;
        });
      },
    );
  }

  Widget _buildRatingFilter(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            for (int i = 1; i <= 10; i++)
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRating = i.toDouble();
                  });
                },
                child: Icon(
                  i <= (selectedRating ?? 0) ? Icons.star : Icons.star_border,
                  color:
                      i <= (selectedRating ?? 0) ? Colors.orange : Colors.grey,
                ),
              ),
          ],
        ),
        if (selectedRating != null)
          Text(
            '${selectedRating!.toInt()} Star${selectedRating! > 1 ? 's' : ''}',
            style: TextStyle(color: Colors.black),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomNavigationBar(),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(child: Text('Failed to load data'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      buildRatingSlideshow(
                          _selectedIndex == 0 ? movies : tvShows),
                      _buildSectionHeader('Popular'),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildHorizontalList(movies, movieRatings, true),
                            _buildHorizontalList(tvShows, tvShowRatings, false),
                          ],
                        ),
                      ),
                      _buildSectionHeader('Pakistani'),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildHorizontalList(Umovies, umovieRatings, true),
                            _buildHorizontalList(
                                UtvShows, utvShowRatings, false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Chatbot()),
          );
        },
        child: SvgPicture.asset(
          'assets/cb_icon.svg',
          width: 35,
          height: 35,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildHorizontalList(
      List<dynamic> items, List<dynamic> ratings, bool isMovie) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final posterPath = item['imageurl'];
        final posterUrl = posterPath != null &&
                posterPath != "Not Available" &&
                posterPath.isNotEmpty
            ? (posterPath.startsWith('http')
                ? posterPath
                : 'https://image.tmdb.org/t/p/w500/$posterPath')
            : 'https://via.placeholder.com/500x750?text=No+Image';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailsScreen(
                  title: item['title'] ?? item['name'] ?? 'N/A',
                  posterUrl: posterUrl,
                  releaseDate: item['release_date'] ?? '',
                  overview: item['description'] ?? 'No description available.',
                  rating: item['rating']?.toDouble() ?? 0.0,
                ),
              ),
            );
          },
          child: Container(
            width: 160,
            margin: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  item['title'],
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.0),
                Text(
                  'Rating: ${item['rating'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 14.0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.movie, size: 28, color: Colors.white),
          label: 'Movies',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.live_tv, size: 28, color: Colors.white),
          label: 'TV Shows',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat, size: 28, color: Colors.white),
          label: 'Chat',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
          _tabController.index = _selectedIndex;

          if (_selectedIndex == 0) {
            fetchMovies();
            fetchUrduMovies();
          } else if (_selectedIndex == 1) {
            fetchTvShows();
            fetchUrduTvShows();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatPage()),
            );
          }
        });
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Cinsage',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      elevation: 10,
      backgroundColor: Colors.black26,
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu, size: 24),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      actions: [
        IconButton(
          onPressed: _openFiltersMenu,
          icon: const Icon(Icons.tune, size: 24),
        ),
        IconButton(
          onPressed: () {
            showSearch(
              context: context,
              delegate: MovieSearchDelegate(
                selectedGenres: selectedGenres,
                selectedReleaseDate: selectedReleaseDate,
                selectedLanguage: selectedLanguage,
                selectedRating: selectedRating,
              ),
            );
          },
          icon: const Icon(Icons.search, size: 24),
        ),
      ],
      bottomOpacity: 0.5,
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 10),
                  Text(
                    'Cinsage',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.blueAccent),
            title: const Text('Account', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AccountsScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.feedback, color: Colors.blueAccent),
            title: const Text('Send Feedback', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.logout, color: Colors.black),
                label: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildRatingSlideshow(List<dynamic> items) {
    items.sort((a, b) => (b['rating'] ?? 0.0).compareTo(a['rating'] ?? 0.0));

    return CarouselSlider.builder(
      itemCount: items.length,
      options: CarouselOptions(
        height: 500.0,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        viewportFraction: 0.8,
      ),
      itemBuilder: (BuildContext context, int index, int realIndex) {
        final item = items[index];
        final posterPath = item['imageurl'];
        final posterUrl = posterPath != null &&
                posterPath != "Not Available" &&
                posterPath.isNotEmpty
            ? (posterPath.startsWith('http')
                ? posterPath
                : 'https://image.tmdb.org/t/p/w500/$posterPath')
            : 'https://via.placeholder.com/500x750?text=No+Image';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailsScreen(
                  title: item['title'] ?? item['name'] ?? 'N/A',
                  posterUrl: posterUrl,
                  releaseDate: item['release_date'] ?? '',
                  overview: item['description'] ?? 'No description available.',
                  rating: item['rating']?.toDouble() ?? 0.0,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(8.0),
            width: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              image: DecorationImage(
                image: NetworkImage(posterUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class MovieDetailsScreen extends StatefulWidget {
  final String title;
  final String posterUrl;
  final String releaseDate;
  final String overview;
  final double? rating;

  MovieDetailsScreen({
    required this.title,
    required this.posterUrl,
    required this.releaseDate,
    required this.overview,
    required this.rating,
  });

  @override
  _MovieDetailsScreenState createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  bool isWatchlistAdded = false;
  bool isSeen = false;
  bool isLiked = false;
  bool isDisliked = false;
  int likes = Random().nextInt(100); // Random initial likes count
  int dislikes = Random().nextInt(50); // Random initial dislikes count
  int duration =
      90 + Random().nextInt(90); // Random duration between 90 and 180 minutes
  int userRating = 0; // User's rating

  void onStarTap(int rating) {
    setState(() {
      userRating = rating;
    });
  }

  String getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Bad!';
      case 2:
        return 'Fair!';
      case 3:
        return 'Good!';
      case 4:
        return 'Very Good!';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      widget.posterUrl,
                      width: 150,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 35),
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PG-13',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '$duration mins',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Rating: ',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.rating != null
                                  ? widget.rating!.toStringAsFixed(1)
                                  : 'N/A',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(width: 8),
                            if (widget.rating != null)
                              Icon(Icons.star, color: Colors.amber)
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.releaseDate,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          isWatchlistAdded
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: isWatchlistAdded ? Colors.amber : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            isWatchlistAdded = !isWatchlistAdded;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(isWatchlistAdded
                                    ? 'Added to watchlist'
                                    : 'Removed from watchlist')),
                          );
                        },
                      ),
                      Text(
                        'Watchlist',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          isSeen ? Icons.visibility : Icons.visibility_off,
                          color: isSeen ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            isSeen = !isSeen;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(isSeen
                                    ? 'Marked as seen'
                                    : 'Marked as not seen')),
                          );
                        },
                      ),
                      Text(
                        'Seen',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked
                              ? Icons.thumb_up
                              : Icons.thumb_up_alt_outlined,
                          color: isLiked ? Colors.green : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isDisliked) {
                              isDisliked = false;
                              dislikes--;
                            }
                            isLiked = !isLiked;
                            if (isLiked) {
                              likes++;
                            } else {
                              likes--;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(isLiked ? 'Liked' : 'Unliked')),
                          );
                        },
                      ),
                      Text(
                        'Like ($likes)',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          isDisliked
                              ? Icons.thumb_down
                              : Icons.thumb_down_alt_outlined,
                          color: isDisliked ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isLiked) {
                              isLiked = false;
                              likes--;
                            }
                            isDisliked = !isDisliked;
                            if (isDisliked) {
                              dislikes++;
                            } else {
                              dislikes--;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    isDisliked ? 'Disliked' : 'Undisliked')),
                          );
                        },
                      ),
                      Text(
                        'Dislike ($dislikes)',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 32),
              DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: 'About'),
                        Tab(text: 'Comments'),
                        Tab(text: 'Review'),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 300,
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  widget.overview,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Center(child: Text('Comments')),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Rate the movie:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return IconButton(
                                    icon: Icon(
                                      index < userRating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: index < userRating
                                          ? Colors.amber
                                          : Colors.grey,
                                    ),
                                    onPressed: () => onStarTap(index + 1),
                                  );
                                }),
                              ),
                              SizedBox(height: 8),
                              Text(
                                getRatingText(userRating),
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MovieSearchDelegate extends SearchDelegate {
  final List<String> selectedGenres;
  final DateTime? selectedReleaseDate;
  final String? selectedLanguage;
  final double? selectedRating;
  List<Map<String, dynamic>> movies = [];
  bool isCsvLoaded = false;

  MovieSearchDelegate({
    required this.selectedGenres,
    required this.selectedReleaseDate,
    required this.selectedLanguage,
    required this.selectedRating,
  }) {
    _loadCSV();
  }

  Future<void> _loadCSV() async {
    final csvData = await rootBundle.loadString('assets/movies.csv');
    List<List<dynamic>> csvTable = CsvToListConverter().convert(csvData);

    movies = csvTable.skip(1).map<Map<String, dynamic>>((row) {
      try {
        return {
          'title': row[2].toString(),
          'genres': row[3].toString().split(','),
          'release_date': row[4].toString(),
          'language': row[5].toString(),
          'rating': double.tryParse(row[6].toString()),
          'overview': row[7].toString(),
          'poster_url': row[10].toString(),
        };
      } catch (e) {
        return {};
      }
    }).toList();

    isCsvLoaded = true;
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (!isCsvLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredMovies = fetchSearchResults(query);

    return filteredMovies.isEmpty
        ? const Center(child: Text('No results found'))
        : ListView.builder(
            itemCount: filteredMovies.length,
            itemBuilder: (context, index) {
              final movie = filteredMovies[index];
              final title = movie['title'];
              final rating = movie['rating'];

              return ListTile(
                title: Text(title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsScreen(
                        title: title,
                        posterUrl: movie['poster_url'],
                        releaseDate: movie['release_date'],
                        overview: movie['overview'],
                        rating: rating,
                      ),
                    ),
                  );
                },
              );
            },
          );
  }

  List<Map<String, dynamic>> fetchSearchResults(String query) {
    return movies.where((movie) {
      return movie['title']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();
  }
}
