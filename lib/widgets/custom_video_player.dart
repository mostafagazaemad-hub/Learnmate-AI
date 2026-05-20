import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GeneratedVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const GeneratedVideoPlayer({super.key, required this.videoUrl});

  @override
  State<GeneratedVideoPlayer> createState() => _GeneratedVideoPlayerState();
}

class _GeneratedVideoPlayerState extends State<GeneratedVideoPlayer> {
  VideoPlayerController? _videoController;
  WebViewController? _webController;
  bool _isError = false;
  bool _isYoutube = false;

  @override
  void initState() {
    super.initState();
    _checkUrlType();
  }

  void _checkUrlType() {
    _isYoutube = widget.videoUrl.contains('youtube.com') || widget.videoUrl.contains('youtu.be');
    
    if (_isYoutube) {
      _initYoutube();
    } else {
      _initVideoPlayer();
    }
  }

  void _initYoutube() {
    _webController = WebViewController();
    
    if (!kIsWeb) {
      // Restricted JavaScript mode on non-web platforms for security, 
      // but unrestricted is often needed for YouTube interaction.
      _webController!.setJavaScriptMode(JavaScriptMode.unrestricted);
      _webController!.setBackgroundColor(const Color(0x00000000));
    }
    
    // Optimize YouTube URL for interaction and mobile reliability
    String embedUrl = widget.videoUrl;
    if (widget.videoUrl.contains('watch?v=')) {
      embedUrl = widget.videoUrl.replaceFirst('watch?v=', 'embed/');
    }

    // Add interaction-friendly parameters
    final uri = Uri.parse(embedUrl);
    final updatedUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'enablejsapi': '1',
      'modestbranding': '1',
      'rel': '0',
      'iv_load_policy': '3',
    });

    _webController!.loadRequest(updatedUri);
  }

  void _initVideoPlayer() {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController!.play();
          _videoController!.setLooping(true);
        }
      }).catchError((error) {
        if (mounted) {
          setState(() => _isError = true);
        }
        debugPrint("Video Error: $error");
      });
  }

  @override
  void didUpdateWidget(GeneratedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _videoController?.dispose();
      _checkUrlType();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutube) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: WebViewWidget(
            controller: _webController!,
            // CRITICAL: Gesture recognizers allow the WebView to capture touches 
            // instead of letting them "fall through" or be blocked by Flutter's gesture system.
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
            },
          ),
        ),
      );
    }

    if (_isError) {
      return _buildErrorState();
    }

    return _videoController?.value.isInitialized ?? false
        ? AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: VideoPlayer(_videoController!),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(_videoController!, allowScrubbing: true),
                ),
                _buildPlayButton(),
              ],
            ),
          )
        : _buildLoadingState();
  }

  Widget _buildPlayButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
          });
        },
        child: Container(
          decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
          child: Icon(
            _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: Colors.white70,
            size: 60,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text("تعذر تشغيل الفيديو.", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() { _isError = false; _initVideoPlayer(); }),
              child: const Text("إعادة المحاولة"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("جاري عرض الفيديو..."),
          ],
        ),
      ),
    );
  }
}
