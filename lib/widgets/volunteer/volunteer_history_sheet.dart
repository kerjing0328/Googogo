import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerHistorySheet extends StatefulWidget {
  final String userId;
  final ScrollController scrollController;
  const VolunteerHistorySheet({
    required this.userId,
    required this.scrollController,
    super.key,
  });
  @override
  State<VolunteerHistorySheet> createState() => _VolunteerHistorySheetState();
}

class _VolunteerHistorySheetState extends State<VolunteerHistorySheet> {
  List<Map<String, dynamic>> _myUploads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyUploads();
  }

  Future<void> _fetchMyUploads() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('walkway_damage')
          .where('reporterId', isEqualTo: widget.userId)
          .get();
      if (mounted) {
        setState(() {
          _myUploads = query.docs.map((doc) => doc.data()).toList();
          _myUploads.sort((a, b) {
            Timestamp tA = a['timestamp'] ?? Timestamp.now();
            Timestamp tB = b['timestamp'] ?? Timestamp.now();
            return tB.compareTo(tA);
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime d = timestamp.toDate();
      return "${d.day}/${d.month}/${d.year}";
    }
    return "Unknown";
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'in progress': return Colors.orange;
      case 'acknowledged': return Colors.blue;
      default: return Colors.green;
    }
  }

  void _showDetailSheet(Map<String, dynamic> item) {
    int severity = 0;
    if (item['severity'] is int) {
      severity = item['severity'];
    } else if (item['severity'] is String) {
      severity = int.tryParse(item['severity']) ?? 0;
    }
    
    Color severityColor = Colors.green; 
    if (severity >= 4) severityColor = Colors.orange; 
    if (severity >= 8) severityColor = Colors.red;

    String status = item['status'] ?? 'submitted';
    String reportId = item['reportId'] ?? 'N/A';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            
            Padding(
              padding: const EdgeInsets.all(10), 
              child: Column(
                children: [
                  const Text("Report Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("ID: $reportId", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    

                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item['imageUrl'] != null
                          ? Image.network(item['imageUrl'], height: 200, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 50),
                    ),
                    const SizedBox(height: 20),
                    _buildDetail("Type", item['damage_type'].toString().toUpperCase()),
                    _buildDetail("Location", item['state'] ?? "Unknown"),
                    _buildDetail("Severity", "$severity/10", color: severityColor),
                    _buildDetail("Description", item['short_desc']),
                    _buildDetail("Date", _formatDate(item['timestamp'])),
                    // Status Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, letterSpacing: 1.2))),
                    ),
                    const SizedBox(height: 20),
                    if (item['admin_notes'] != null && item['admin_notes'].toString().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.blue.shade100), borderRadius: BorderRadius.circular(8), color: Colors.blue.shade50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [Icon(Icons.info_outline, size: 16, color: Colors.blue), SizedBox(width: 5), Text("Authority Note", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))]),
                            const SizedBox(height: 5),
                            Text(item['admin_notes'], style: TextStyle(color: Colors.blue.shade900)),
                          ],
                        ),
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String val, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          Expanded(child: Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const Padding(padding: EdgeInsets.all(15), child: Text("My History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _myUploads.isEmpty
                ? const Center(child: Text("No history."))
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _myUploads.length,
                    itemBuilder: (context, index) {
                      final item = _myUploads[index];
                      final status = item['status'] ?? 'submitted';
                      
                      return GestureDetector(
                        onTap: () => _showDetailSheet(item),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 60, height: 60, color: Colors.grey[200],
                                    child: item['imageUrl'] != null ? Image.network(item['imageUrl'], fit: BoxFit.cover) : const Icon(Icons.image),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['damage_type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(item['state'] ?? "Unknown", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(status))),
                                      )
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}