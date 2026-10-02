import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:drivio/theme/app_theme.dart';

/// Swipeable trap photos with page dots; tapping opens a zoomable viewer.
class TrapPhotoGallery extends StatefulWidget {
  const TrapPhotoGallery({super.key, required this.urls});

  final List<String> urls;

  @override
  State<TrapPhotoGallery> createState() => _TrapPhotoGalleryState();
}

class _TrapPhotoGalleryState extends State<TrapPhotoGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(urls: widget.urls, initialIndex: _index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.urls.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (context, index) => GestureDetector(
            onTap: _openViewer,
            child: CachedNetworkImage(
              imageUrl: widget.urls[index],
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                color: colors.surface,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
              errorWidget: (_, _, _) => Container(
                color: colors.surface,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: colors.onSurfaceVariant,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        if (widget.urls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.urls.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _index ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(blurRadius: 4, color: Colors.black38),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PhotoViewGallery.builder(
        itemCount: urls.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(urls[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
      ),
    );
  }
}
