
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tflite_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'firebase_guard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:fl_chart/fl_chart.dart'; // For Charts
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For dark mode & favorites
import 'package:csv/csv.dart'; // For CSV export
import 'package:pdf/pdf.dart'; // For PDF
import 'package:pdf/widgets.dart' as pw; // For PDF widgets
import 'package:share_plus/share_plus.dart'; // For sharing
import 'package:path_provider/path_provider.dart'; // For file paths
import 'new_features.dart'; // NEW FEATURES
import 'onboarding_screen.dart'; // Onboarding flow
import 'collection_manager.dart'; // Collection management
import 'collection_screen.dart'; // Collection UI
import 'recipe_data.dart'; // Recipe database
import 'recipe_screen.dart'; // Recipe UI

// --- Premium Color Palette ---
// Light Mode Colors
const Color oxbloodPrimary = Color(0xFF800020);      // Primary brand color
const Color sandBackground = Color(0xFFC2B280);      // Main background
const Color onyxBlack = Color(0xFF353839);           // Text, icons
const Color beigeSurface = Color(0xFFF5F5DC);        // Cards, surfaces
const Color ivoryHighlight = Color(0xFFFFFFF0);      // Highlights, elevated surfaces
const Color accentBrown = Color(0xFF442b1b);         // Buttons, CTAs, accents
const Color sandLight = Color(0xFFD4C9A8);           // Lighter sand variant

// Dark Mode Colors
const Color darkOxblood = Color(0xFF4A0012);         // Primary in dark mode
const Color darkSand = Color(0xFF3A3526);            // Dark background
const Color lightBeige = Color(0xFFE8E4D0);          // Text on dark
const Color darkSurface = Color(0xFF2D2A22);         // Cards in dark mode
const Color accentBrownDark = Color(0xFF6B4423);     // Lighter brown for dark mode
const Color darkOnyx = Color(0xFF1a1a1b);            // Deep dark for backgrounds

// Additional color aliases for backward compatibility
const Color beigePrimary = beigeSurface;
const Color beigeDark = accentBrown;
const Color beigeAccent = accentBrown;
const Color beigeText = onyxBlack;
const Color beigeBackground = sandBackground;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Prevent duplicate Firebase initialization
  try {
    if (shouldInitializeFirebase(Firebase.apps)) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // If Firebase is already initialized, we can safely ignore this error
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialized, continuing...');
    } else {
      // Re-throw other errors
      rethrow;
    }
  }
  
  runApp(const MyApp());
}

// --- Theme Provider for Dark Mode ---
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: oxbloodPrimary,
    scaffoldBackgroundColor: beigeSurface, // Changed from sandBackground to beige
    colorScheme: const ColorScheme.light(
      primary: oxbloodPrimary,
      secondary: accentBrown,
      background: beigeSurface, // Changed to beige
      onBackground: onyxBlack,
      surface: beigeSurface,
      onSurface: onyxBlack,
      tertiary: ivoryHighlight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: sandBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: accentBrown),
      titleTextStyle: TextStyle(
        color: onyxBlack,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    iconTheme: const IconThemeData(color: accentBrown),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: onyxBlack, fontSize: 16),
      bodyMedium: TextStyle(color: onyxBlack, fontSize: 14),
      headlineSmall: TextStyle(
        color: onyxBlack,
        fontWeight: FontWeight.bold,
        fontSize: 24,
        letterSpacing: 0.5,
      ),
      titleMedium: TextStyle(
        color: onyxBlack,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    ),
    cardTheme: CardThemeData(
      color: beigeSurface,
      elevation: 3,
      shadowColor: onyxBlack.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: oxbloodPrimary,
        foregroundColor: ivoryHighlight,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkOxblood,
    scaffoldBackgroundColor: darkSand,
    colorScheme: const ColorScheme.dark(
      primary: darkOxblood,
      secondary: accentBrownDark,
      background: darkSand,
      onBackground: lightBeige,
      surface: darkSurface,
      onSurface: lightBeige,
      tertiary: darkOnyx,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSand,
      elevation: 0,
      iconTheme: IconThemeData(color: accentBrownDark),
      titleTextStyle: TextStyle(
        color: lightBeige,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    iconTheme: const IconThemeData(color: accentBrownDark),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: lightBeige, fontSize: 16),
      bodyMedium: TextStyle(color: lightBeige, fontSize: 14),
      headlineSmall: TextStyle(
        color: lightBeige,
        fontWeight: FontWeight.bold,
        fontSize: 24,
        letterSpacing: 0.5,
      ),
      titleMedium: TextStyle(
        color: lightBeige,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkOxblood,
        foregroundColor: lightBeige,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

// --- Favorites Manager (Local Storage) ---
class FavoritesManager {
  static const String _favoritesKey = 'favorites';

  static Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favoritesList = prefs.getStringList(_favoritesKey);
    return favoritesList?.toSet() ?? {};
  }

  static Future<void> addFavorite(String productName) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.add(productName);
    await prefs.setStringList(_favoritesKey, favorites.toList());
  }

  static Future<void> removeFavorite(String productName) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.remove(productName);
    await prefs.setStringList(_favoritesKey, favorites.toList());
  }

  static Future<bool> isFavorite(String productName) async {
    final favorites = await getFavorites();
    return favorites.contains(productName);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  bool _hasSeenOnboarding = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kitchen Utensils Scanner',
          theme: _themeProvider.lightTheme,
          darkTheme: _themeProvider.darkTheme,
          themeMode: _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: _isLoading
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : _hasSeenOnboarding
                  ? MainScreen(themeProvider: _themeProvider)
                  : const OnboardingScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final ThemeProvider? themeProvider;
  const MainScreen({super.key, this.themeProvider});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryPage(),
    const ScanPage(),
    const StatisticsPage(), // Statistics tab
    const CollectionScreen(), // Collection tab
    const RecipeScreen(), // Recipe tab
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Utensils Scanner'),
        actions: [
          // NEW: Dark mode toggle button
          if (widget.themeProvider != null)
            IconButton(
              icon: Icon(
                widget.themeProvider!.isDarkMode 
                    ? Icons.light_mode 
                    : Icons.dark_mode,
              ),
              onPressed: () {
                widget.themeProvider!.toggleTheme();
              },
              tooltip: 'Toggle Dark Mode',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: TopNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}

class TopNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const TopNavBar({required this.currentIndex, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced from 24 to 12
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Reduced from 8 to 4
      decoration: BoxDecoration(
        color: isDark ? darkSurface : ivoryHighlight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : onyxBlack).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_rounded, 'Home', 0),
            _buildNavItem(context, Icons.history_rounded, 'History', 1),
            _buildNavItem(context, Icons.qr_code_scanner_rounded, 'Scan', 2),
            _buildNavItem(context, Icons.bar_chart_rounded, 'Stats', 3),
            _buildNavItem(context, Icons.collections_bookmark_rounded, 'Collection', 4),
            _buildNavItem(context, Icons.restaurant_menu_rounded, 'Recipes', 5),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced from 20 to 12
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? darkOxblood : oxbloodPrimary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? (isDark ? lightBeige : ivoryHighlight)
                  : (isDark ? accentBrownDark : accentBrown),
              size: 22,
            ),
            if (isSelected) const SizedBox(width: 8),
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  color: isDark ? lightBeige : ivoryHighlight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Home Section ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Product data with images, names, and descriptions
  final List<Map<String, String>> products = const [
    {
      'image': 'assets/Rolling Pin.jpg',
      'name': 'Rolling Pin',
      'description': 'Essential for flattening dough for pastries and baking',
    },
    {
      'image': 'assets/Whisk.jpg',
      'name': 'Whisk',
      'description': 'Perfect for blending ingredients smooth and incorporating air',
    },
    {
      'image': 'assets/Tongs.jpg',
      'name': 'Tongs',
      'description': 'Great for gripping and lifting hot food safely',
    },
    {
      'image': 'assets/Ladle.jpg',
      'name': 'Ladle',
      'description': 'Ideal for serving soups, stews, and sauces',
    },
    {
      'image': 'assets/Peeler.jpg',
      'name': 'Peeler',
      'description': 'Removes skin from vegetables and fruits with ease',
    },
    {
      'image': 'assets/Grater.jpg',
      'name': 'Grater',
      'description': 'Shreds cheese, vegetables, and zest quickly',
    },
    {
      'image': 'assets/Colander.jpg',
      'name': 'Colander',
      'description': 'Drains pasta and washes vegetables efficiently',
    },
    {
      'image': 'assets/Spatula.jpg',
      'name': 'Spatula',
      'description': 'Versatile tool for mixing, scraping, and flipping',
    },
    {
      'image': 'assets/Kitchen Scissors.jpg',
      'name': 'Kitchen Scissors',
      'description': 'Multi-purpose shears for cutting herbs and packaging',
    },
    {
      'image': 'assets/Slotted Spoon.jpg',
      'name': 'Slotted Spoon',
      'description': 'Retrieves solid food from liquids while draining',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Text(
            "Kitchen Utensils Gallery",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Explore our kitchen utensils collection",
            style: TextStyle(
              fontSize: 16,
              color: accentBrown.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          
          // Grid Layout - 2 columns, 5 rows
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Adjust card height
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(
                context,
                products[index]['image']!,
                products[index]['name']!,
                products[index]['description']!,
                index,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    String imagePath,
    String name,
    String description,
    int index,
  ) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: ivoryHighlight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: onyxBlack.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          name: name,
                          imagePath: imagePath,
                          description: description,
                        ),
                      ),
                    );
                  },
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Image
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                       child: Container(
                         color: sandLight.withOpacity(0.4),
                         child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Product Info
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Text(
                             name,
                             style: const TextStyle(
                               fontWeight: FontWeight.bold,
                               fontSize: 14,
                               color: onyxBlack,
                             ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                           Text(
                             description,
                             style: TextStyle(
                               fontSize: 10,
                               color: accentBrown.withOpacity(0.75),
                               height: 1.3,
                             ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }
}


// --- Scan Section ---
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String _status = 'Initializing...';
  final TFLiteHelper _tfliteHelper = TFLiteHelper();
  bool _isModelLoaded = false;
  AnimationController? _animationController;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController?.dispose();
    _tfliteHelper.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _status = 'Initializing Camera...';
    });
    await _initializeCamera();
    if (mounted && _isInitialized) {
      _loadModel();
    }
  }

  Future<void> _loadModel() async {
    setState(() {
      _status = 'Loading Model...';
    });
    try {
      await _tfliteHelper.loadModel();
      if (mounted) {
        setState(() {
          _isModelLoaded = true;
          _status = 'Tap to Scan';
        });
      }
    } catch (e, s) {
      if (mounted) setState(() => _status = 'Error loading model: $e');
      print('Error loading model: $e\n$s');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        if (mounted) setState(() => _status = 'Camera permission denied');
        return;
      }
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) setState(() => _status = 'No cameras found');
        return;
      }
      _cameraController = CameraController(_cameras![0], ResolutionPreset.high, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _status = 'Camera error: $e');
    }
  }

  // In _ScanPageState

  Future<void> _savePrediction(List<Map<String, dynamic>> predictions, String imagePath) async {
    if (predictions.isEmpty) { return; }

    final topPrediction = predictions[0];
    final double topConfidence = topPrediction['confidence'];

    // --- REMOVED STRICT THRESHOLD CHECKS FOR SAVING ---
    // User wants ALL scans to be visible in the logs.
    
    HapticFeedback.heavyImpact();

    try {
      // Write to Firestore for storage and syncing
      final firestoreRecord = {
        'ClassType': topPrediction['label'],
        'Accuracy_Rate': (topConfidence * 100),
        'Time': DateTime.now().toIso8601String(), // Store as string for consistency or Timestamp
        'Timestamp': FieldValue.serverTimestamp(),
        'ImagePath': imagePath,
      };

      await FirebaseFirestore.instance.collection('Mojado_KitchenUtensils_Logs').add(firestoreRecord);

      print("SUCCESS: Prediction saved to Firestore.");
    } catch (e) {
      print("Error saving to Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save result: $e')));
      }
    }
  }


  // In _ScanPageState

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _status = 'Processing image...';
    });

    final imageFile = File(imagePath);
    final predictions = _tfliteHelper.predictImage(imageFile);

    if (predictions != null && predictions.isNotEmpty) {
      // FIX IS HERE: Pass the imagePath to the save function
      await _savePrediction(predictions, imagePath);
    }

    if (mounted && predictions != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            imagePath: imagePath,
            predictions: predictions,
          ),
        ),
      );
      // Reset status after returning from results
      setState(() {
        _status = '';
      });
    }
  }


  Future<void> _takePicture() async {
    if (!_isInitialized || !_isModelLoaded) return;
    _animationController?.forward().then((_) => _animationController?.reverse());
    try {
      final XFile image = await _cameraController!.takePicture();
      _processImage(image.path);
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (!_isModelLoaded) return;
    _animationController?.forward().then((_) => _animationController?.reverse());
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      _processImage(image.path);
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canScan = _isInitialized && _isModelLoaded;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _isInitialized
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraController!),
                        if (!_isModelLoaded)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(color: Colors.white),
                                  const SizedBox(height: 10),
                                  Text(_status, style: const TextStyle(color: Colors.white, fontSize: 16))
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                            onPressed: () {
                              if (_cameraController != null && _cameraController!.value.isInitialized) {
                                setState(() => _isFlashOn = !_isFlashOn);
                                _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
                              }
                            },
                          ),
                        )
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [const CircularProgressIndicator(color: beigeAccent), const SizedBox(height: 16), Text(_status)],
                      ),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 72),
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 0.9).animate(_animationController!),
                    child: GestureDetector(
                      onTap: canScan ? _takePicture : null,
                      child: Opacity(
                        opacity: canScan ? 1.0 : 0.4,
                        child: Container(
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: beigeDark, width: 3)),
                          child: Center(child: Container(height: 60, width: 60, decoration: const BoxDecoration(shape: BoxShape.circle, color: beigePrimary))),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: IconButton(
                      onPressed: canScan ? _pickImageFromGallery : null,
                      icon: Icon(Icons.photo_library_outlined, color: canScan ? beigeAccent : beigeDark, size: 36),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(canScan ? "Tap to Scan" : _status, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

// --- History Section ---
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _searchQuery = '';

  // Helper function to get product image from assets based on ClassType
  String _getProductImageFromAssets(String classType) {
    final lowerCaseLabel = classType.toLowerCase();
    if (lowerCaseLabel.contains('rolling pin')) return 'assets/Rolling Pin.jpg';
    if (lowerCaseLabel.contains('whisk')) return 'assets/Whisk.jpg';
    if (lowerCaseLabel.contains('tongs')) return 'assets/Tongs.jpg';
    if (lowerCaseLabel.contains('ladle')) return 'assets/Ladle.jpg';
    if (lowerCaseLabel.contains('peeler')) return 'assets/Peeler.jpg';
    if (lowerCaseLabel.contains('grater')) return 'assets/Grater.jpg';
    if (lowerCaseLabel.contains('colander')) return 'assets/Colander.jpg';
    if (lowerCaseLabel.contains('spatula')) return 'assets/Spatula.jpg';
    if (lowerCaseLabel.contains('kitchen scissors')) return 'assets/Kitchen Scissors.jpg';
    if (lowerCaseLabel.contains('slotted spoon')) return 'assets/Slotted Spoon.jpg';
    return '';
  }

  // Robust time parser for history list
  DateTime? _parseTime(dynamic timeValue) {
    if (timeValue == null) return null;
    if (timeValue is Timestamp) return timeValue.toDate(); // Handle Firestore Timestamp
    if (timeValue is DateTime) return timeValue;
    if (timeValue is String) {
      try {
        return DateTime.parse(timeValue);
      } catch (_) {
        final ms = int.tryParse(timeValue);
        if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
        return null;
      }
    }
    if (timeValue is num) return DateTime.fromMillisecondsSinceEpoch(timeValue.toInt());
    return null;
  }

  int _getRecordTimestamp(Map<String, dynamic> record) {
    final tsField = record['Timestamp'];
    if (tsField is num) return tsField.toInt();
    final time = _parseTime(record['Time']);
    if (time != null) return time.millisecondsSinceEpoch;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Mojado_KitchenUtensils_Logs')
          .orderBy('Timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: (isDark ? lightBeige : onyxBlack).withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No scan history found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: (isDark ? lightBeige : onyxBlack).withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start scanning kitchen utensils to build your history',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: (isDark ? lightBeige : onyxBlack).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final documents = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

        // Filter documents based on search query
        final filteredDocs = documents.where((data) {
          final classType = (data['ClassType'] ?? '').toString().toLowerCase();
          return classType.contains(_searchQuery.toLowerCase());
        }).toList();

        return Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Scan History",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "View your scanned kitchen utensils",
                    style: TextStyle(
                      fontSize: 16,
                      color: (isDark ? lightBeige : accentBrown).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar and Export Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: TextStyle(
                          color: (isDark ? lightBeige : onyxBlack).withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? accentBrownDark : accentBrown,
                        ),
                        filled: true,
                        fillColor: isDark ? darkSurface : beigeSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Export Button
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? darkOxblood : oxbloodPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.download_rounded,
                        color: isDark ? lightBeige : ivoryHighlight,
                      ),
                      tooltip: 'Export History',
                      color: isDark ? darkSurface : ivoryHighlight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) async {
                        if (value == 'csv') {
                          await ExportUtils.exportToCSV(filteredDocs);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exported as CSV!')),
                            );
                          }
                        } else if (value == 'pdf') {
                          await ExportUtils.exportToPDF(filteredDocs);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exported as PDF!')),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'csv',
                          child: Row(
                            children: [
                              Icon(
                                Icons.table_chart,
                                color: isDark ? accentBrownDark : accentBrown,
                              ),
                              const SizedBox(width: 12),
                              const Text('Export as CSV'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: isDark ? accentBrownDark : accentBrown,
                              ),
                              const SizedBox(width: 12),
                              const Text('Export as PDF'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Results Count
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filteredDocs.length} ${filteredDocs.length == 1 ? "result" : "results"} found',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: (isDark ? accentBrownDark : accentBrown),
                    ),
                  ),
                ),
              ),

            // History List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final data = filteredDocs[index];
                  final time = _parseTime(data['Time']);
                  final classType = data['ClassType'] ?? 'Unknown Class';
                  final accuracy = (data['Accuracy_Rate'] as num?)?.toStringAsFixed(0) ?? '0';
                  final assetImage = _getProductImageFromAssets(classType);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? darkSurface : ivoryHighlight,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ScanDetailScreen(data: data)),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Product Image
                              _buildHistoryImage(isDark, assetImage),
                              
                              const SizedBox(width: 16),
                              
                              // Product Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      classType,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                        color: isDark ? lightBeige : onyxBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: (isDark ? lightBeige : onyxBlack).withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            time != null
                                                ? time.toLocal().toString().split('.')[0]
                                                : 'No date',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: (isDark ? lightBeige : onyxBlack).withOpacity(0.7),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Accuracy Badge and Share
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [darkOxblood, darkOxblood.withOpacity(0.7)]
                                            : [oxbloodPrimary, oxbloodPrimary.withOpacity(0.7)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '$accuracy%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? lightBeige : ivoryHighlight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.share_rounded,
                                      size: 20,
                                      color: isDark ? accentBrownDark : accentBrown,
                                    ),
                                    onPressed: () {
                                      ExportUtils.shareText(
                                        'Scanned: $classType\nAccuracy: $accuracy%\nDate: ${time != null ? time.toLocal() : 'N/A'}',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryImage(bool isDark, String assetImage) {
    if (assetImage.isNotEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : onyxBlack).withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: ClipOval(
          child: Image.asset(
            assetImage,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: (isDark ? darkSurface : beigeSurface),
          shape: BoxShape.circle,
          border: Border.all(
            color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: (isDark ? lightBeige : onyxBlack).withOpacity(0.5),
        ),
      );
    }
  }
}

class ScanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const ScanDetailScreen({super.key, required this.data});

  String _getProductImageFromAssets(String classType) {
    final lowerCaseLabel = classType.toLowerCase();
    if (lowerCaseLabel.contains('rolling pin')) return 'assets/Rolling Pin.jpg';
    if (lowerCaseLabel.contains('whisk')) return 'assets/Whisk.jpg';
    if (lowerCaseLabel.contains('tongs')) return 'assets/Tongs.jpg';
    if (lowerCaseLabel.contains('ladle')) return 'assets/Ladle.jpg';
    if (lowerCaseLabel.contains('peeler')) return 'assets/Peeler.jpg';
    if (lowerCaseLabel.contains('grater')) return 'assets/Grater.jpg';
    if (lowerCaseLabel.contains('colander')) return 'assets/Colander.jpg';
    if (lowerCaseLabel.contains('spatula')) return 'assets/Spatula.jpg';
    if (lowerCaseLabel.contains('kitchen scissors')) return 'assets/Kitchen Scissors.jpg';
    if (lowerCaseLabel.contains('slotted spoon')) return 'assets/Slotted Spoon.jpg';
    return '';
  }

  DateTime? _parseTime(dynamic timeValue) {
    if (timeValue == null) return null;
    if (timeValue is DateTime) return timeValue;
    if (timeValue is String) {
      try {
        return DateTime.parse(timeValue);
      } catch (_) {
        final ms = int.tryParse(timeValue);
        if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
        return null;
      }
    }
    if (timeValue is num) return DateTime.fromMillisecondsSinceEpoch(timeValue.toInt());
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classType = data['ClassType'] as String?;
    final accuracy = data['Accuracy_Rate'] as num?;
    final time = _parseTime(data['Time']);
    final productImage = _getProductImageFromAssets(classType ?? '');

    return Scaffold(
      backgroundColor: isDark ? darkSand : sandBackground,
      appBar: AppBar(
        title: Text(classType ?? 'Scan Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display product image from assets with gradient background
            if (productImage.isNotEmpty)
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [darkOxblood.withOpacity(0.3), darkSurface]
                        : [oxbloodPrimary.withOpacity(0.1), beigeSurface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Image.asset(
                  productImage,
                  fit: BoxFit.contain,
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Product Name Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? darkSurface : ivoryHighlight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : onyxBlack).withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.label_outline,
                        color: isDark ? accentBrownDark : accentBrown,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Identified Product',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: (isDark ? accentBrownDark : accentBrown),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    classType ?? 'N/A',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? lightBeige : onyxBlack,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Stats Row
            Row(
              children: [
                // Confidence Score Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [darkOxblood, darkOxblood.withOpacity(0.7)]
                            : [oxbloodPrimary, oxbloodPrimary.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: isDark ? lightBeige : ivoryHighlight,
                          size: 24,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Confidence',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (isDark ? lightBeige : ivoryHighlight).withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${accuracy?.toStringAsFixed(1) ?? '0'}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? lightBeige : ivoryHighlight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Scan Date Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? darkSurface : ivoryHighlight,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : onyxBlack).withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: isDark ? accentBrownDark : accentBrown,
                          size: 24,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scanned',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (isDark ? accentBrownDark : accentBrown),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time != null
                              ? '${time.day}/${time.month}/${time.year}'
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? lightBeige : onyxBlack,
                          ),
                        ),
                        if (time != null)
                          Text(
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: (isDark ? lightBeige : onyxBlack).withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// --- Results Screen and Widgets ---
class ResultsScreen extends StatelessWidget {
  final String imagePath;
  final List<Map<String, dynamic>> predictions;

  const ResultsScreen({super.key, required this.imagePath, required this.predictions});

  Color _getProductColor(String label) {
    final lowerCaseLabel = label.toLowerCase();
    if (lowerCaseLabel.contains('rolling pin')) return Colors.brown;
    if (lowerCaseLabel.contains('whisk')) return Colors.grey;
    if (lowerCaseLabel.contains('tongs')) return Colors.grey;
    if (lowerCaseLabel.contains('ladle')) return Colors.grey;
    if (lowerCaseLabel.contains('peeler')) return Colors.green;
    if (lowerCaseLabel.contains('grater')) return Colors.grey;
    if (lowerCaseLabel.contains('colander')) return Colors.redAccent;
    if (lowerCaseLabel.contains('spatula')) return Colors.black;
    if (lowerCaseLabel.contains('kitchen scissors')) return Colors.blue;
    if (lowerCaseLabel.contains('slotted spoon')) return Colors.grey;
    return beigeDark;
  }

  String _getProductDescription(String label) {
    final lowerCaseLabel = label.toLowerCase();
    if (lowerCaseLabel.contains('rolling pin')) return 'Essential for flattening dough for pastries and baking';
    if (lowerCaseLabel.contains('whisk')) return 'Perfect for blending ingredients smooth and incorporating air';
    if (lowerCaseLabel.contains('tongs')) return 'Great for gripping and lifting hot food safely';
    if (lowerCaseLabel.contains('ladle')) return 'Ideal for serving soups, stews, and sauces';
    if (lowerCaseLabel.contains('peeler')) return 'Removes skin from vegetables and fruits with ease';
    if (lowerCaseLabel.contains('grater')) return 'Shreds cheese, vegetables, and zest quickly';
    if (lowerCaseLabel.contains('colander')) return 'Drains pasta and washes vegetables efficiently';
    if (lowerCaseLabel.contains('spatula')) return 'Versatile tool for mixing, scraping, and flipping';
    if (lowerCaseLabel.contains('kitchen scissors')) return 'Multi-purpose shears for cutting herbs and packaging';
    if (lowerCaseLabel.contains('slotted spoon')) return 'Retrieves solid food from liquids while draining';
    return 'No description available.';
  }

  String _getProductImageFromAssets(String label) {
    final lowerCaseLabel = label.toLowerCase();
    if (lowerCaseLabel.contains('rolling pin')) return 'assets/Rolling Pin.jpg';
    if (lowerCaseLabel.contains('whisk')) return 'assets/Whisk.jpg';
    if (lowerCaseLabel.contains('tongs')) return 'assets/Tongs.jpg';
    if (lowerCaseLabel.contains('ladle')) return 'assets/Ladle.jpg';
    if (lowerCaseLabel.contains('peeler')) return 'assets/Peeler.jpg';
    if (lowerCaseLabel.contains('grater')) return 'assets/Grater.jpg';
    if (lowerCaseLabel.contains('colander')) return 'assets/Colander.jpg';
    if (lowerCaseLabel.contains('spatula')) return 'assets/Spatula.jpg';
    if (lowerCaseLabel.contains('kitchen scissors')) return 'assets/Kitchen Scissors.jpg';
    if (lowerCaseLabel.contains('slotted spoon')) return 'assets/Slotted Spoon.jpg';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.lightImpact();

    final topPrediction = predictions.isNotEmpty ? predictions[0] : null;
    final top5Predictions = predictions.take(5).toList();
    final String topLabel = topPrediction?['label'] ?? '';
    final String productImage = _getProductImageFromAssets(topLabel);

    return Scaffold(
      backgroundColor: isDark ? darkSand : sandBackground,
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? darkSand : sandBackground,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Scanned Image
                  Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Confidence Badge
                  if (topPrediction != null)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [darkOxblood, darkOxblood.withOpacity(0.8)]
                                : [oxbloodPrimary, oxbloodPrimary.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: isDark ? lightBeige : ivoryHighlight,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(topPrediction['confidence'] * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isDark ? lightBeige : ivoryHighlight,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Prediction Card - Enhanced
                  if (topPrediction != null) 
                    _buildEnhancedTopPredictionCard(
                      context,
                      topPrediction, 
                      productImage,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Confidence Chart
                  if (top5Predictions.isNotEmpty) 
                    _buildBarChart(context, top5Predictions),
                  
                  const SizedBox(height: 24),
                  
                  // All Predictions Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? darkSurface : ivoryHighlight,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              color: isDark ? accentBrownDark : accentBrown,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'All Predictions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? lightBeige : onyxBlack,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildEnhancedConfidenceList(context, predictions),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTopPredictionCard(
    BuildContext context,
    Map<String, dynamic> topPrediction,
    String productImage,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double confidence = topPrediction['confidence'];
    final String label = topPrediction['label'];
    final String description = _getProductDescription(label);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              name: label,
              imagePath: productImage,
              description: description,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? darkSurface : ivoryHighlight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      child: Column(
        children: [
          // Header with Product Image
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [darkOxblood.withOpacity(0.2), darkOxblood.withOpacity(0.05)]
                    : [oxbloodPrimary.withOpacity(0.1), oxbloodPrimary.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                // Product Image
                if (productImage.isNotEmpty)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      productImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(width: 20),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [darkOxblood, darkOxblood.withOpacity(0.8)]
                                : [oxbloodPrimary, oxbloodPrimary.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '✓ Identified',
                          style: TextStyle(
                            color: isDark ? lightBeige : ivoryHighlight,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? lightBeige : onyxBlack,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Description
          if (true) // Always show description
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: isDark ? accentBrownDark : accentBrown,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Product Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? lightBeige : onyxBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: (isDark ? lightBeige : onyxBlack).withOpacity(0.8),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildEnhancedConfidenceList(BuildContext context, List<Map<String, dynamic>> predictions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: predictions.asMap().entries.map((entry) {
        final int index = entry.key;
        final prediction = entry.value;
        final String label = prediction['label'];
        final double confidence = prediction['confidence'];
        final String productImage = _getProductImageFromAssets(label);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  name: label,
                  imagePath: productImage,
                  description: _getProductDescription(label),
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: index == 0
                        ? LinearGradient(
                            colors: isDark
                                ? [darkOxblood, darkOxblood.withOpacity(0.8)]
                                : [oxbloodPrimary, oxbloodPrimary.withOpacity(0.8)],
                          )
                        : null,
                    color: index == 0
                        ? null
                        : (isDark ? accentBrownDark : accentBrown),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isDark ? lightBeige : ivoryHighlight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Product Image Thumbnail
                if (productImage.isNotEmpty)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      productImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(width: 12),
                
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? lightBeige : onyxBlack,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Confidence with Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isDark ? accentBrownDark : accentBrown,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isDark ? lightBeige : beigeSurface).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: confidence,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [darkOxblood, darkOxblood.withOpacity(0.7)]
                                  : [oxbloodPrimary, oxbloodPrimary.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopPredictionCard(Map<String, dynamic> topPrediction, bool isConfident) {
    final double confidence = topPrediction['confidence'];
    final String label = topPrediction['label'];
    final Color productColor = _getProductColor(label);
    final String description = _getProductDescription(label);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isConfident ? productColor.withOpacity(0.7) : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isConfident ? productColor : Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConfident ? 'Top Match' : 'Not Identified',
                    style: TextStyle(
                      color: (isConfident ? productColor : Colors.orangeAccent).computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isConfident ? label : 'Confidence is too low',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isConfident) const SizedBox(height: 12),
                if (isConfident)
                  Container(
                    padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                      border: Border.all(color: productColor.withOpacity(0.5)),
                       borderRadius: BorderRadius.circular(12),
                       color: productColor.withOpacity(0.05),
                     ),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: beigeText.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: ConfidenceRingPainter(
                confidence: confidence,
                backgroundColor: beigePrimary,
                foregroundColor: isConfident ? productColor : Colors.orangeAccent,
              ),
              child: Center(
                child: Text('${(confidence * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceList(List<Map<String, dynamic>> predictions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: predictions.asMap().entries.map((entry) {
          final int index = entry.key;
          final prediction = entry.value;
          final String label = prediction['label'];
          final double confidence = prediction['confidence'];
          final Color productColor = _getProductColor(label);
          final String description = _getProductDescription(label);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: index != predictions.length -1 ? Border(bottom: BorderSide(color: beigePrimary)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: productColor, shape: BoxShape.circle)),
                      const SizedBox(width: 16),
                      Expanded(child: Text(label, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 16),
                      Text('${(confidence * 100).toStringAsFixed(1)}%', style: TextStyle(color: beigeText.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: productColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: productColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      description,
                      style: TextStyle(
                        color: beigeText.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(List<Map<String, dynamic>> predictions, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: predictions.map((pred) {
          final label = pred['label'] as String;
          final color = _getProductColor(label);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<Map<String, dynamic>> topPredictions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? darkSurface : ivoryHighlight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: isDark ? accentBrownDark : accentBrown,
              ),
              const SizedBox(width: 12),
              Text(
                'Top 5 Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? lightBeige : onyxBlack,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? darkOxblood : oxbloodPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final pred = topPredictions[group.x.toInt()];
                      final label = pred['label'];
                      final confidence = (rod.toY * 100).toStringAsFixed(1);
                      return BarTooltipItem(
                        '$label\n$confidence%',
                        TextStyle(
                          color: isDark ? lightBeige : ivoryHighlight,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 0.25,
                      getTitlesWidget: (value, meta) {
                        if (value % 0.25 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 12, color: beigeText.withOpacity(0.6))),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (value) => FlLine(color: beigePrimary, strokeWidth: 1),
                ),
                barGroups: topPredictions.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['confidence'],
                        gradient: LinearGradient(
                          colors: isDark
                              ? [darkOxblood.withOpacity(0.7), darkOxblood]
                              : [oxbloodPrimary.withOpacity(0.7), oxbloodPrimary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          _buildLegend(topPredictions, context),
        ],
      ),
    );
  }
}

class ConfidenceRingPainter extends CustomPainter {
  final double confidence;
  final Color backgroundColor;
  final Color foregroundColor;
  ConfidenceRingPainter({required this.confidence, required this.backgroundColor, required this.foregroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 12.0;
    final backgroundPaint = Paint()..color = backgroundColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);
    final foregroundPaint = Paint()..color = foregroundColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * confidence;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




class ProductDetailScreen extends StatefulWidget {
  final String name;
  final String imagePath;
  final String description;

  const ProductDetailScreen({
    super.key,
    required this.name,
    required this.imagePath,
    required this.description,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isInCollection = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCollectionStatus();
  }

  Future<void> _checkCollectionStatus() async {
    final inCollection = await CollectionManager.isInCollection(widget.name);
    setState(() {
      _isInCollection = inCollection;
      _isLoading = false;
    });
  }

  Future<void> _toggleCollection() async {
    final newStatus = await CollectionManager.toggleInCollection(widget.name);
    setState(() {
      _isInCollection = newStatus;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus 
                ? '✓ Added ${widget.name} to collection' 
                : '✗ Removed ${widget.name} from collection',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _toggleCollection,
              backgroundColor: _isInCollection
                  ? (isDark ? accentBrownDark : accentBrown)
                  : (isDark ? darkOxblood : oxbloodPrimary),
              icon: Icon(
                _isInCollection ? Icons.check_circle : Icons.add_circle_outline,
                color: isDark ? lightBeige : ivoryHighlight,
              ),
              label: Text(
                _isInCollection ? 'In Collection' : 'Add to Collection',
                style: TextStyle(
                  color: isDark ? lightBeige : ivoryHighlight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: 350,
                color: beigePrimary.withOpacity(0.3),
                padding: const EdgeInsets.all(30),
                child: Hero(
                  tag: widget.name, // Unique tag for hero animation
                  child: Image.asset(
                    widget.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Product Name
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: beigeText,
              ),
            ),
            const SizedBox(height: 16),
            
            // Collection Status Badge
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isInCollection
                      ? (isDark ? darkOxblood : oxbloodPrimary).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isInCollection
                        ? (isDark ? darkOxblood : oxbloodPrimary)
                        : Colors.grey,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isInCollection ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: _isInCollection
                          ? (isDark ? accentBrownDark : accentBrown)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isInCollection ? 'In Your Collection' : 'Not In Collection',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isInCollection
                            ? (isDark ? accentBrownDark : accentBrown)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            // Description Header
            Row(
              children: [
                Icon(Icons.info_outline, color: beigeAccent),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: beigeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description Text
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: beigeDark.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: beigeText,
                ),
              ),
            ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }
}
