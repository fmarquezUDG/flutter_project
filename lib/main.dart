// ----------- IMPORTS & CONSTANTS -----------
// Importa las librerías necesarias y define los rangos de generaciones de Pokémon con sus respectivas regiones

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:math';

const Map<int, List<int>> generationRanges = {
  1: [1, 151],      // Kanto
  2: [152, 251],    // Johto
  3: [252, 386],    // Hoenn
  4: [387, 493],    // Sinnoh
  5: [494, 649],    // Unova
  6: [650, 721],    // Kalos
  7: [722, 809],    // Alola
  8: [810, 905],    // Galar
  9: [906, 1025],   // Paldea
};

String getGenerationLabel(int gen) {
  const sufijos = [
    "a Generación (Kanto)",
    "a Generación (Johto)",
    "a Generación (Hoenn)",
    "a Generación (Sinnoh)",
    "a Generación (Unova)",
    "a Generación (Kalos)",
    "a Generación (Alola)",
    "a Generación (Galar)",
    "a Generación (Paldea)"
  ];
  return "${gen}${sufijos[gen - 1]}";
}

// ----------- APP INITIALIZATION -----------
// Inicializa la aplicación Flutter con el tema principal y la pantalla de inicio

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(),
      title: '¿Quién es ese Pokémon?',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ----------- SPLASH SCREEN -----------
// Pantalla de carga inicial que muestra el logo de Pokémon y reproduce un audio de introducción

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playSplashAudio();
    _navigateToMain();
  }

  Future<void> _playSplashAudio() async {
    await _audioPlayer.play(AssetSource('audio/quienpokemon.mp3'));
  }

  Future<void> _navigateToMain() async {
    await Future.delayed(const Duration(seconds: 5));
    await _audioPlayer.stop();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PokemonGame()),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade600,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/pokemon.png',
              width: 300,
            ),
            const SizedBox(height: 30),

            const SizedBox(height: 50),
            CircularProgressIndicator(
              color: Colors.blue.shade900,
              strokeWidth: 5,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------- POKEMON GAME -----------
// Pantalla principal del juego donde se muestra la silueta del Pokémon y el usuario debe adivinar su nombre

class PokemonGame extends StatefulWidget {
  const PokemonGame({Key? key}) : super(key: key);

  @override
  State<PokemonGame> createState() => _PokemonGameState();
}

class _PokemonGameState extends State<PokemonGame> {
  String? pokemonImage;
  String? pokemonName;
  int? pokemonId;
  bool isLoading = true;
  bool isRevealed = false;
  bool? isCorrect;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int selectedGeneration = 1;

  Map<int, Set<int>> capturedPokemons = {};
  Map<int, Set<int>> escapedPokemons = {};

  AudioPlayer? _bgmPlayer;

  @override
  void initState() {
    super.initState();
    loadAllData();
    _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    _bgmPlayer = AudioPlayer();
    await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer!.setVolume(0.02);
    await _bgmPlayer!.play(AssetSource('audio/pokemon-intro.mp3'));
  }

  @override
  void dispose() {
    _bgmPlayer?.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> loadAllData() async {
    await loadCapturedPokemons();
    await loadEscapedPokemons();
    await loadRandomPokemon();
  }

  Future<void> loadCapturedPokemons() async {
    final prefs = await SharedPreferences.getInstance();
    for (var gen in generationRanges.keys) {
      final List<String>? saved = prefs.getStringList('capturedPokemons_gen$gen');
      capturedPokemons[gen] = saved?.map((e) => int.parse(e)).toSet() ?? {};
    }
    setState(() {});
  }

  Future<void> saveCapturedPokemons() async {
    final prefs = await SharedPreferences.getInstance();
    for (var gen in generationRanges.keys) {
      await prefs.setStringList(
        'capturedPokemons_gen$gen',
        capturedPokemons[gen]?.map((e) => e.toString()).toList() ?? [],
      );
    }
  }

  Future<void> loadEscapedPokemons() async {
    final prefs = await SharedPreferences.getInstance();
    for (var gen in generationRanges.keys) {
      final List<String>? saved = prefs.getStringList('escapedPokemons_gen$gen');
      escapedPokemons[gen] = saved?.map((e) => int.parse(e)).toSet() ?? {};
    }
    setState(() {});
  }

  Future<void> saveEscapedPokemons() async {
    final prefs = await SharedPreferences.getInstance();
    for (var gen in generationRanges.keys) {
      await prefs.setStringList(
        'escapedPokemons_gen$gen',
        escapedPokemons[gen]?.map((e) => e.toString()).toList() ?? [],
      );
    }
  }

  Future<void> loadRandomPokemon() async {
    setState(() {
      isLoading = true;
      isRevealed = false;
      isCorrect = null;
      _controller.clear();
    });

    try {
      final range = generationRanges[selectedGeneration]!;
      final random = Random();
      final id = random.nextInt(range[1] - range[0] + 1) + range[0];

      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['sprites']['other']['official-artwork']['front_default'];
        final name = data['name'];

        if (imageUrl == null || name == null) {
          await loadRandomPokemon();
          return;
        }

        setState(() {
          pokemonImage = imageUrl;
          pokemonName = name;
          pokemonId = id;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void checkAnswer() async {
    setState(() {
      isRevealed = true;
      if (_controller.text.trim().toLowerCase() == pokemonName?.toLowerCase()) {
        isCorrect = true;
        if (pokemonId != null) {
          capturedPokemons[selectedGeneration] ??= {};
          capturedPokemons[selectedGeneration]!.add(pokemonId!);
          escapedPokemons[selectedGeneration]?.remove(pokemonId!);
        }
      } else {
        isCorrect = false;
        if (pokemonId != null) {
          if (!capturedPokemons[selectedGeneration]!.contains(pokemonId!)) {
            escapedPokemons[selectedGeneration] ??= {};
            escapedPokemons[selectedGeneration]!.add(pokemonId!);
          }
        }
      }
    });
    await saveCapturedPokemons();
    await saveEscapedPokemons();
  }

  void goToPokedex() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PokedexScreen(
          capturedPokemons: capturedPokemons,
          escapedPokemons: escapedPokemons,
          onReset: (int gen) async {
            capturedPokemons[gen]?.clear();
            escapedPokemons[gen]?.clear();
            await saveCapturedPokemons();
            await saveEscapedPokemons();
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          color: Colors.red.shade600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Text(
                            "Generación:",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 4
                                ..color = Colors.blue.shade900,
                            ),
                          ),
                          const Text(
                            "Generación:",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Color(0xFFFFD600),
                            width: 2,
                          ),
                        ),
                        child: DropdownButton<int>(
                          value: selectedGeneration,
                          dropdownColor: Colors.red.shade900,
                          underline: Container(),
                          iconEnabledColor: Colors.white,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          items: generationRanges.keys
                              .map((gen) => DropdownMenuItem(
                            value: gen,
                            child: Text(
                              getGenerationLabel(gen),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ))
                              .toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              setState(() {
                                selectedGeneration = value;
                              });
                              await loadRandomPokemon();
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(15.0),
                  child: Image.asset(
                    'assets/images/udg.png',
                    width: 250,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(15.0),
                  child: Image.asset(
                    'assets/images/pokemon.png',
                    width: 250,
                  ),
                ),
                const SizedBox(height: 10),
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: pokemonImage != null
                          ? ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black,
                          isRevealed ? BlendMode.dst : BlendMode.srcATop,
                        ),
                        child: Image.network(
                          pokemonImage!,
                          fit: BoxFit.contain,
                        ),
                      )
                          : const Center(child: Text('Error al cargar imagen')),
                    ),
                    const SizedBox(height: 20),
                    if (!isRevealed)
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).requestFocus(_focusNode);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Container(
                            height: 60,
                            alignment: Alignment.center,
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20),
                              decoration: InputDecoration(
                                hintText: 'Escribe el nombre del Pokémon',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (isRevealed)
                      Column(
                        children: [
                          if (isCorrect == true)
                            Column(
                              children: [
                                Image.asset(
                                  'assets/images/pokebola.png',
                                  width: 80,
                                ),
                                const SizedBox(height: 10),
                                Stack(
                                  children: [
                                    Text(
                                      '¡Pokémon capturado!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 4
                                          ..color = Colors.blue.shade900,
                                      ),
                                    ),
                                    const Text(
                                      '¡Pokémon capturado!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFFD600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            Stack(
                              children: [
                                Text(
                                  '¡Pokémon huyó!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 4
                                      ..color = Colors.blue.shade900,
                                  ),
                                ),
                                const Text(
                                  '¡Pokémon huyó!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFD600),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          Stack(
                            children: [
                              Text(
                                '¡Era ${pokemonName != null ? pokemonName![0].toUpperCase() + pokemonName!.substring(1) : "desconocido"}!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 4
                                    ..color = Colors.blue.shade900,
                                ),
                              ),
                              Text(
                                '¡Era ${pokemonName != null ? pokemonName![0].toUpperCase() + pokemonName!.substring(1) : "desconocido"}!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFD600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: isLoading || isRevealed ? null : checkAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Revelar',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: (isLoading || !isRevealed) ? null : loadRandomPokemon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Siguiente',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: goToPokedex,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Pokedex',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15.0),
                      topRight: Radius.circular(15.0),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Angel Francisco Sanchez de Tagle Marquez',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Diseño de aplicaciones móviles',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------- POKEDEX SCREEN -----------
// Pantalla que muestra los Pokémon capturados y escapados, además de un sistema de medallas por logros

class PokedexScreen extends StatefulWidget {
  final Map<int, Set<int>> capturedPokemons;
  final Map<int, Set<int>> escapedPokemons;
  final Future<void> Function(int gen) onReset;

  const PokedexScreen({
    Key? key,
    required this.capturedPokemons,
    required this.escapedPokemons,
    required this.onReset,
  }) : super(key: key);

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final List<int> badgeThresholds = [20, 40, 60, 80, 100, 120, 140, 151];
  final List<String> badgeImages = [
    'assets/images/medalla1.png',
    'assets/images/medalla2.png',
    'assets/images/medalla3.png',
    'assets/images/medalla4.png',
    'assets/images/medalla5.png',
    'assets/images/medalla6.png',
    'assets/images/medalla7.png',
    'assets/images/medalla8.png',
  ];
  Set<int> notifiedBadges = {};

  @override
  void initState() {
    super.initState();
    _loadNotifiedBadges();
  }

  Future<void> _loadNotifiedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('notifiedBadges') ?? [];
    setState(() {
      notifiedBadges = list.map(int.parse).toSet();
    });
    _checkBadges();
  }

  void _checkBadges() async {
    final captured = widget.capturedPokemons[1]?.length ?? 0;
    for (int i = 0; i < badgeThresholds.length; i++) {
      if (captured >= badgeThresholds[i] && !notifiedBadges.contains(i)) {
        notifiedBadges.add(i);
        final prefs = await SharedPreferences.getInstance();
        prefs.setStringList('notifiedBadges', notifiedBadges.map((e) => e.toString()).toList());
        await Future.delayed(const Duration(milliseconds: 500));
        _showBadgeDialog(i + 1, badgeImages[i], badgeThresholds[i]);
      }
    }
    setState(() {});
  }

  void _showBadgeDialog(int badgeNumber, String badgeImage, int threshold) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '¡Logro desbloqueado!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 4
                  ..color = Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              '¡Logro desbloqueado!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD600),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              badgeImage,
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 10),
            Text(
              '¡Has conseguido la medalla $badgeNumber por capturar $threshold Pokémon!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget badgeBoard(int captured, {bool showMedals = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF8B5C2A),
          width: 8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.shade900.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                "Medallas de Gimnasio",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 6
                    ..color = Colors.blue.shade900,
                ),
              ),
              const Text(
                "Medallas de Gimnasio",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (i) => showMedals ? _badgeImage(i, captured) : _emptyBadge()),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (i) => showMedals ? _badgeImage(i + 4, captured) : _emptyBadge()),
          ),
        ],
      ),
    );
  }

  Widget _badgeImage(int i, int captured) {
    final unlocked = captured >= badgeThresholds[i];
    if (!unlocked) {
      return _emptyBadge();
    }
    return Container(
      width: 54,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade700,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Image.asset(
          badgeImages[i],
          width: 44,
          height: 44,
        ),
      ),
    );
  }

  Widget _emptyBadge() {
    return Container(
      width: 54,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade700,
          width: 2,
        ),
      ),
      child: const Center(
        child: Icon(Icons.help_outline, color: Colors.grey, size: 32),
      ),
    );
  }

  Future<String?> getPokemonDescription(int pokeId) async {
    final response = await http.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$pokeId/'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final entries = data['flavor_text_entries'] as List;
      final entryEs = entries.firstWhere(
            (e) => e['language']['name'] == 'es',
        orElse: () => null,
      );
      if (entryEs != null) {
        return (entryEs['flavor_text'] as String)
            .replaceAll('\n', ' ')
            .replaceAll('\f', ' ')
            .trim();
      }
    }
    return null;
  }

  Widget generationHeader(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.red.shade900,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 6
                ..color = Colors.blue.shade900,
            ),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD600),
            ),
          ),
        ],
      ),
    );
  }

  Widget generationStats(int gen) {
    final captured = widget.capturedPokemons[gen]?.length ?? 0;
    final escaped = widget.escapedPokemons[gen]?.length ?? 0;
    final total = generationRanges[gen]![1] - generationRanges[gen]![0] + 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade900, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.catching_pokemon, color: Colors.green),
              Text(
                'Capturados\n$captured/$total',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Icon(Icons.running_with_errors, color: Colors.grey.shade700),
              Text(
                'Escapados\n$escaped/$total',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Icon(Icons.question_mark, color: Colors.blue.shade900),
              Text(
                'Por ver\n${total - captured - escaped}/$total',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showResetConfirmationDialog(int gen) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reiniciar ${getGenerationLabel(gen)}',
            style: TextStyle(color: Colors.red.shade900),
          ),
          content: const Text(
            '¿Estás seguro que quieres borrar todos los Pokémon capturados y vistos de esta generación?\n\nEsta acción no se puede deshacer.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Reiniciar',
                style: TextStyle(color: Colors.red.shade900),
              ),
              onPressed: () async {
                await widget.onReset(gen);
                setState(() {});
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPokemonDetails(int pokeId, String status) async {
    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$pokeId'),
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final name = data['name'];
        final types = (data['types'] as List)
            .map((type) => type['type']['name'].toString())
            .toList();

        final description = await getPokemonDescription(pokeId);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    name[0].toUpperCase() + name.substring(1),
                    style: TextStyle(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4
                        ..color = Colors.blue.shade900,
                    ),
                  ),
                  Text(
                    name[0].toUpperCase() + name.substring(1),
                    style: const TextStyle(
                      color: Color(0xFFFFD600),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  status == 'captured'
                      ? Image.network(
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokeId.png',
                    height: 150,
                  )
                      : ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcATop,
                    ),
                    child: Image.network(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokeId.png',
                      height: 150,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tipos: ${types.join(", ")}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Estado: ${status == "captured" ? "Capturado" : "Escapado"}',
                    style: TextStyle(
                      fontSize: 16,
                      color: status == "captured" ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cerrar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Manejo de errores
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pokedexWidgets = [];

    for (final gen in generationRanges.keys) {
      final range = generationRanges[gen]!;
      final start = range[0];
      final end = range[1];

      pokedexWidgets.add(generationHeader(getGenerationLabel(gen)));

      final capturedGen1 = widget.capturedPokemons[1]?.length ?? 0;
      pokedexWidgets.add(
        badgeBoard(
          capturedGen1,
          showMedals: gen == 1,
        ),
      );

      pokedexWidgets.add(generationStats(gen));

      pokedexWidgets.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: end - start + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final pokeId = start + index;
              final isCaptured = widget.capturedPokemons[gen]?.contains(pokeId) ?? false;
              final isEscaped = widget.escapedPokemons[gen]?.contains(pokeId) ?? false;

              return GestureDetector(
                onTap: () {
                  if (isCaptured) {
                    _showPokemonDetails(pokeId, 'captured');
                  } else if (isEscaped) {
                    _showPokemonDetails(pokeId, 'escaped');
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isCaptured
                          ? Colors.green
                          : isEscaped
                          ? Colors.red
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isCaptured || isEscaped
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isEscaped
                        ? ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcATop,
                      ),
                      child: Image.network(
                        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokeId.png',
                        fit: BoxFit.contain,
                      ),
                    )
                        : Image.network(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokeId.png',
                      fit: BoxFit.contain,
                    ),
                  )
                      : Center(
                    child: Text(
                      '#$pokeId',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      pokedexWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: () => _showResetConfirmationDialog(gen),
            icon: const Icon(Icons.refresh),
            label: Text('Reiniciar ${getGenerationLabel(gen)}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      );

      if (gen != generationRanges.keys.last) {
        pokedexWidgets.add(
          Divider(
            color: Colors.blue.shade900,
            thickness: 2,
            indent: 20,
            endIndent: 20,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Stack(
          children: [
            Text(
              'Pokédex',
              style: TextStyle(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6
                  ..color = Colors.blue.shade900,
              ),
            ),
            const Text(
              'Pokédex',
              style: TextStyle(
                color: Color(0xFFFFD600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade900,
      ),
      body: SingleChildScrollView(
        child: Column(children: pokedexWidgets),
      ),
    );
  }
}