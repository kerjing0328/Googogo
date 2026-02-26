import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_detail_screen.dart';

class PlannerList extends StatefulWidget {
  const PlannerList({super.key});

  @override
  State<PlannerList> createState() => _PlannerListState();
}

class _PlannerListState extends State<PlannerList> {
  // --- Filter States ---
  String _selectedState = 'All';
  String _selectedStatus = 'All';
  String _selectedSeverity = 'All';
  String _dateSort = 'Newest'; 
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusOptions = ['All', 'Submitted', 'Acknowledged', 'In Progress', 'Resolved'];
  final List<String> _severityOptions = ['All', 'Critical (8-10)', 'Moderate (4-7)', 'Minor (1-3)'];
  List<String> _availableStates = ['All']; 

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedState = 'All';
      _selectedStatus = 'All';
      _selectedSeverity = 'All';
      _dateSort = 'Newest';
      _searchQuery = '';
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved': return const Color(0xFF48A89D); 
      case 'in progress': return Colors.orange;
      case 'acknowledged': return const Color(0xFF4953B9); 
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("All Reports", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    IconButton(icon: const Icon(Icons.refresh), onPressed: _resetFilters, tooltip: "Reset Filters"),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search ID, description...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildDropdown("Region", _availableStates, _selectedState, (val) => setState(() => _selectedState = val!))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown("Status", _statusOptions, _selectedStatus, (val) => setState(() => _selectedStatus = val!))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown("Severity", _severityOptions, _selectedSeverity, (val) => setState(() => _selectedSeverity = val!))),
                    const SizedBox(width: 12),
                    
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        border: Border.all(color: Colors.grey.shade300), 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: IconButton(
                        icon: Icon(_dateSort == 'Newest' ? Icons.arrow_downward : Icons.arrow_upward, color: const Color(0xFF4953B9)),
                        tooltip: "Sort by Date",
                        onPressed: () => setState(() => _dateSort = _dateSort == 'Newest' ? 'Oldest' : 'Newest'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('walkway_damage').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var allDocs = snapshot.data!.docs;

                Set<String> states = {'All'};
                for (var doc in allDocs) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['state'] != null) states.add(data['state']);
                }
                if (states.length != _availableStates.length) {
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                     setState(() {
                       _availableStates = states.toList()..sort();
                       _availableStates.remove('All');
                       _availableStates.insert(0, 'All');
                     });
                   });
                }

                var filteredList = allDocs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String state = data['state'] ?? 'Unknown';
                  String status = (data['status'] ?? 'submitted').toString().toLowerCase();
                  int severity = data['severity'] ?? 0;
                  String desc = (data['short_desc'] ?? '').toString().toLowerCase();
                  String reportId = (data['reportId'] ?? '').toString().toLowerCase();

                  if (_selectedState != 'All' && state != _selectedState) return false;
                  if (_selectedStatus != 'All' && status != _selectedStatus.toLowerCase()) return false;
                  if (_selectedSeverity == 'Critical (8-10)' && severity < 8) return false;
                  if (_selectedSeverity == 'Moderate (4-7)' && (severity < 4 || severity > 7)) return false;
                  if (_selectedSeverity == 'Minor (1-3)' && severity > 3) return false;
                  if (_searchQuery.isNotEmpty && !desc.contains(_searchQuery) && !reportId.contains(_searchQuery)) return false;
                  
                  return true;
                }).toList();

                filteredList.sort((a, b) {
                  Timestamp tA = (a.data() as Map<String, dynamic>)['timestamp'] ?? Timestamp.now();
                  Timestamp tB = (b.data() as Map<String, dynamic>)['timestamp'] ?? Timestamp.now();
                  return _dateSort == 'Newest' ? tB.compareTo(tA) : tA.compareTo(tB);
                });

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_off, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text("No reports found", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    var doc = filteredList[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildReportCard(context, doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String currentValue, ValueChanged<String?> onChanged) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items[0],
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String value) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value == 'All' ? label : value,
                  style: TextStyle(
                    color: value == 'All' ? Colors.grey.shade600 : const Color(0xFF4953B9),
                    fontWeight: value == 'All' ? FontWeight.normal : FontWeight.bold,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: items.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String docId, Map<String, dynamic> data) {
    String status = data['status'] ?? 'submitted';
    String type = data['damage_type'] ?? 'Issue';
    String reportId = data['reportId'] ?? 'N/A';
    int severity = data['severity'] ?? 0;
    
    Color sevColor = const Color(0xFF48A89D); 
    if (severity >= 4) sevColor = Colors.orange;
    if (severity >= 8) sevColor = const Color(0xFFE11D48);

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailScreen(docId: docId, data: data))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60, height: 60, color: Colors.grey.shade100,
                  child: data['imageUrl'] != null
                    ? Image.network(data['imageUrl'], fit: BoxFit.cover)
                    : const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(status))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("#$reportId • ${data['state'] ?? 'Unknown'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: sevColor),
                        const SizedBox(width: 6),
                        Text("Severity: $severity", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sevColor)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}