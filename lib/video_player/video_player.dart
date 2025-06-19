import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

enum AspectRatio {
  original,
  ratio16x9,
  ratio4x3,
  ratio21x9,
  ratio1x1,
  stretch,
  fitWidth,
  fitHeight
}

extension AspectRatioExtension on AspectRatio {
  String get label {
    switch (this) {
      case AspectRatio.original:
        return 'Original';
      case AspectRatio.ratio16x9:
        return '16:9';
      case AspectRatio.ratio4x3:
        return '4:3';
      case AspectRatio.ratio21x9:
        return '21:9';
      case AspectRatio.ratio1x1:
        return '1:1';
      case AspectRatio.stretch:
        return 'Stretch';
      case AspectRatio.fitWidth:
        return 'Fit Width';
      case AspectRatio.fitHeight:
        return 'Fit Height';
    }
  }

  double? get value {
    switch (this) {
      case AspectRatio.original:
        return null;
      case AspectRatio.ratio16x9:
        return 16 / 9;
      case AspectRatio.ratio4x3:
        return 4 / 3;
      case AspectRatio.ratio21x9:
        return 21 / 9;
      case AspectRatio.ratio1x1:
        return 1;
      case AspectRatio.stretch:
        return null;
      case AspectRatio.fitWidth:
        return null;
      case AspectRatio.fitHeight:
        return null;
    }
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isFullscreen = false;
  bool _showControls = true;
  Timer? _controlsTimer;
  double _volume = 1.0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isVolumeControlVisible = false;
  bool _isBrightnessControlVisible = false;
  double _brightness = 0.5;
  bool _isSeekingActive = false;
  Duration _seekPosition = Duration.zero;
  bool _isLocked = false;
  bool _isLooping = false; // Added for loop feature

  AspectRatio _currentAspectRatio = AspectRatio.original;
  double? _originalAspectRatio;
  bool _isAspectRatioMenuVisible = false;

  final Color _primaryColor = Colors.blue;
  final Color _accentColor = Colors.lightBlueAccent;
  final Color _backgroundColor = Colors.black;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
    _configureSystemUI();
  }

  void _configureSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent
      ),
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final file = File(widget.videoUrl);
      if (!file.existsSync()) {
        throw Exception('Video file not found at ${widget.videoUrl}');
      }

      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController.initialize();
      await _videoPlayerController.setVolume(_volume);
      final videoWidth = _videoPlayerController.value.size.width;
      final videoHeight = _videoPlayerController.value.size.height;
      if (videoWidth > 0 && videoHeight > 0) {
        _originalAspectRatio = videoWidth / videoHeight;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: _isLooping, // Updated to use loop state
        allowFullScreen: true,
        allowMuting: true,
        showControls: false,
        aspectRatio: _getAspectRatioValue(),
        materialProgressColors: ChewieProgressColors(
          playedColor: _primaryColor,
          handleColor: _accentColor,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.grey.shade600,
        ),
        placeholder: Container(
          color: _backgroundColor,
          child: Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
              strokeWidth: 3,
            ),
          ),
        ),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) => Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      _videoPlayerController.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _startControlsTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  double? _getAspectRatioValue() {
    switch (_currentAspectRatio) {
      case AspectRatio.original:
        return _originalAspectRatio;
      case AspectRatio.stretch:
        final size = MediaQuery.of(context).size;
        return size.width / size.height;
      case AspectRatio.fitWidth:
      case AspectRatio.fitHeight:
        return _originalAspectRatio;
      default:
        return _currentAspectRatio.value;
    }
  }

  void _updateAspectRatio(AspectRatio ratio) {
    setState(() {
      _currentAspectRatio = ratio;
      if (_chewieController != null) {
        final wasPlaying = _videoPlayerController.value.isPlaying;
        final position = _videoPlayerController.value.position;

        _chewieController!.dispose();
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: wasPlaying,
          looping: _isLooping, // Maintain loop state
          allowFullScreen: true,
          allowMuting: true,
          showControls: false,
          aspectRatio: _getAspectRatioValue(),
          materialProgressColors: ChewieProgressColors(
            playedColor: _primaryColor,
            handleColor: _accentColor,
            backgroundColor: Colors.grey.shade800,
            bufferedColor: Colors.grey.shade600,
          ),
          placeholder: Container(
            color: _backgroundColor,
            child: Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 3,
              ),
            ),
          ),
          autoInitialize: true,
        );

        _videoPlayerController.seekTo(position);
        if (wasPlaying) {
          _videoPlayerController.play();
        }
      }
      _isAspectRatioMenuVisible = false;
    });
  }

  void _videoListener() {
    if (_videoPlayerController.value.isBuffering) {
      if (mounted) setState(() {});
    }

    if (_videoPlayerController.value.isPlaying && _showControls) {
      _startControlsTimer();
    }

    if (!_isSeekingActive && mounted) {
      setState(() {
        _seekPosition = _videoPlayerController.value.position;
      });
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _showControls = false;
        _controlsTimer?.cancel();
      } else {
        _showControls = true;
        _startControlsTimer();
      }
    });
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
      _videoPlayerController.setLooping(_isLooping);
      if (_chewieController != null) {
        final wasPlaying = _videoPlayerController.value.isPlaying;
        final position = _videoPlayerController.value.position;

        _chewieController!.dispose();
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: wasPlaying,
          looping: _isLooping,
          allowFullScreen: true,
          draggableProgressBar: true,
          showControls: false,
          aspectRatio: _getAspectRatioValue(),
          materialProgressColors: ChewieProgressColors(
            playedColor: _primaryColor,
            handleColor: _accentColor,
            backgroundColor: Colors.grey.shade800,
            bufferedColor: Colors.grey.shade600,
          ),
          placeholder: Container(
            color: _backgroundColor,
            child: Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 3,
              ),
            ),
          ),
          autoInitialize: true,
        );

        _videoPlayerController.seekTo(position);
        if (wasPlaying) {
          _videoPlayerController.play();
        }
      }
    });
  }

  void _changePlaybackSpeed(BuildContext context) {
    final List<double> speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentSpeed = _videoPlayerController.value.playbackSpeed;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Playback Speed',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const Divider(color: Colors.grey, height: 1),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: speeds.length,
                itemBuilder: (context, index) {
                  final speed = speeds[index];
                  final isSelected = currentSpeed == speed;
                  return ListTile(
                    tileColor: isSelected ? _primaryColor.withOpacity(0.2) : null,
                    title: Text('${speed}x',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        )),
                    trailing: isSelected
                        ? Icon(Icons.check, color: _primaryColor)
                        : null,
                    onTap: () {
                      _videoPlayerController.setPlaybackSpeed(speed);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAspectRatioMenu(BuildContext context) {
    const aspectRatios = AspectRatio.values;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aspect Ratio',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const Divider(color: Colors.grey, height: 1),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: aspectRatios.length,
                itemBuilder: (context, index) {
                  final ratio = aspectRatios[index];
                  final isSelected = _currentAspectRatio == ratio;
                  return ListTile(
                    tileColor: isSelected ? _primaryColor.withOpacity(0.2) : null,
                    title: Text(ratio.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        )),
                    trailing: isSelected
                        ? Icon(Icons.check, color: _primaryColor)
                        : null,
                    onTap: () {
                      _updateAspectRatio(ratio);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleControlsVisibility() {
    if (!_isLocked) {
      setState(() => _showControls = !_showControls);
      if (_showControls) {
        _startControlsTimer();
      } else {
        _controlsTimer?.cancel();
      }
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls && _videoPlayerController.value.isPlaying && !_isLocked) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _videoPlayerController.removeListener(_videoListener);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,overlays: []);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoPlayerController.pause();
    }
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    if (!_isLocked && !_isSeekingActive) {
      setState(() {
        _isSeekingActive = true;
        _seekPosition = _videoPlayerController.value.position;
      });

      if (_videoPlayerController.value.isPlaying) {
        _videoPlayerController.pause();
      }

      if (!_showControls) {
        setState(() => _showControls = true);
        _controlsTimer?.cancel();
      }
    }
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isSeekingActive && !_isLocked) {
      final screenWidth = MediaQuery.of(context).size.width;
      final dragDistance = details.primaryDelta ?? 0;
      final percentageMoved = dragDistance / screenWidth;
      final videoDuration = _videoPlayerController.value.duration.inMilliseconds;
      final seekAmount = (percentageMoved * videoDuration * 0.5).round();

      final currentPosition = _seekPosition.inMilliseconds;
      final newPosition = currentPosition + seekAmount;
      final clampedPosition = newPosition.clamp(0, videoDuration);

      setState(() {
        _seekPosition = Duration(milliseconds: clampedPosition);
      });
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isSeekingActive && !_isLocked) {
      _videoPlayerController.seekTo(_seekPosition);

      if (_videoPlayerController.value.isPlaying) {
        _videoPlayerController.play();
      }

      setState(() {
        _isSeekingActive = false;
      });

      _startControlsTimer();
    }
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    if (!_isLocked) {
      final isRightSide = details.globalPosition.dx > MediaQuery.of(context).size.width / 2;

      setState(() {
        _isVolumeControlVisible = isRightSide;
        _isBrightnessControlVisible = !isRightSide;
      });

      if (!_showControls) {
        setState(() => _showControls = true);
        _controlsTimer?.cancel();
      }
    }
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isLocked) {
      if (_isVolumeControlVisible) {
        final volumeChange = -(details.primaryDelta ?? 0) / 300;
        setState(() {
          _volume = (_volume + volumeChange).clamp(0.0, 1.0);
          _videoPlayerController.setVolume(_volume);
        });
      } else if (_isBrightnessControlVisible) {
        final brightnessChange = -(details.primaryDelta ?? 0) / 300;
        setState(() {
          _brightness = (_brightness + brightnessChange).clamp(0.0, 1.0);
        });
      }
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (!_isLocked) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isVolumeControlVisible = false;
            _isBrightnessControlVisible = false;
          });
        }
      });

      _startControlsTimer();
    }
  }

  void _seekForward() {
    if (!_isLocked) {
      final currentPosition = _videoPlayerController.value.position;
      final duration = _videoPlayerController.value.duration;
      final newPosition = currentPosition + const Duration(seconds: 10);

      if (newPosition < duration) {
        _videoPlayerController.seekTo(newPosition);
      } else {
        _videoPlayerController.seekTo(duration);
      }

      if (!_showControls) {
        setState(() => _showControls = true);
        _startControlsTimer();
      }
    }
  }

  void _seekBackward() {
    if (!_isLocked) {
      final currentPosition = _videoPlayerController.value.position;
      final newPosition = currentPosition - const Duration(seconds: 10);

      if (newPosition.inSeconds > 0) {
        _videoPlayerController.seekTo(newPosition);
      } else {
        _videoPlayerController.seekTo(Duration.zero);
      }

      if (!_showControls) {
        setState(() => _showControls = true);
        _startControlsTimer();
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Loading video...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.5), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Error playing video',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _initializePlayer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController == null) {
      return const Center(
        child: Text('Unable to load video player',
            style: TextStyle(color: Colors.white)),
      );
    }

    return GestureDetector(
      onTap: _toggleControlsVisibility,
      onDoubleTapDown: (details) {
        if (_isLocked) return;
        final screenWidth = MediaQuery.of(context).size.width;
        final tapPosition = details.globalPosition.dx;

        if (tapPosition < screenWidth / 3) {
          _seekBackward();
        } else if (tapPosition > (screenWidth * 2 / 3)) {
          _seekForward();
        } else {
          setState(() {
            if (_videoPlayerController.value.isPlaying) {
              _videoPlayerController.pause();
            } else {
              _videoPlayerController.play();
              _startControlsTimer();
            }
          });
        }
      },
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onVerticalDragStart: _handleVerticalDragStart,
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      onVerticalDragEnd: _handleVerticalDragEnd,
      child: _buildVideoWithAspectRatio(),
    );
  }

  Widget _buildVideoWithAspectRatio() {
    if (_currentAspectRatio == AspectRatio.stretch) {
      return Container(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: _videoPlayerController.value.size.width,
                  height: _videoPlayerController.value.size.height,
                  child: Chewie(controller: _chewieController!),
                ),
              ),
            ),
            _buildOverlays(),
          ],
        ),
      );
    } else if (_currentAspectRatio == AspectRatio.fitWidth) {
      return Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: _videoPlayerController.value.size.height,
                child: Chewie(controller: _chewieController!),
              ),
            ),
          ),
          _buildOverlays(),
        ],
      );
    } else if (_currentAspectRatio == AspectRatio.fitHeight) {
      return Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: SizedBox(
                width: _videoPlayerController.value.size.width,
                height: _videoPlayerController.value.size.height,
                child: Chewie(controller: _chewieController!),
              ),
            ),
          ),
          _buildOverlays(),
        ],
      );
    } else {
      return Stack(
        children: [
          Chewie(controller: _chewieController!),
          _buildOverlays(),
        ],
      );
    }
  }

  Widget _buildOverlays() {
    return Stack(
      children: [
        if (_videoPlayerController.value.isBuffering)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 3,
              ),
            ),
          ),

        if (_isVolumeControlVisible && !_isLocked)
          Positioned(
            right: 24,
            top: 0,
            bottom: 0,
            child: Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _volume == 0
                        ? Icons.volume_off
                        : _volume > 0.5
                        ? Icons.volume_up
                        : Icons.volume_down,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 120 * _volume,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_volume * 100).round()}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        if (_isBrightnessControlVisible && !_isLocked)
          Positioned(
            left: 24,
            top: 0,
            bottom: 0,
            child: Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.brightness_6,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 120 * _brightness,
                          child: Container(
                            decoration: BoxDecoration(
                              color: CusColor.darkBlue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_brightness * 100).round()}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        if (_isSeekingActive && !_isLocked)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fast_rewind, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_seekPosition),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.fast_forward, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(_seekPosition),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Text(' / ', style: TextStyle(color: Colors.white70)),
                      Text(
                        _formatDuration(_videoPlayerController.value.duration),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        if (_showControls || _isLocked)
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
              child: _isLocked
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.lock, color: Colors.white, size: 20),
                    onPressed: _toggleLock,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap to unlock',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ],
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            path.basename(widget.title),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isLocked ? Icons.lock : Icons.lock_open,
                            color: Colors.white,
                          ),
                          onPressed: _toggleLock,
                        ),
                      ],
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(
                          Icons.replay_10,
                          color: Colors.white,
                        ),
                        onPressed: _seekBackward,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: const EdgeInsets.all(8),
                          iconSize: 48,
                          icon: Icon(
                            _videoPlayerController.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_videoPlayerController.value.isPlaying) {
                                _videoPlayerController.pause();
                              } else {
                                _videoPlayerController.play();
                                _startControlsTimer();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(
                          Icons.forward_10,
                          color: Colors.white,
                        ),
                        onPressed: _seekForward,
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: _primaryColor,
                            inactiveTrackColor: Colors.grey.shade700,
                            thumbColor: _accentColor,
                            overlayColor: _accentColor.withOpacity(0.3),
                          ),
                          child: Slider(
                            value: _seekPosition.inMilliseconds.toDouble(),
                            min: 0.0,
                            max: _videoPlayerController.value.duration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              setState(() {
                                _seekPosition = Duration(milliseconds: value.toInt());
                              });
                            },
                            onChangeStart: (_) {
                              if (_videoPlayerController.value.isPlaying) {
                                _videoPlayerController.pause();
                              }
                              _controlsTimer?.cancel();
                            },
                            onChangeEnd: (value) {
                              _videoPlayerController.seekTo(Duration(milliseconds: value.toInt()));
                              if (_videoPlayerController.value.isPlaying) {
                                _videoPlayerController.play();
                                _startControlsTimer();
                              }
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_seekPosition),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _videoPlayerController.value.volume > 0
                                        ? Icons.volume_up
                                        : Icons.volume_off,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_videoPlayerController.value.volume > 0) {
                                        _volume = 0;
                                      } else {
                                        _volume = 1.0;
                                      }
                                      _videoPlayerController.setVolume(_volume);
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isLooping ? Icons.repeat_one : Icons.repeat,
                                    color: _isLooping ? _primaryColor : Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _toggleLoop,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.rocket_launch,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () => _changePlaybackSpeed(context),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.width_full_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () => _showAspectRatioMenu(context),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isFullscreen
                                        ? Icons.screen_rotation_alt
                                        : Icons.screen_rotation,
                                    color: Colors.white,
                                  ),
                                  onPressed: _toggleFullscreen,
                                ),
                                Text(
                                  _formatDuration(_videoPlayerController.value.duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(1, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}