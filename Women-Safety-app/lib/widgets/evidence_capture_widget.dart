import 'package:flutter/material.dart';
import 'package:title_proj/services/firebase_evidence_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Evidence Capture Widget
/// Shows dialog to capture evidence after emergency
class EvidenceCaptureWidget extends StatefulWidget {
  final String incidentId;
  final String? description;

  const EvidenceCaptureWidget({
    Key? key,
    required this.incidentId,
    this.description,
  }) : super(key: key);

  @override
  State<EvidenceCaptureWidget> createState() => _EvidenceCaptureWidgetState();
}

class _EvidenceCaptureWidgetState extends State<EvidenceCaptureWidget> {
  final FirebaseEvidenceService _evidenceService = FirebaseEvidenceService();
  bool _uploading = false;
  String? _uploadStatus;

  Future<void> _captureEvidence(ImageSource source) async {
    setState(() {
      _uploading = true;
      _uploadStatus = 'Capturing...';
    });

    try {
      final evidence = await _evidenceService.storeEvidence(
        incidentId: widget.incidentId,
        description: widget.description ?? 'Emergency evidence',
        source: source,
      );

      setState(() {
        _uploading = false;
        _uploadStatus = 'Success!';
      });

      Fluttertoast.showToast(
        msg: '✅ Evidence stored securely\nHash: ${evidence.fileHash.substring(0, 16)}...',
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );

      // Close dialog after short delay
      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _uploadStatus = 'Error';
      });

      Fluttertoast.showToast(
        msg: 'Failed to store evidence: $e',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.camera_alt, color: Colors.pink),
          SizedBox(width: 8),
          Text('Capture Evidence'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Would you like to capture evidence (photo/video) for this emergency?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 20),
          if (_uploading)
            Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  _uploadStatus ?? 'Processing...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _captureEvidence(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _captureEvidence(ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _uploading ? null : () => Navigator.of(context).pop(false),
          child: Text('Skip'),
        ),
      ],
    );
  }
}

/// Show evidence capture dialog
Future<bool?> showEvidenceCaptureDialog(
  BuildContext context, {
  required String incidentId,
  String? description,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => EvidenceCaptureWidget(
      incidentId: incidentId,
      description: description,
    ),
  );
}

