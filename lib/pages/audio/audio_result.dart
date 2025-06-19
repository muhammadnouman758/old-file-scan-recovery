import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import '../../first/shimmer/shimmer.dart';
import '../history/scan_records.dart';
import 'audio_fetcher.dart';
import 'audio_file_page.dart';

class AudioFolderGridApp extends StatefulWidget {
  const AudioFolderGridApp({super.key});

  @override
  State<AudioFolderGridApp> createState() => _AudioFolderGridAppState();
}

class _AudioFolderGridAppState extends State<AudioFolderGridApp>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final AudioFileFetcher _fileFetcher = AudioFileFetcher();
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late AnimationController _textAnimationController;
  bool _scanning = false;
  double _currentProgress = 0.0;
  String _currentPath = "";
  Map<String, Set<File>>? _folders;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _setupListeners();
    _startFetchingAudioFiles();
  }

  void _setupListeners() {
    _fileFetcher.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentProgress = progress;
          _progressAnimation = Tween<double>(
            begin: _progressAnimation.value,
            end: progress / 100,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          );
          _controller.forward(from: 0.0);
        });
      }
    });

    _fileFetcher.currentPathStream.listen((path) {
      if (mounted) {
        setState(() {
          _currentPath = path;
        });
      }
    });

    _fileFetcher.folderStream.listen((folders) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _folders = folders;
          if (folders.isNotEmpty) {
            streamListenerTo(folders, "audio");
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      setState(() {
        _scanning = false;
      });
    }
  }

  void _startFetchingAudioFiles() {
    setState(() {
      _scanning = true;
      _folders = null;
    });
    _fileFetcher.fetchAudioFiles();
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {

        return true;
      },
      child: Scaffold(
        backgroundColor: CusColor.decentWhite,
        appBar: AppBar(
          title: const Text('Audio Folders', style: TextStyle(color: Colors.white)),
          backgroundColor: CusColor.darkBlue3,
          leading: IconButton(
              onPressed: () {
                // Cancel scanning operation before navigation
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white)
          ),
        ),
        body: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: _scanning
              ? const Center(child: VideoScanningAnimation())
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_folders == null) {
      return const Center(child: VideoScanningAnimation());
    }

    if (_folders!.isEmpty) {
      return const Center(child: Text("No audio folders found."));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15.0,
        mainAxisSpacing: 15.0,
      ),
      padding: EdgeInsets.symmetric(horizontal: 25.0.w, vertical: 20.h),
      itemCount: _folders!.keys.length,
      itemBuilder: (context, index) {
        final folderPath = _folders!.keys.elementAt(index);
        final folderName = folderPath.split('/').last;
        final files = _folders![folderPath]!;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioFolderPage(
                    folderName: folderName,
                    audioFiles: files
                ),
              ),
            );
          },
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            decoration: BoxDecoration(
              color: CusColor.darkBlue3,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5.0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder, color: Colors.white, size: 50),
                Text(
                  folderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CusColor.white2,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "${files.length} files",
                  maxLines: 1,
                  style: TextStyle(
                    color: CusColor.white2,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fileFetcher.dispose();
    _controller.dispose();
    _textAnimationController.dispose();
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void streamListenerTo(Map<String, Set<File>> folder, String keyName) async {
    final fileData = [{
      keyName: folder.values.expand((set) => set).toList(),
    }];
    final object = ScanHistoryTransform();
    ScanHistoryTransform.storeFiles(fileData);
  }
}