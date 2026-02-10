import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReportDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const ReportDetailScreen({super.key, required this.docId, required this.data});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late String _currentStatus;
  late TextEditingController _notesController;
  bool _isSaving = false;

  final List<String> _statusOptions = ['submitted', 'acknowledged', 'in progress', 'resolved'];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['status'] ?? 'submitted';
    _notesController = TextEditingController(text: widget.data['admin_notes'] ?? '');
  }

  // --- FEATURE: ENLARGE IMAGE DIALOG ---
  void _showEnlargedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            // Interactive Viewer for Zoom/Pan
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            // Close Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('walkway_damage').doc(widget.docId).update({
        'status': _currentStatus,
        'admin_notes': _notesController.text,
        'last_updated': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated successfully!"), backgroundColor: Color(0xFF48A89D)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    GeoPoint loc = widget.data['location'];
    int severity = widget.data['severity'] ?? 0;
    
    // Using Solid Color instead of Gradient
    const Color primaryColor = Color(0xFF4953B9); 

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text("Report #${widget.data['reportId'] ?? ''}"),
          backgroundColor: primaryColor, // Solid Color
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)]),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: IMAGE & MAP
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: widget.data['imageUrl'] != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(widget.data['imageUrl'], fit: BoxFit.cover, width: double.infinity),
                                      // Hover/Click Hint
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _showEnlargedImage(context, widget.data['imageUrl']),
                                          child: Container(
                                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.0)),
                                            alignment: Alignment.center,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                                  SizedBox(width: 4),
                                                  Text("Click to Enlarge", style: TextStyle(color: Colors.white, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                : Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image))),
                            ),
                            Expanded(
                              flex: 2,
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(target: LatLng(loc.latitude, loc.longitude), zoom: 16),
                                markers: {Marker(markerId: const MarkerId('t'), position: LatLng(loc.latitude, loc.longitude))},
                                zoomControlsEnabled: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // RIGHT: DETAILS FORM
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.data['damage_type'].toString().toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 8),
                              Text("Reported in ${widget.data['state']}", style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 24),
                              
                              _infoRow("Severity", "$severity / 10", severity >= 8 ? Colors.red : Colors.orange),
                              const SizedBox(height: 16),
                              const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(widget.data['short_desc'] ?? "N/A", style: const TextStyle(fontSize: 16)),
                              
                              const Divider(height: 40),
                              
                              const Text("Status Update", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _currentStatus,
                                    isExpanded: true,
                                    items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                                    onChanged: (val) => setState(() => _currentStatus = val!),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              const Text("Admin Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _notesController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: "Internal notes about repair status...",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // FOOTER
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor, // Solid color here
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 40, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        )
      ],
    );
  }
}