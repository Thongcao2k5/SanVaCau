import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/url_util.dart';
import '../models/home_data.dart';

/// Data for a single hero carousel slide.
class _HeroSlide {
  const _HeroSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.cta,
    required this.icon,
    this.imageUrl,
    this.linkUrl,
    this.onPressed,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String cta;
  final IconData icon;
  final String? imageUrl;
  final String? linkUrl;
  final VoidCallback? onPressed;
}

class HomeHeroSection extends StatefulWidget {
  const HomeHeroSection({
    required this.onBookCourtPressed,
    required this.onViewProductsPressed,
    required this.onRacketServicePressed,
    required this.onViewBranchesPressed,
    this.banners = const [],
    super.key,
  });

  final VoidCallback onBookCourtPressed;
  final VoidCallback onViewProductsPressed;
  final VoidCallback onRacketServicePressed;
  final VoidCallback onViewBranchesPressed;
  final List<HomeBanner> banners;

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;
  bool _userInteracted = false;
  bool _disposed = false;

  static const _autoPlayDuration = Duration(seconds: 5);
  static const _animationDuration = Duration(milliseconds: 320);

  List<_HeroSlide> get _fallbackSlides => [
    _HeroSlide(
      eyebrow: 'ĐẶT SÂN TRỰC TUYẾN',
      title: 'Tìm sân trống, vào trận nhanh.',
      description: 'Chọn ngày, giờ và chi nhánh phù hợp.',
      cta: 'Xem lịch sân trống',
      icon: Icons.sports_tennis_rounded,
      onPressed: widget.onBookCourtPressed,
    ),
    _HeroSlide(
      eyebrow: 'DỤNG CỤ CẦU LÔNG',
      title: 'Trang bị chuẩn, tự tin từng cú đánh.',
      description: 'Khám phá vợt, giày và phụ kiện phù hợp.',
      cta: 'Khám phá sản phẩm',
      icon: Icons.shopping_bag_rounded,
      onPressed: widget.onViewProductsPressed,
    ),
    _HeroSlide(
      eyebrow: 'DỊCH VỤ VỢT',
      title: 'Căng vợt đúng lực, chơi đúng phong độ.',
      description: 'Chọn chi nhánh và dịch vụ phù hợp với bạn.',
      cta: 'Xem dịch vụ',
      icon: Icons.build_rounded,
      onPressed: widget.onRacketServicePressed,
    ),
    _HeroSlide(
      eyebrow: 'HỆ THỐNG SANVACAU',
      title: 'Sân gần bạn, tiện đường ra trận.',
      description: 'Khám phá các chi nhánh SanVaCau.',
      cta: 'Xem chi nhánh',
      icon: Icons.location_on_rounded,
      onPressed: widget.onViewBranchesPressed,
    ),
  ];

  /// Actions mapped by slide position for API banners without linkUrl.
  List<VoidCallback> get _positionalActions => [
    widget.onBookCourtPressed,
    widget.onViewProductsPressed,
    widget.onRacketServicePressed,
    widget.onViewBranchesPressed,
  ];

  List<_HeroSlide> _buildSlides() {
    final fallbacks = _fallbackSlides;
    final apiBanners = widget.banners.take(4).toList();

    final slides = <_HeroSlide>[];
    for (var i = 0; i < apiBanners.length && i < 4; i++) {
      final banner = apiBanners[i];
      slides.add(
        _HeroSlide(
          eyebrow: banner.title.isNotEmpty
              ? banner.title.toUpperCase()
              : fallbacks[i].eyebrow,
          title: fallbacks[i].title,
          description: fallbacks[i].description,
          cta: fallbacks[i].cta,
          icon: fallbacks[i].icon,
          imageUrl: banner.imageUrl.isNotEmpty ? banner.imageUrl : null,
          linkUrl: banner.linkUrl,
          onPressed: (banner.linkUrl != null && banner.linkUrl!.isNotEmpty)
              ? null // Will use linkUrl via openUrlSafely
              : _positionalActions[i],
        ),
      );
    }

    // Fill remaining positions with fallback slides.
    for (var i = slides.length; i < 4; i++) {
      slides.add(fallbacks[i]);
    }

    return slides;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopAutoPlay();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoPlay();
    } else {
      _stopAutoPlay();
    }
  }

  void _startAutoPlay() {
    if (_userInteracted || _disposed) return;
    // Check reduced motion via the platform dispatcher.
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    if (features.disableAnimations) return;

    _stopAutoPlay();
    _autoPlayTimer = Timer.periodic(_autoPlayDuration, (_) {
      if (_disposed || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % 4;
      _pageController.animateToPage(
        nextPage,
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _onPageChanged(int page) {
    if (_disposed) return;
    setState(() => _currentPage = page);
  }

  void _onUserInteraction() {
    _userInteracted = true;
    _stopAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 4,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return GestureDetector(
                onPanDown: (_) => _onUserInteraction(),
                child: _HeroSlideCard(slide: slides[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _PageIndicators(count: 4, currentPage: _currentPage),
      ],
    );
  }
}

class _HeroSlideCard extends StatelessWidget {
  const _HeroSlideCard({required this.slide});

  final _HeroSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: API image or fallback gradient.
            _SlideBackground(imageUrl: slide.imageUrl, icon: slide.icon),
            // Dark overlay for readability.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryDark.withValues(alpha: 0.55),
                    AppColors.primaryDark.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            // Content.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eyebrow badge.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      slide.eyebrow,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Title.
                  Flexible(
                    child: Text(
                      slide.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Description.
                  Text(
                    slide.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  // CTA Button.
                  _SlideCta(slide: slide),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideBackground extends StatelessWidget {
  const _SlideBackground({this.imageUrl, required this.icon});

  final String? imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _FallbackBackground(icon: icon),
      );
    }
    return _FallbackBackground(icon: icon);
  }
}

class _FallbackBackground extends StatelessWidget {
  const _FallbackBackground({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: CustomPaint(
        painter: _CourtLinesPainter(),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              icon,
              size: 72,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws subtle geometric badminton-court lines.
class _CourtLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Horizontal lines.
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      paint,
    );
    // Vertical center line.
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      paint,
    );
    // Center rectangle.
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: size.width * 0.4,
        height: size.height * 0.5,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SlideCta extends StatelessWidget {
  const _SlideCta({required this.slide});

  final _HeroSlide slide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FilledButton(
        onPressed: () {
          if (slide.linkUrl != null && slide.linkUrl!.isNotEmpty) {
            openUrlSafely(context, slide.linkUrl!);
          } else {
            slide.onPressed?.call();
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                slide.cta,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({required this.count, required this.currentPage});

  final int count;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}
