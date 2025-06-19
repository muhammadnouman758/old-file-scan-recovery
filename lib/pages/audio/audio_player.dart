import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';

class AudioPlayerPage extends StatefulWidget {
  final File audioFile;

  const AudioPlayerPage({super.key, required this.audioFile});

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLooping = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _playPauseController;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _showSpeedControls = false;
  bool _showVolumeControls = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_isLooping) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.resume();
      } else {
        setState(() {
          _isPlaying = false;
          _playPauseController.reverse();
        });
      }
    });

    _audioPlayer.setVolume(_volume);
    _audioPlayer.setPlaybackRate(_playbackSpeed);
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _playPauseController.reverse();
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.audioFile.path));
      _playPauseController.forward();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seekAudio(Duration position) {
    _audioPlayer.seek(position);
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
  }

  void _skipForward() {
    if (_duration.inSeconds > 0) {
      final newPosition = _position + const Duration(seconds: 10);
      _seekAudio(newPosition < _duration ? newPosition : _duration);
    }
  }

  void _skipBackward() {
    if (_duration.inSeconds > 0) {
      final newPosition = _position - const Duration(seconds: 10);
      _seekAudio(newPosition > Duration.zero ? newPosition : Duration.zero);
    }
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value;
    });
    _audioPlayer.setVolume(value);
  }

  void _setPlaybackSpeed(double value) {
    setState(() {
      _playbackSpeed = value;
    });
    _audioPlayer.setPlaybackRate(value);
  }

  String _getAudioFileName() {
    String fullPath = widget.audioFile.path;
    String fileName = fullPath.split('/').last;
    // Truncate if too long
    if (fileName.length > 25) {
      return '${fileName.substring(0, 22)}...';
    }
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CusColor.decentWhite,
      appBar: AppBar(
        backgroundColor: CusColor.darkBlue3,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: CusColor.white2),
        ),
        title: Text(
          _getAudioFileName(),
          style: TextStyle(color: CusColor.white2, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF0F8FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Artwork / Visualization area (60% of screen)
              Expanded(
                flex: 6,
                child: Container(
                  margin: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: CusColor.darkBlue3.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isPlaying ? 150.w : 140.w,
                      height: _isPlaying ? 150.w : 140.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            CusColor.darkBlue3,
                            CusColor.darkBlue3.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: _isPlaying ? 70.sp : 60.sp,
                        color: Colors.white.withOpacity(_isPlaying ? 1.0 : 0.8),
                      ),
                    ),
                  ),
                ),
              ),

              // Controls area (40% of screen)
              Expanded(
                flex: 5,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Time and slider
                      Column(
                        children: [
                          SizedBox(height: 20.h),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4.h,
                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                              activeTrackColor: CusColor.darkBlue3,
                              inactiveTrackColor: Colors.grey.shade200,
                              thumbColor: CusColor.darkBlue3,
                              overlayColor: CusColor.darkBlue3.withOpacity(0.2),
                            ),
                            child: Slider(
                              min: 0,
                              max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                              value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1),
                              onChanged: (value) {
                                _seekAudio(Duration(seconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                Text(
                                  _formatDuration(_duration),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Main controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isLooping ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                              color: _isLooping ? CusColor.darkBlue3 : Colors.grey.shade600,
                              size: 24.sp,
                            ),
                            onPressed: _toggleLoop,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.replay_10_rounded,
                              color: CusColor.darkBlue3,
                              size: 32.sp,
                            ),
                            onPressed: _skipBackward,
                          ),
                          Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  CusColor.darkBlue3,
                                  CusColor.darkBlue3.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CusColor.darkBlue3.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: AnimatedIcon(
                                icon: AnimatedIcons.play_pause,
                                progress: _playPauseController,
                                color: Colors.white,
                                size: 32.sp,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.forward_10_rounded,
                              color: CusColor.darkBlue3,
                              size: 32.sp,
                            ),
                            onPressed: _skipForward,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.speed,
                              color: _showSpeedControls ? CusColor.darkBlue3 : Colors.grey.shade600,
                              size: 24.sp,
                            ),
                            onPressed: () {
                              setState(() {
                                _showSpeedControls = !_showSpeedControls;
                                _showVolumeControls = false;
                              });
                            },
                          ),
                        ],
                      ),

                      // Extended controls (volume or speed)
                      AnimatedCrossFade(
                        firstChild: _buildVolumeControls(),
                        secondChild: _buildSpeedControls(),
                        crossFadeState: _showSpeedControls ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControls() {
    return AnimatedOpacity(
      opacity: _showVolumeControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: _showVolumeControls
          ? SizedBox(
        height: 50.h,
        child: Row(
          children: [
            Icon(
              _volume <= 0 ? Icons.volume_off : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
              color: Colors.grey.shade700,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.h,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                  activeTrackColor: CusColor.darkBlue3,
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: CusColor.darkBlue3,
                ),
                child: Slider(
                  min: 0.0,
                  max: 1.0,
                  value: _volume,
                  onChanged: _setVolume,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.grey.shade700,
                size: 20.sp,
              ),
              onPressed: () {
                setState(() {
                  _showVolumeControls = false;
                });
              },
            ),
          ],
        ),
      )
          : GestureDetector(
        onTap: () {
          setState(() {
            _showVolumeControls = true;
            _showSpeedControls = false;
          });
        },
        child: Container(
          height: 50.h,
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _volume <= 0 ? Icons.volume_off : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
                color: Colors.grey.shade600,
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Volume',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedControls() {
    return SizedBox(
      height: 50.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSpeedButton(0.5),
              _buildSpeedButton(0.75),
              _buildSpeedButton(1.0),
              _buildSpeedButton(1.25),
              _buildSpeedButton(1.5),
              _buildSpeedButton(2.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton(double speed) {
    final isSelected = _playbackSpeed == speed;
    return GestureDetector(
      onTap: () => _setPlaybackSpeed(speed),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? CusColor.darkBlue3 : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? CusColor.darkBlue3 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          '${speed}x',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    if (duration.inHours > 0) {
      String hours = twoDigits(duration.inHours);
      String minutes = twoDigits(duration.inMinutes.remainder(60));
      String seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$hours:$minutes:$seconds";
    } else {
      String minutes = twoDigits(duration.inMinutes);
      String seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playPauseController.dispose();
    super.dispose();
  }
}