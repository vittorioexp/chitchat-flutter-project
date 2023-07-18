import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CustomImagePicker extends StatefulWidget {
  final String title;
  final bool label;
  final String image;
  final void Function(File pickedImage) onPickImage;

  const CustomImagePicker({
    super.key,
    required this.title,
    required this.label,
    required this.image,
    required this.onPickImage,
  });

  @override
  State<StatefulWidget> createState() {
    return _CustomImagePickerState();
  }
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  File? _pickedImageFile;

  void _pickImage() async {
    final imageSource = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            widget.title,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Take a photo'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Upload from Photos'),
            ),
          ],
        );
      },
    );

    if (imageSource == null) {
      return;
    }

    final pickedImage = await ImagePicker().pickImage(
      source: imageSource,
      imageQuality: 50,
      maxHeight: 150,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _pickedImageFile = File(pickedImage.path);
    });

    widget.onPickImage(_pickedImageFile!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey,
            backgroundImage: _pickedImageFile != null
                ? FileImage(_pickedImageFile!) as ImageProvider
                : AssetImage(widget.image),
          ),
        ),
        if (widget.label)
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: Text(
              widget.title,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          )
      ],
    );
  }
}
