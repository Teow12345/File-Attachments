import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<AttachedFile> attachedFiles = [];
  bool _isLoading = false;
  bool _isPickingDocument = false;
  bool _isImagePickerActive = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_isImagePickerActive) {
      return; // Exit if already picking
    }

    setState(() {
      _isImagePickerActive = true;
    });

    final pickedImage = await ImagePicker().pickImage(source: source);
    if (pickedImage != null) {
      await _processFile(File(pickedImage.path));

      // Save the captured image directly to the photo album
      await ImageGallerySaver.saveFile(pickedImage.path);
    }

    setState(() {
      _isImagePickerActive = false;
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null) {
      final filePath = result.files.single.path!;
      _processFile(File(filePath));

      // Replace with your actual image URL
      String imageUrl = 'https://your-actual-image-url.com/your-image.jpg'; // Can replace with an actual URL you want
      _saveNetworkImage(imageUrl);
    }
  }

  Future<void> _processFile(File file) async {
    setState(() {
      _isLoading = true;
    });

    final compressedFile = await _compressImage(file);
    setState(() {
      attachedFiles.add(AttachedFile(
        name: _addPrefixToFilename(Path.basename(compressedFile.path)),
        path: compressedFile.path,
        size: compressedFile.lengthSync(),
      ));
      _isLoading = false;
    });
  }

  Future<File> _compressImage(File imageFile) async {
    final appDir = await getTemporaryDirectory();
    final targetPath =
    Path.join(appDir.path, 'compressed_${Path.basename(imageFile.path)}');
    final compressedFile = await imageFile.copy(targetPath);
    return compressedFile;
  }

  String _addPrefixToFilename(String originalName) {
    return 'ETMS_$originalName';
  }

  Future<void> _saveNetworkImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final result =
        await ImageGallerySaver.saveImage(Uint8List.fromList(bytes));
        if (result['isSuccess']) {
          print('Image saved to gallery');
        } else {
          print('Failed to save image');
        }
      } else {
        print('Failed to fetch image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching image: $e');
    }
  }

  Future<void> _saveNetworkVideo(String videoUrl) async {
    try {
      final response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final result =
        await ImageGallerySaver.saveImage(Uint8List.fromList(bytes));
        if (result['isSuccess']) {
          print('Video saved to gallery');
        } else {
          print('Failed to save video');
        }
      } else {
        print('Failed to fetch video. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching video: $e');
    }
  }

  void _openAttachment(BuildContext context, String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    if (extension == 'jpg' || extension == 'png') {
      // For JPG and PNG files, show a dialog to ask the user how to open the file.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Open Image File'),
            content: Text('How would you like to open this image file?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  OpenFile.open(filePath); // Use open_file to open the image file
                },
                child: Text('Open with Default App'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Add code here to handle other ways of opening the image file, if needed.
                },
                child: Text('Other Options'),
              ),
            ],
          );
        },
      );
    } else if (extension == 'pdf') {
      // For PDF files, show a dialog to ask the user how to open the file.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Open PDF File'),
            content: Text('How would you like to open this PDF file?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Use your existing code to open PDF files here
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return Scaffold(
                          appBar: AppBar(title: Text('PDF Preview')),
                          body: PDFView(
                            filePath: filePath,
                            enableSwipe: true,
                            swipeHorizontal: true,
                            autoSpacing: false,
                            pageSnap: true,
                          ),
                        );
                      },
                    ),
                  );
                },
                child: Text('Open with Default PDF Viewer'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Add code here to handle other ways of opening the PDF file, if needed.
                },
                child: Text('Other Options'),
              ),
            ],
          );
        },
      );
    } else {
      // For other file types, show a dialog for the user to choose how to open the file.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Open File'),
            content: Text('How would you like to open this file?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  OpenFile.open(filePath); // Use open_file to open the file
                },
                child: Text('Open with Default App'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Add code here to handle other ways of opening the file, if needed.
                },
                child: Text('Other Options'),
              ),
            ],
          );
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('File Attachments')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'User able to add files:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: Text('Camera'),
            leading: Icon(Icons.camera_alt),
            onTap: () => _pickImage(ImageSource.camera),
          ),
          ListTile(
            title: Text('Photo Album'),
            leading: Icon(Icons.photo),
            onTap: () => _pickImage(ImageSource.gallery), // Use ImageSource.gallery
          ),
          ListTile(
            title: Text('Document'),
            leading: Icon(Icons.description),
            onTap: _pickDocument,
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Attached Files:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: attachedFiles.length,
              itemBuilder: (context, index) {
                final file = attachedFiles[index];
                return ListTile(
                  title: Text(file.name),
                  subtitle: Text('${_formatFileSize(file.size)}'),
                  onTap: () => _openAttachment(context, file.path),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / 1048576).toStringAsFixed(2)} MB';
  }
}

class AttachedFile {
  final String name;
  final String path;
  final int size;

  AttachedFile({required this.name, required this.path, required this.size});
}
