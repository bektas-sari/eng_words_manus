import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'vocabulary_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English-Turkish Vocabulary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      themeMode: ThemeMode.system,
      home: const VocabularyQuizScreen(),
    );
  }
}

class VocabularyQuizScreen extends StatefulWidget {
  const VocabularyQuizScreen({Key? key}) : super(key: key);

  @override
  State<VocabularyQuizScreen> createState() => _VocabularyQuizScreenState();
}

class _VocabularyQuizScreenState extends State<VocabularyQuizScreen> with SingleTickerProviderStateMixin {
  int currentCardIndex = 0;
  int correctAnswers = 0;
  bool quizCompleted = false;
  bool isAnswering = false;
  
  // For card animation
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;
  
  bool? lastAnswerCorrect;
  
  final Random random = Random();
  
  // Shuffled list of vocabulary
  late List<Map<String, dynamic>> shuffledVocabulary;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Default animation (will be updated when answer is selected)
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.green,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Shuffle the vocabulary list
    shuffledVocabulary = List.from(vocabularyList);
    shuffledVocabulary.shuffle(random);
    
    // Limit to 20 words as per requirements
    if (shuffledVocabulary.length > 20) {
      shuffledVocabulary = shuffledVocabulary.sublist(0, 20);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Get a random incorrect translation
  String getRandomIncorrectTranslation() {
    List<String> allTranslations = vocabularyList.map((item) => item['turkish'] as String).toList();
    String correctTranslation = shuffledVocabulary[currentCardIndex]['turkish'] as String;
    
    // Remove the correct translation from the list
    allTranslations.remove(correctTranslation);
    
    // Return a random incorrect translation
    return allTranslations[random.nextInt(allTranslations.length)];
  }
  
  // Get answer options in random order
  List<Map<String, dynamic>> getAnswerOptions() {
    String correctTranslation = shuffledVocabulary[currentCardIndex]['turkish'] as String;
    String incorrectTranslation = getRandomIncorrectTranslation();
    
    List<Map<String, dynamic>> options = [
      {'text': correctTranslation, 'isCorrect': true},
      {'text': incorrectTranslation, 'isCorrect': false},
    ];
    
    // Shuffle the options
    options.shuffle(random);
    
    return options;
  }
  
  void checkAnswer(bool isCorrect) {
    if (isAnswering) return;
    
    setState(() {
      isAnswering = true;
      lastAnswerCorrect = isCorrect;
      
      if (isCorrect) {
        correctAnswers++;
        
        // Set animation for correct answer (right swipe with green background)
        _animation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(1.5, 0.0),
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        
        _colorAnimation = ColorTween(
          begin: Colors.white,
          end: Colors.green[300],
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
      } else {
        // Set animation for incorrect answer (left swipe with red background)
        _animation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.5, 0.0),
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        
        _colorAnimation = ColorTween(
          begin: Colors.white,
          end: Colors.red[300],
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
      }
    });
    
    // Start the animation
    _animationController.forward().then((_) {
      // Reset animation
      _animationController.reset();
      
      setState(() {
        isAnswering = false;
        
        // Move to next card or complete quiz
        if (currentCardIndex < shuffledVocabulary.length - 1) {
          currentCardIndex++;
        } else {
          quizCompleted = true;
        }
      });
    });
  }
  
  void restartQuiz() {
    setState(() {
      currentCardIndex = 0;
      correctAnswers = 0;
      quizCompleted = false;
      
      // Reshuffle the vocabulary list
      shuffledVocabulary.shuffle(random);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('English-Turkish Vocabulary'),
        elevation: 0,
      ),
      body: SafeArea(
        child: quizCompleted
            ? _buildResultScreen()
            : _buildQuizScreen(),
      ),
    );
  }
  
  Widget _buildQuizScreen() {
    final List<Map<String, dynamic>> answerOptions = getAnswerOptions();
    
    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: LinearProgressIndicator(
            value: (currentCardIndex + 1) / shuffledVocabulary.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        
        // Card counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Card ${currentCardIndex + 1} of ${shuffledVocabulary.length}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Flashcard
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: _animation,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: _colorAnimation.value,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              shuffledVocabulary[currentCardIndex]['english'] as String,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Select the correct Turkish translation:',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
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
        ),
        
        // Answer buttons
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              for (final option in answerOptions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isAnswering
                          ? null
                          : () => checkAnswer(option['isCorrect'] as bool),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        option['text'] as String,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildResultScreen() {
    final double percentage = (correctAnswers / shuffledVocabulary.length) * 100;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              'Quiz Completed!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'You got $correctAnswers out of ${shuffledVocabulary.length} correct!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: percentage >= 70 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: restartQuiz,
                icon: const Icon(Icons.refresh),
                label: const Text('Restart Quiz'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
