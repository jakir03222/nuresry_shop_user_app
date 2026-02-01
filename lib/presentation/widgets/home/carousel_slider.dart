import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/carousel_model.dart';

class CarouselSliderWidget extends StatefulWidget {
  final List<CarouselModel> carousels;

  const CarouselSliderWidget({
    super.key,
    required this.carousels,
  });

  @override
  State<CarouselSliderWidget> createState() => _CarouselSliderWidgetState();
}

class _CarouselSliderWidgetState extends State<CarouselSliderWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.carousels.isNotEmpty) {
      _startAutoPlay();
    }
  }

  @override
  void didUpdateWidget(covariant CarouselSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.carousels.isEmpty) {
      _timer?.cancel();
      _timer = null;
    } else if (oldWidget.carousels.isEmpty || oldWidget.carousels.length != widget.carousels.length) {
      _timer?.cancel();
      _currentPage = 0;
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.carousels.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_pageController.hasClients) return;
      final next = _currentPage < widget.carousels.length - 1 ? _currentPage + 1 : 0;
      _currentPage = next;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.carousels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.carousels.length,
            itemBuilder: (context, index) {
              final carousel = widget.carousels[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(Colors.black, Colors.transparent, 0.9)!,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: carousel.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: AppColors.borderGrey,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBlue,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                        fadeInDuration: const Duration(milliseconds: 300),
                        fadeOutDuration: const Duration(milliseconds: 100),
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: AppColors.borderGrey,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Gradient overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color.lerp(Colors.black, Colors.transparent, 0.5)!,
                            ],
                          ),
                        ),
                      ),
                      // Title and Description
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                carousel.title,
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (carousel.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  carousel.description,
                                  style: const TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Page Indicators - green active, grey inactive (same as image)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.carousels.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.borderGrey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
