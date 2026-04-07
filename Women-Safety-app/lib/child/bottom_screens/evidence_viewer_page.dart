import 'package:flutter/material.dart';
import 'package:title_proj/services/firebase_evidence_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Evidence Viewer Page
/// Shows all evidence for a specific incident
class EvidenceViewerPage extends StatefulWidget {
  final String incidentId;

  const EvidenceViewerPage({
    Key? key,
    required this.incidentId,
  }) : super(key: key);

  @override
  State<EvidenceViewerPage> createState() => _EvidenceViewerPageState();
}

class _EvidenceViewerPageState extends State<EvidenceViewerPage> {
  final FirebaseEvidenceService _evidenceService = FirebaseEvidenceService();
  List<EvidenceRecord> _evidenceList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  Future<void> _loadEvidence() async {
    setState(() => _loading = true);
    try {
      final evidence = await _evidenceService.getIncidentEvidence(widget.incidentId);
      setState(() {
        _evidenceList = evidence;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Fluttertoast.showToast(
        msg: 'Error loading evidence: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _verifyEvidence(EvidenceRecord evidence) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final verified = await _evidenceService.verifyEvidence(
        evidence.fileHash,
        evidence.downloadUrl,
      );

      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(verified ? '✅ Verified' : '❌ Verification Failed'),
          content: Text(
            verified
                ? 'Evidence integrity verified. File has not been tampered with.'
                : 'Evidence verification failed. File may have been modified.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      Fluttertoast.showToast(
        msg: 'Verification error: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evidence'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEvidence,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _evidenceList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No evidence captured',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _evidenceList.length,
                  itemBuilder: (context, index) {
                    final evidence = _evidenceList[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image/Video Preview
                          if (evidence.fileType == 'image')
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                              child: CachedNetworkImage(
                                imageUrl: evidence.downloadUrl,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.error, size: 48, color: Colors.red),
                                ),
                              ),
                            ),
                          // Details
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.description, size: 20, color: Colors.pink),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        evidence.fileName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                if (evidence.description != null)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Text(evidence.description!),
                                  ),
                                Divider(),
                                _buildInfoRow('Type', evidence.fileType.toUpperCase()),
                                _buildInfoRow('Size', '${(evidence.fileSize / 1024).toStringAsFixed(2)} KB'),
                                _buildInfoRow('Hash', evidence.fileHash.substring(0, 24) + '...'),
                                _buildInfoRow(
                                  'Time',
                                  '${evidence.timestamp.day}/${evidence.timestamp.month}/${evidence.timestamp.year} ${evidence.timestamp.hour}:${evidence.timestamp.minute.toString().padLeft(2, '0')}',
                                ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _verifyEvidence(evidence),
                                      icon: Icon(Icons.verified),
                                      label: Text('Verify'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Open full screen view
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Scaffold(
                                              appBar: AppBar(title: Text('Evidence')),
                                              body: Center(
                                                child: evidence.fileType == 'image'
                                                    ? CachedNetworkImage(
                                                        imageUrl: evidence.downloadUrl,
                                                        fit: BoxFit.contain,
                                                      )
                                                    : Text('Video preview not available'),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.fullscreen),
                                      label: Text('View'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

