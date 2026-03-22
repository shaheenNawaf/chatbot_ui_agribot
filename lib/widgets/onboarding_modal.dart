import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingModal extends StatefulWidget {
  const OnboardingModal({Key? key}) : super(key: key);

  @override
  State<OnboardingModal> createState() => _OnboardingModalState();

  static Future<void> showIfRequired(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final shouldShow = prefs.getBool('show_onboarding') ?? true;

    if (shouldShow && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const OnboardingModal(),
      );
    }
  }
}

class _OnboardingModalState extends State<OnboardingModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _doNotShowAgain = false;

  final List<Map<String, String>> _pages = [
    {
      "title": "Welcome to Agri-Pinoy!",
      "subtitle":
          "Your AI farming assistant for Philippine cash crops like Rice, Corn, Cocoa, Banana and Wheat.",
      "image": "assets/images/step1.png",
    },
    {
      "title": "Ask Specific Questions in English",
      "subtitle":
          "Tap any of the suggested prompts above the chat box to get started with common farming concerns.",
      "image": "assets/images/step2.png",
    },
    {
      "title": "Customize Response Depth",
      "subtitle":
          "Use the Settings (tune icon) to choose if you want a Concise, Balanced, or Deep AI answer.",
      "image": "assets/images/step3.png",
    },
    {
      "title": "Start Fresh Anytime",
      "subtitle":
          "Need to switch crops? Simply tap the 'New Chat' icon at the top right to clear the current session.",
      "image": "assets/images/step4.png",
    },
  ];

  void _completeOnboarding() async {
    if (_doNotShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_onboarding', false);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 550, maxWidth: 400),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 20,
                      right: 20,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200], // Placeholder color
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.green[200]!,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Placeholder.\n(${index + 1}/4)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _pages[index]['title']!,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _pages[index]['subtitle']!,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF2E7D32)
                                : Colors.green[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _doNotShowAgain,
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (value) {
                            setState(() => _doNotShowAgain = value ?? false);
                          },
                        ),
                        Text(
                          "Do not show this again",
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            );
                          }
                        },
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? "GET STARTED"
                              : "NEXT",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
