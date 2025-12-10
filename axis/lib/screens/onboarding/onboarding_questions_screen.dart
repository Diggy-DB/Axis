import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class OnboardingQuestionsScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String email;
  final String password;

  const OnboardingQuestionsScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.email,
    required this.password,
  });

  @override
  State<OnboardingQuestionsScreen> createState() =>
      _OnboardingQuestionsScreenState();
}

class _OnboardingQuestionsScreenState
    extends State<OnboardingQuestionsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  final _answer3Controller = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    _answer3Controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signUpWithDetails(
        email: widget.email,
        password: widget.password,
        firstName: widget.firstName,
        lastName: widget.lastName,
        dateOfBirth: widget.dateOfBirth,
        coreValues: _answer1Controller.text.trim(),
        worldview: _answer2Controller.text.trim(),
        ambition: _answer3Controller.text.trim(),
      );

      if (mounted && authProvider.error == null) {
        // Router will automatically redirect to home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(
                      right: index < 2 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Questions
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildQuestionPage(
                  question: 'What are my Core Values?',
                  description:
                      'Often people respond in perplexity or come up with some general answers for this question, but by which values do we really live? Realistically value is revealed by how much time or money we spend for something. Think about this and write your deepest desired values, which you want to see expressed in your daily activities.',
                  controller: _answer1Controller,
                ),
                _buildQuestionPage(
                  question:
                      'What is my Worldview, Believe System\nand Purpose?',
                  description:
                      'How do you think about yourself, your next person, or even really different people, the world, even the universe, and what is your place or role in it?\n\nThere are three roles:\n• Main role (protagonist)\n• Supporting role\n• Opposite role (antagonist)',
                  controller: _answer2Controller,
                ),
                _buildQuestionPage(
                  question: 'What is your ambition?\nWhat role do you want to play in the future?',
                  description:
                      'Describe your future aspirations and the role you envision for yourself. What impact do you want to make?',
                  controller: _answer3Controller,
                  isLast: true,
                ),
              ],
            ),
          ),

          // Continue Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_currentPage < 2) {
                          _nextPage();
                        } else {
                          _completeOnboarding();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _currentPage < 2 ? 'Continue' : 'Complete',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage({
    required String question,
    required String description,
    required TextEditingController controller,
    bool isLast = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            question,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Write your answer here...',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ],
      ),
    );
  }
}
