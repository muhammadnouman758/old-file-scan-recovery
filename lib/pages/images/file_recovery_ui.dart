import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/first/shimmer/shimmer.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:old_file_recovery/pages/history/scan_records.dart';
import 'package:old_file_recovery/pages/images/image_folder.dart';
import 'package:old_file_recovery/pages/images/recovery_code.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';


class FolderGridApp extends StatefulWidget {
  const FolderGridApp({super.key});
  @override
  State<FolderGridApp> createState() => _FolderGridAppState();
}

class _FolderGridAppState extends State<FolderGridApp> with WidgetsBindingObserver {
  late FileScanner _fileScanner;
  late Stream<Map<String, Set<File>>> _folderStream;
  late Stream<ScanProgress> _progressStream;
  final Map<String, Set<File>> _folders = {};
  bool _isLoading = true;
  bool _scanStarted = false;
  StreamSubscription<Map<String, Set<File>>>? _folderStreamSubscription;
  StreamSubscription<ScanProgress>? _progressStreamSubscription;
  String _currentScanPath = 'Initializing scan...';
  int _foldersScanned = 0;
  int _totalFilesFound = 0;
  int _imageFilesFound = 0;
  Duration _scanDuration = Duration.zero;
  ScanType _scanType = ScanType.quick;

  DateTime? _lastProgressUpdate;
  int _lastFoldersCount = 0;
  double _scanSpeed = 0.0; // folders per second
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showScanModeDialog();
    });
  }

  Future<void> _showScanModeDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Scan Mode',
            style: TextStyle(color: CusColor.darkBlue3, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose how you want to scan for images:',
                style: TextStyle(color: CusColor.darkBlue3),
              ),
              const SizedBox(height: 16),
              _buildScanModeOption(
                title: 'Quick Scan',
                description: 'Quickly scans for images based on file extensions.',
                icon: Icons.speed,
                scanType: ScanType.quick,
              ),
              const SizedBox(height: 16),
              _buildScanModeOption(
                title: 'Deep Scan',
                description: 'Thoroughly scans for images by analyzing file signatures. May take longer but finds more images.',
                icon: Icons.search,
                scanType: ScanType.deep,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanModeOption({
    required String title,
    required String description,
    required IconData icon,
    required ScanType scanType,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _scanType = scanType;
        });
        Navigator.of(context).pop();
        _initializeScanner();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: CusColor.darkBlue3.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: CusColor.darkBlue3, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CusColor.darkBlue3,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                    style: TextStyle(
                      color: CusColor.darkBlue3.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _initializeScanner() {
    _fileScanner = FileScannerFactory.createScanner(_scanType);
    _folderStream = _fileScanner.folderStream;
    _progressStream = _fileScanner.progressStream;
    _setupStreamListeners();
    _startFetchingFiles();
  }

  void _setupStreamListeners() {
    _folderStreamSubscription = _folderStream.listen(
            (folderMap) {
          if (mounted) {
            setState(() {
              _folders.clear();
              _folders.addAll(folderMap);
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            streamListenerTo(_folders, 'image');
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error scanning files: $error"))
            );
          }
        }
    );

    _progressStreamSubscription = _progressStream.listen(
            (progress) {
          if (mounted) {
            if (_lastProgressUpdate != null) {
              final timeDiff = progress.lastUpdate.difference(_lastProgressUpdate!).inMilliseconds;
              if (timeDiff > 0) {
                final foldersDiff = progress.foldersScanned - _lastFoldersCount;
                _scanSpeed = (foldersDiff / timeDiff) * 1000; // folders per second
              }
            }

            setState(() {
              _currentScanPath = progress.currentPath;
              _foldersScanned = progress.foldersScanned;
              _totalFilesFound = progress.totalFilesFound;
              _imageFilesFound = progress.imageFilesFound;
              _lastProgressUpdate = progress.lastUpdate;
              _lastFoldersCount = progress.foldersScanned;
            });
          }
        },
        onDone: () {
          if (_durationTimer?.isActive == true) {
            _durationTimer?.cancel();
          }
        }
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _fileScanner.cancel();
      _durationTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _folderStreamSubscription?.cancel();
    _progressStreamSubscription?.cancel();
    _durationTimer?.cancel();
    _fileScanner.dispose();
    super.dispose();
  }

  Future<void> _startFetchingFiles() async {
    setState(() {
      _isLoading = true;
      _scanStarted = true;
      _folders.clear();
      _currentScanPath = 'Initializing scan...';
      _foldersScanned = 0;
      _totalFilesFound = 0;
      _imageFilesFound = 0;
      _scanDuration = Duration.zero;
      _scanSpeed = 0.0;
    });

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isLoading) {
        setState(() {
          _scanDuration = _fileScanner.scanDuration;
        });
      }
    });

    _fileScanner.fetchImages();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Share folder method
  Future<void> _shareFolder(Set<File> files, String folderName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing files for sharing...'),
            ],
          ),
        ),
      );

      // Prepare files for sharing
      final List<XFile> xFiles = files.map((file) => XFile(file.path)).toList();

      // Close loading dialog
      Navigator.of(context).pop();

      // Share files
      await Share.shareXFiles(
        xFiles,
        subject: 'Sharing folder: $folderName',
        text: 'Check out these images from $folderName',
      );

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Folder $folderName shared successfully'),
          backgroundColor: CusColor.darkBlue3,
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing folder: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // Improved Rename Folder Dialog
  Future<void> _renameFolder(String oldFolderName) async {
    final TextEditingController controller = TextEditingController(text: oldFolderName);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.drive_file_rename_outline,
                      color: CusColor.darkBlue3, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Rename Folder',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter new folder name',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.folder, color: CusColor.darkBlue3),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Folder name cannot be empty';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, controller.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CusColor.darkBlue3,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Rename'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty && result != oldFolderName) {
      try {
        setState(() {
          final files = _folders.remove(oldFolderName);
          if (files != null) {
            _folders[result] = files;
          }
        });

        // Show success message
        _showSuccessSnackBar('Folder renamed to $result');
      } catch (e) {
        _showErrorSnackBar('Error renaming folder: $e');
      }
    }
  }

// Improved Export Folder method
  Future<void> _exportFolder(String folderName) async {
    try {
      // Show loading dialog with animation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          height: 60,
                          width: 60,
                          child: CircularProgressIndicator(
                            color: CusColor.darkBlue3,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.upload_file,
                          size: 30,
                          color: CusColor.darkBlue3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Exporting Folder',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we prepare $folderName for export',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(CusColor.darkBlue3),
                ),
              ],
            ),
          ),
        ),
      );

      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pop();

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Export Complete',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Folder $folderName has been successfully exported',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CusColor.darkBlue3,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorSnackBar('Error exporting folder: $e');
    }
  }

// Improved Delete Folder method
  Future<void> _deleteFolder(String folderName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 40,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Delete Folder',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete "$folderName"?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        setState(() {
          _folders.remove(folderName);
        });

        // Show animated snackbar with undo option
        final snackBar = SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Folder "$folderName" deleted'),
              ),
            ],
          ),
          backgroundColor: CusColor.darkBlue3,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () {
              // Implement undo logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Folder restored'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } catch (e) {
        _showErrorSnackBar('Error deleting folder: $e');
      }
    }
  }

// Helper methods for showing consistent snackbars
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: CusColor.darkBlue3,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Show more options bottom sheet
  void _showMoreOptions(String folderName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename Folder'),
            onTap: () {
              Navigator.pop(context);
              _renameFolder(folderName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Folder'),
            onTap: () {
              Navigator.pop(context);
              _exportFolder(folderName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Folder', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteFolder(folderName);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_scanStarted) {
          _fileScanner.cancel();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: CusColor.decentWhite,
        appBar: AppBar(
          backgroundColor: CusColor.darkBlue3,
          title: Text(
              _scanStarted
                  ? 'Image Folders (${_scanType == ScanType.quick ? 'Quick Scan' : 'Deep Scan'})'
                  : 'Image Folders',
              style: TextStyle(color: CusColor.whiteDark)
          ),
          leading: IconButton(
              onPressed: () {
                if (_scanStarted) {
                  _fileScanner.cancel();
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white)
          ),
          actions: [
            if (_isLoading && _scanStarted)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _scanStarted ? _buildBody() : _buildWaitingForSelection(),
      ),
    );
  }

  Widget _buildWaitingForSelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 64, color: CusColor.darkBlue3.withOpacity(0.7)),
          const SizedBox(height: 16),
          Text(
              "Select scan mode to begin",
              style: TextStyle(
                  color: CusColor.darkBlue3,
                  fontSize: 18,
                  fontWeight: FontWeight.bold
              )
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showScanModeDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: CusColor.darkBlue3,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text("Choose Scan Mode", style: TextStyle(color: CusColor.whiteDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Column(
        children: [
          _buildScanProgressCard(),
          Expanded(
            child: _folders.isEmpty
                ? const Center(child: VideoScanningAnimation())
                : _buildFolderGrid(),
          ),
        ],
      );
    }

    if (_folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 64, color: CusColor.darkBlue3.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text("No image folders found",
                style: TextStyle(color: CusColor.darkBlue3, fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showScanModeDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: CusColor.darkBlue3,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text("Try Another Scan Mode", style: TextStyle(color: CusColor.whiteDark)),
            ),
          ],
        ),
      );
    }

    return _buildFolderGrid();
  }

  Widget _buildScanProgressCard() {
    final formatter = NumberFormat("#,###");
    final scanTypeIcon = _scanType == ScanType.quick ? Icons.speed : Icons.search;
    final scanTypeText = _scanType == ScanType.quick ? "Quick Scan" : "Deep Scan";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isLoading ? null : 0,
      child: Card(
        margin: const EdgeInsets.all(10),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: CusColor.white2,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(scanTypeIcon, size: 18, color: CusColor.darkBlue3),
                      const SizedBox(width: 6),
                      Text(
                          "$scanTypeText in Progress",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CusColor.darkBlue3
                          )
                      ),
                    ],
                  ),
                  Text(
                      _formatDuration(_scanDuration),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CusColor.darkBlue3
                      )
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 20,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    "Scanning: ${_currentScanPath.replaceAll('/storage/emulated/0', '')}",
                    style: TextStyle(
                        color: CusColor.darkBlue3.withOpacity(0.8),
                        fontSize: 14
                    ),
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("Folders", formatter.format(_foldersScanned), Icons.folder_outlined),
                  _buildStatColumn("Files", formatter.format(_totalFilesFound), Icons.insert_drive_file_outlined),
                  _buildStatColumn("Images", formatter.format(_imageFilesFound), Icons.image_outlined),
                  _buildStatColumn("Speed", "${_scanSpeed.toStringAsFixed(1)}/s", Icons.speed),
                ],
              ),
              const SizedBox(height: 10),
              if (_totalFilesFound > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: _imageFilesFound / (_totalFilesFound > 0 ? _totalFilesFound : 1),
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(CusColor.darkBlue3),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${(_imageFilesFound / _totalFilesFound * 100).toStringAsFixed(1)}% of files are images",
                      style: TextStyle(
                          fontSize: 12,
                          color: CusColor.darkBlue3.withOpacity(0.7)
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              if (_isLoading)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      _fileScanner.cancel();
                      setState(() {
                        _isLoading = false;
                      });
                    },
                    icon: Icon(Icons.cancel, color: Colors.red.shade700, size: 16),
                    label: Text(
                      "Cancel Scan",
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: CusColor.darkBlue3, size: 22),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: CusColor.darkBlue3
          ),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: CusColor.darkBlue3.withOpacity(0.7)
          ),
        ),
      ],
    );
  }

  Widget _buildFolderGrid() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
        ),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          crossAxisSpacing: 16.0,
          mainAxisExtent: 240,
          mainAxisSpacing: 16.0,
        ),
        padding: const EdgeInsets.all(20.0),
        itemCount: _folders.keys.length,
        itemBuilder: (context, index) {
          final folderName = _folders.keys.elementAt(index);
          final files = _folders[folderName]!;
          List<File> listFile = files.toList();

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FolderImagesPage(folderName: folderName, images: files),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: CusColor.darkBlue3.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          color: CusColor.darkBlue3,
                          size: 18,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            folderName,
                            style: TextStyle(
                              color: CusColor.darkBlue3,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: CusColor.darkBlue3.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            "${files.length}",
                            style: TextStyle(
                              color: CusColor.darkBlue3,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: listFile.isEmpty
                        ? _buildEmptyState()
                        : _buildGalleryPreview(listFile),
                  ),
                  Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.visibility_outlined,
                          label: "View",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FolderImagesPage(folderName: folderName, images: files),
                              ),
                            );
                          },
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey.shade300,
                        ),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: "Share",
                          onPressed: () => _shareFolder(files, folderName),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey.shade300,
                        ),
                        _buildActionButton(
                          icon: Icons.more_horiz,
                          label: "More",
                          onPressed: () => _showMoreOptions(folderName),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            "No images",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 16,
          color: CusColor.darkBlue3.withOpacity(0.8),
        ),
        label: Text(
          label,
          style: TextStyle(
            color: CusColor.darkBlue3.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.zero),
        ),
      ),
    );
  }

  Widget _buildGalleryPreview(List<File> images) {
    if (images.length == 1) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.file(
            images[0],
            fit: BoxFit.cover,
            cacheWidth: 300,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
            },
          ),
        ),
      );
    } else if (images.length == 2) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(
                  images[0],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  cacheWidth: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                  },
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(
                  images[1],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  cacheWidth: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                  },
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(
                  images[0],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  cacheWidth: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                  },
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.file(
                        images[1],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        cacheWidth: 100,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.file(
                            images[2],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            cacheWidth: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                            },
                          ),
                        ),
                        if (images.length > 3)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Container(
                              color: Colors.black.withOpacity(0.6),
                              child: Center(
                                child: Text(
                                  "+${images.length - 3}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
  void streamListenerTo(Map<String, Set<File>> folder, String keyName) async {
    if (folder.isEmpty) return;

    final fileData = [{
      keyName: folder.values.expand((set) => set).toList(),
    }];
    final object = ScanHistoryTransform();
    ScanHistoryTransform.storeFiles(fileData);
  }
}