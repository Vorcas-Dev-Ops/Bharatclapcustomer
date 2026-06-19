import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/onboarding_1.png',
      title: 'Your trusted partner for\nhome services.',
      description: 'Find verified professionals for electrical work, plumbing, cleaning, appliance repair, and more.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding_2.png',
      title: 'Book services in minutes.',
      description: 'Browse categories, choose a professional, and schedule services at your convenience.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding_3.png',
      title: 'Stay updated every step of\nthe way.',
      description: 'Browse categories, choose a professional, and schedule services at your convenience.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Image.asset(
                              _pages[index].image,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 40,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _pages[_currentPage].title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B1464),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _pages[_currentPage].description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_currentPage == _pages.length - 1)
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B1464),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Register or Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              'Skip for now',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                              );
                            },
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => _buildDot(index),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Row(
                            children: [
                              Text(
                                'Next',
                                style: TextStyle(
                                  color: Color(0xFF1B1464),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Color(0xFF1B1464),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFF1B1464)
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
