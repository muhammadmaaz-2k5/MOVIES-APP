// Shared filter data used by SearchScreen and FilterSheet

class SearchFilters {
  final String genre;
  final String country;
  final String year;
  final String language;
  final String sortBy;

  const SearchFilters({
    this.genre = 'All',
    this.country = 'All',
    this.year = 'All',
    this.language = 'All',
    this.sortBy = 'Hottest',
  });

  bool get isDefault =>
      genre == 'All' &&
      country == 'All' &&
      year == 'All' &&
      language == 'All' &&
      sortBy == 'Hottest';

  int get activeCount {
    int c = 0;
    if (genre != 'All') c++;
    if (country != 'All') c++;
    if (year != 'All') c++;
    if (language != 'All') c++;
    if (sortBy != 'Hottest') c++;
    return c;
  }

  SearchFilters copyWith({
    String? genre,
    String? country,
    String? year,
    String? language,
    String? sortBy,
  }) =>
      SearchFilters(
        genre: genre ?? this.genre,
        country: country ?? this.country,
        year: year ?? this.year,
        language: language ?? this.language,
        sortBy: sortBy ?? this.sortBy,
      );

  static const List<String> genres = [
    'All', 'Action', 'Adventure', 'Animation', 'Biography', 'Comedy',
    'Crime', 'Documentary', 'Drama', 'Family', 'Fantasy', 'Film-Noir',
    'Game-Show', 'History', 'Horror', 'Music', 'Musical', 'Mystery',
    'News', 'Reality-TV', 'Romance', 'Sci-Fi', 'Short', 'Sport',
    'Talk-Show', 'Thriller', 'War', 'Western', 'Other',
  ];

  static const List<String> countries = [
    'All', 'United States', 'United Kingdom', 'Korea', 'Japan',
    'Bangladesh', 'China', 'Egypt', 'France', 'Germany', 'India',
    'Indonesia', 'Iraq', 'Italy', 'Ivory Coast', 'Kenya', 'Lebanon',
    'Mexico', 'Morocco', 'Nigeria', 'Pakistan', 'Philippines', 'Russia',
    'Saudi Arabia', 'South Africa', 'Spain', 'Syria', 'Thailand',
    'Malaysia', 'Turkey', 'Other',
  ];

  static const List<String> years = [
    'All', '2026', '2025', '2024', '2023', '2022', '2021', '2020',
    '2010s', '2000s', '1990s', '1980s', 'Other',
  ];

  static const List<String> languages = [
    'All', 'English dub', 'French dub', 'Hindi dub', 'Bengali dub',
    'Urdu dub', 'Punjabi dub', 'Tamil dub', 'Telugu dub', 'Malayalam dub',
    'Kannada dub', 'Arabic dub', 'Arabic sub', 'Tagalog dub',
    'Indonesian dub', 'Russian dub', 'Kurdish sub', 'Spanish dub',
    'Spanish sub', 'Spanish Latam dub',
  ];

  static const List<String> sortOptions = [
    'Hottest', 'Latest', 'Rating',
  ];

  // TMDB genre ID map
  static const Map<String, int> genreIds = {
    'Action': 28, 'Adventure': 12, 'Animation': 16, 'Comedy': 35,
    'Crime': 80, 'Documentary': 99, 'Drama': 18, 'Family': 10751,
    'Fantasy': 14, 'History': 36, 'Horror': 27, 'Music': 10402,
    'Mystery': 9648, 'Romance': 10749, 'Sci-Fi': 878, 'Thriller': 53,
    'War': 10752, 'Western': 37,
  };

  // TMDB country code map
  static const Map<String, String> countryCodes = {
    'United States': 'US', 'United Kingdom': 'GB', 'Korea': 'KR',
    'Japan': 'JP', 'Bangladesh': 'BD', 'China': 'CN', 'Egypt': 'EG',
    'France': 'FR', 'Germany': 'DE', 'India': 'IN', 'Indonesia': 'ID',
    'Iraq': 'IQ', 'Italy': 'IT', 'Ivory Coast': 'CI', 'Kenya': 'KE',
    'Lebanon': 'LB', 'Mexico': 'MX', 'Morocco': 'MA', 'Nigeria': 'NG',
    'Pakistan': 'PK', 'Philippines': 'PH', 'Russia': 'RU',
    'Saudi Arabia': 'SA', 'South Africa': 'ZA', 'Spain': 'ES',
    'Syria': 'SY', 'Thailand': 'TH', 'Malaysia': 'MY', 'Turkey': 'TR',
  };

  // TMDB language code map (original_language)
  static const Map<String, String> languageCodes = {
    'English dub': 'en', 'French dub': 'fr', 'Hindi dub': 'hi',
    'Bengali dub': 'bn', 'Urdu dub': 'ur', 'Punjabi dub': 'pa',
    'Tamil dub': 'ta', 'Telugu dub': 'te', 'Malayalam dub': 'ml',
    'Kannada dub': 'kn', 'Arabic dub': 'ar', 'Arabic sub': 'ar',
    'Tagalog dub': 'tl', 'Indonesian dub': 'id', 'Russian dub': 'ru',
    'Kurdish sub': 'ku', 'Spanish dub': 'es', 'Spanish sub': 'es',
    'Spanish Latam dub': 'es',
  };
}
