import 'dart:io';
import 'dart:async';
import 'package:encrypt/encrypt.dart';

/// Encrypt a file in chunks and write to the output securely
Future<void> secureFileInChunks({
  required File inputFile,
  required Directory outputDir,
  required Encrypter encrypter,
  required IV iv,
  int chunkSize = 10 * 1024 * 1024, // 10 MB chunks
}) async {
  final String fileName = inputFile.uri.pathSegments.last;
  final outputFile = File('${outputDir.path}/$fileName.aes');
  final inputStream = inputFile.openRead();
  final outputSink = outputFile.openWrite();

  try {
    // Process the file in chunks
    await inputStream.listen((chunk) {
      // Encrypt the chunk
      final encrypted = encrypter.encryptBytes(chunk, iv: iv);
      // Write the encrypted bytes to the output file
      outputSink.add(encrypted.bytes);
    }).asFuture(); // Ensure the stream completes

  } catch (e) {
    return;

  } finally {
    await outputSink.close();
  }
}

/// Batch process multiple files
Future<void> batchProcessFiles({
  required List<File> files,
  required Directory outputDir,
  required Encrypter encrypter,
  required IV iv,
}) async {
  for (final file in files) {
    try {
      await secureFileInChunks(
        inputFile: file,
        outputDir: outputDir,
        encrypter: encrypter,
        iv: iv,
      );
    } catch (e){
      return ;
    }
  }
}

/// Example main function
Future<void> main() async {
  // Create an AES key and IV
  final key = Key.fromLength(32); // 256-bit key
  final iv = IV.fromLength(16); // 128-bit IV
  final encrypter = Encrypter(AES(key));

  // Input directory containing files to encrypt
  final inputDir = Directory('input_videos'); // Change this to your directory
  final outputDir = Directory('secured_videos');

  // Ensure the output directory exists
  if (!outputDir.existsSync()) {
    await outputDir.create(recursive: true);
  }

  // Fetch files from input directory
  final files = inputDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.mp4')) // Filter for video files
      .toList();
  // Secure the files in batch
  await batchProcessFiles(
    files: files,
    outputDir: outputDir,
    encrypter: encrypter,
    iv: iv,
  );

}
