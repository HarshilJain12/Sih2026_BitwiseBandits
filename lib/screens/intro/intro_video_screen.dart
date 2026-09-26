import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/route_names.dart';

/// Full-screen intro video that plays when the app first opens.
///
/// After the video completes (or the user taps "Skip"), the screen
/// navigates to the splash route which then redirects to the normal flow
/// (language selection or role selection).
class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasNavigated = false;
  bool _showSkip = false;

  // Fade-out animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set immersive full-screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Fade animation for smooth transition out
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/videos/intro.mp4');

    try {
      await _controller.initialize();
      _controller.addListener(_onVideoProgress);
      setState(() => _isInitialized = true);

      // Start playing immediately
      await _controller.play();

      // Show skip button after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSkip = true);
      });
    } catch (e) {
      // If video fails to load, skip to main app immediately
      debugPrint('⚠️ Intro video failed to load: $e');
      _navigateToApp();
    }
  }

  void _onVideoProgress() {
    if (_hasNavigated) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    // Navigate when video is complete (or within 200ms of the end)
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 200)) {
      _navigateToApp();
    }
  }

  Future<void> _navigateToApp() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    // Fade to black before navigating
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    context.go(RouteNames.splash);
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoProgress);
    _controller.dispose();
    _fadeController.dispose();

    // Restore system UI in case dispose runs before navigation
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video player (fullscreen cover)
          if (_isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),

          // Tap anywhere to skip
          Positioned.fill(
            child: GestureDetector(
              onTap: _navigateToApp,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),

          // Skip button (appears after 2 seconds)
          if (_showSkip)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _showSkip ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToApp,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Fade-out overlay (black screen transition)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
