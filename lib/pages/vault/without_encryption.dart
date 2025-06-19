
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';

import 'package:path_provider/path_provider.dart';

class VaultProcessWithoutEncryption {
  late Directory _processingDir;
  Future<void> initializeProcessor() async {
    final appDir = await getApplicationDocumentsDirectory();
    _processingDir = Directory('${appDir.path}/vault');
    if (!await _processingDir.exists()) {
      await _processingDir.create(recursive: true);
    }
  }
  Future<bool> copyFileInChunks(File sourceFile) async {
    final fileName = sourceFile.path.split('/').last;
    final destinationFile = File('${_processingDir.path}/$fileName');
    final input = sourceFile.openRead();
    final output = destinationFile.openWrite();

    try {
      const int chunkSize = 128 * 1024; // 128 KB chunks
      await for (final chunk in input.transform(
          StreamTransformer.fromBind(
                  (stream) {
                return stream.map((data) => data.sublist(0, data.length < chunkSize ? data.length : chunkSize));
              }))) {
        output.add(chunk);

      }
    } catch (e) {
      return false;
    } finally {
      await output.close();
      return true;
    }
  }
  Future<String?> generateThumbnail(File videoFile) async {
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 250, // Resize height
      maxWidth: 360,  // Resize width
      quality: 75,    // Thumbnail quality
    );


    return thumbnailPath.path;
  }
  Future<void> processFileWithIsolate(File file) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _processFileInIsolate,
      {
        'filePath': file.path,
        'chunkSize': 128 * 1024, // 128 KB
        'responsePort': receivePort.sendPort,
      },
    );

    final result = await receivePort.first;
    isolate.kill();

    if (result is String) {
    } else {
    }
  }

  static Future<void> _processFileInIsolate(Map<String, dynamic> args) async {
    final filePath = args['filePath'] as String;
    final chunkSize = args['chunkSize'] as int;
    final responsePort = args['responsePort'] as SendPort;

    final sourceFile = File(filePath);
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/${sourceFile.path.split('/').last}';
    final destinationFile = File(tempFilePath);

    final input = sourceFile.openRead();
    final output = destinationFile.openWrite();

    try {
      // Read and write chunks
      await for (final chunk in input) {
        final effectiveChunk = chunk.length < chunkSize
            ? chunk
            : chunk.sublist(0, chunkSize); // Adjust chunk size
        output.add(effectiveChunk); // Write the chunk to the output file
      }
      await output.close();
      responsePort.send(tempFilePath);
      // Send file path back to the main isolate
    } catch (e) {
      responsePort.send(null); // Signal failure
    } finally {
      await output.close();
    }
  }

}