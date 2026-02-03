import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:spotshare/services/story_service.dart';

class StoryPlayerPage extends StatefulWidget {
  final List<dynamic> stories;
  final int initialIndex;
  // Infos utilisateur
  final String username;
  final String userImage;
  final bool isMine;

  const StoryPlayerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.username,
    required this.userImage,
    required this.isMine,
  });

  @override
  State<StoryPlayerPage> createState() => _StoryPlayerPageState();
}

class _StoryPlayerPageState extends State<StoryPlayerPage> {
  late PageController _pageController;
  late int _currentIndex;
  final StoryService _storyService = StoryService();
  
  VideoPlayerController? _videoController;
  Timer? _timer;
  double _progress = 0.0;
  bool _isDeleted = false; 

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _startStory();
  }

  void _startStory() {
    if (_isDeleted || widget.stories.isEmpty) return;

    final story = widget.stories[_currentIndex];
    final bool isVideo = story['media_type'] == "VIDEO";
    final String url = story['media_url'];
    final int storyId = story['story_id'];

    // Marquer comme vu
    _storyService.viewStory(storyId);

    _progress = 0.0;
    _timer?.cancel();
    _videoController?.dispose();
    _videoController = null;

    if (isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController!.play();
            _videoController!.addListener(() {
              if (_videoController!.value.isInitialized) {
                setState(() {
                  _progress = _videoController!.value.position.inMilliseconds / 
                              _videoController!.value.duration.inMilliseconds;
                });
                if (_videoController!.value.position >= _videoController!.value.duration) {
                  _nextStory();
                }
              }
            });
          }
        });
    } else {
      // Image : 5 secondes
      const duration = Duration(seconds: 5);
      const tick = Duration(milliseconds: 50);
      int totalTicks = duration.inMilliseconds ~/ tick.inMilliseconds;
      int currentTick = 0;

      _timer = Timer.periodic(tick, (timer) {
        currentTick++;
        if (mounted) {
          setState(() {
            _progress = currentTick / totalTicks;
          });
        }

        if (currentTick >= totalTicks) {
          timer.cancel();
          _nextStory();
        }
      });
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.jumpToPage(_currentIndex);
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.jumpToPage(_currentIndex);
      _startStory();
    }
  }

  Future<void> _deleteCurrentStory() async {
    _timer?.cancel();
    _videoController?.pause();

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer"),
        content: const Text("Voulez-vous supprimer cette story ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final storyId = widget.stories[_currentIndex]['story_id'];
      await _storyService.deleteStory(storyId);
      
      setState(() {
        widget.stories.removeAt(_currentIndex);
      });

      if (widget.stories.isEmpty) {
        _isDeleted = true;
        if(mounted) Navigator.pop(context);
      } else {
        if (_currentIndex >= widget.stories.length) {
          _currentIndex = widget.stories.length - 1;
        }
        _pageController.jumpToPage(_currentIndex);
        _startStory();
      }
    } else {
      if (_videoController != null) _videoController!.play();
      _startStory();
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().toUtc().difference(date.toUtc()); 
      if (diff.inMinutes < 60) return "${diff.inMinutes}m";
      if (diff.inHours < 24) return "${diff.inHours}h";
      return "${diff.inDays}j";
    } catch (e) {
      return "";
    }
  }

  /// Helper pour récupérer l'ImageProvider ou null si pas d'image
  ImageProvider? _getProfileImageProvider(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    
    // Si l'URL est absolue
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    
    // Si l'URL est relative (cas fréquent avec les uploads locaux)
    // Adaptez l'IP si besoin (10.0.2.2 pour émulateur Android, localhost pour iOS simulator)
    return NetworkImage("http://10.0.2.2:8000/$url");
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    
    final currentStory = widget.stories.isNotEmpty ? widget.stories[_currentIndex] : null;
    final String timeAgo = currentStory != null ? _formatTime(currentStory['date'] ?? "") : "";

    // On prépare l'image provider
    final ImageProvider? profileImage = _getProfileImageProvider(widget.userImage);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onLongPress: () {
            _timer?.cancel();
            _videoController?.pause();
        },
        onLongPressUp: () {
            _startStory();
        },
        child: Stack(
          children: [
            // 1. CONTENT
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return Center(
                  child: story['media_type'] == "VIDEO"
                      ? (_videoController != null && _videoController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            )
                          : const CircularProgressIndicator(color: Colors.white))
                      : Image.network(
                          story['media_url'],
                          fit: BoxFit.contain,
                          loadingBuilder: (ctx, child, loading) {
                             if (loading == null) return child;
                             return const Center(child: CircularProgressIndicator(color: Colors.white));
                          },
                          errorBuilder: (ctx, error, stackTrace) {
                            return const Center(child: Icon(Icons.broken_image, color: Colors.white));
                          },
                        ),
                );
              },
            ),
            
            // 2. GRADIENT TOP
            Positioned(
              top: 0, left: 0, right: 0,
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. PROGRESS BARS
            Positioned(
              top: topPadding + 10,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: LinearProgressIndicator(
                        value: index < _currentIndex ? 1.0 : (index == _currentIndex ? _progress : 0.0),
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 2.5,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 4. HEADER (Avatar, Infos, Menu)
            Positioned(
              top: topPadding + 25,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar CORRIGÉ : Logique standard "CircleAvatar avec fallback Icon"
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? const Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (widget.isMine)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'delete') _deleteCurrentStory();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text("Supprimer", style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),

                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // 5. CAPTION
            if (currentStory?['caption'] != null && currentStory!['caption'].toString().isNotEmpty)
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: Text(
                  currentStory['caption'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}