import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui; 
import 'report_detail_screen.dart';

class PlannerDashboard extends StatelessWidget {
  final VoidCallback onViewAll;

  const PlannerDashboard({super.key, required this.onViewAll});

  void _handleExport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Exporting Analytics Data..."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF4953B9),
        width: 300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('walkway_damage').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var docs = snapshot.data!.docs;

              // --- DATA PROCESSING ---
              int submitted = 0, inProgress = 0, resolved = 0, critical = 0;
              int sevLow = 0, sevMid = 0, sevHigh = 0;
              List<DocumentSnapshot> inboxItems = [];
              
              Map<String, int> dailyCounts = {};
              DateTime now = DateTime.now();
              for (int i = 6; i >= 0; i--) {
                DateTime d = now.subtract(Duration(days: i));
                String dateKey = "${d.day}/${d.month}";
                dailyCounts[dateKey] = 0; // Initialize 0
              }

              for (var doc in docs) {
                var data = doc.data() as Map<String, dynamic>;
                String status = (data['status'] ?? 'submitted').toString().toLowerCase();
                int severity = data['severity'] is int ? data['severity'] : 0;
                
                // Status Counts
                if (status == 'submitted') {
                  submitted++;
                  inboxItems.add(doc);
                } else if (status == 'in progress' || status == 'acknowledged') inProgress++;
                else if (status == 'resolved') resolved++;

                // Severity
                if (severity >= 8) { sevHigh++; if (status != 'resolved') critical++; }
                else if (severity >= 4) sevMid++;
                else sevLow++;

                // Trend Data Processing
                if (data['timestamp'] != null) {
                  DateTime t = (data['timestamp'] as Timestamp).toDate();
                  if (now.difference(t).inDays <= 7) {
                    String key = "${t.day}/${t.month}";
                    if (dailyCounts.containsKey(key)) {
                      dailyCounts[key] = dailyCounts[key]! + 1;
                    }
                  }
                }
              }

              inboxItems.sort((a, b) {
                Timestamp tA = (a.data() as Map<String, dynamic>)['timestamp'] ?? Timestamp.now();
                Timestamp tB = (b.data() as Map<String, dynamic>)['timestamp'] ?? Timestamp.now();
                return tB.compareTo(tA);
              });

              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Dashboard Overview", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              SizedBox(height: 6),
                              Text("Real-time insights and incoming reports.", style: TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _handleExport(context),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text("Export"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4953B9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 30),

                      LayoutBuilder(builder: (context, constraints) {
                        return Wrap(
                          spacing: 20, runSpacing: 20,
                          children: [
                            _StatCard(title: "New", count: submitted, color: const Color(0xFF4953B9), icon: Icons.mark_email_unread_outlined, maxWidth: constraints.maxWidth),
                            _StatCard(title: "Active", count: inProgress, color: const Color(0xFF48A89D), icon: Icons.handyman_outlined, maxWidth: constraints.maxWidth),
                            _StatCard(title: "Critical", count: critical, color: const Color(0xFFE11D48), icon: Icons.warning_amber_rounded, maxWidth: constraints.maxWidth),
                            _StatCard(title: "Fixed", count: resolved, color: const Color(0xFF5382C9), icon: Icons.check_circle_outline, maxWidth: constraints.maxWidth),
                          ],
                        );
                      }),
                      const SizedBox(height: 30),

                      SizedBox(
                        height: 300, 
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Severity Breakdown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    const Spacer(),
                                    _SimpleBarChart(
                                      data: {
                                        "Minor": sevLow,
                                        "Moderate": sevMid,
                                        "Critical": sevHigh,
                                      },
                                      colors: const [Color(0xFF5382C9), Colors.orange, Color(0xFFE11D48)],
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4953B9), Color(0xFF48A89D)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: const Color(0xFF4953B9).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.auto_graph, color: Colors.white, size: 32),
                                    const Spacer(),
                                    Text("${((resolved / (docs.isEmpty ? 1 : docs.length)) * 100).toStringAsFixed(1)}%", 
                                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)
                                    ),
                                    const Text("Resolution Rate", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    Text(
                                      "$resolved issues fixed out of ${docs.length} total reports.", 
                                      style: const TextStyle(color: Colors.white70, fontSize: 12)
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),

                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Report Activity (Last 7 Days)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                Icon(Icons.show_chart, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: _TrendLineChart(data: dailyCounts),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Recent Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          TextButton(
                            onPressed: onViewAll, 
                            child: const Text("View All", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4953B9)))
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        color: Colors.white,
                        child: inboxItems.isEmpty
                          ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No new reports.")))
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: inboxItems.take(5).length,
                              separatorBuilder: (c, i) => Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.shade100),
                              itemBuilder: (context, index) {
                                var doc = inboxItems[index];
                                var data = doc.data() as Map<String, dynamic>;
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.assignment_outlined, color: Color(0xFF4953B9), size: 20),
                                  ),
                                  title: Text(data['damage_type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text("#${data['reportId']} • ${data['state']}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailScreen(docId: doc.id, data: data))),
                                );
                              },
                            ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final double maxWidth;

  const _StatCard({required this.title, required this.count, required this.color, required this.icon, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    // 4 Columns logic
    double width = (maxWidth > 800) ? (maxWidth - 60) / 4 : (maxWidth - 20) / 2;
    if (maxWidth < 500) width = maxWidth;

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(count.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)),
          Text(title, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final Map<String, int> data;
  final List<Color> colors;

  const _SimpleBarChart({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    int maxVal = 1;
    data.forEach((k, v) => maxVal = v > maxVal ? v : maxVal);

    int i = 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: data.entries.map((e) {
        Color c = colors[i++ % colors.length];
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
              width: 30,
              height: (e.value / maxVal) * 150 + 5, // Scale height
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5)),
            ),
            const SizedBox(height: 8),
            Text(e.key, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        );
      }).toList(),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  final Map<String, int> data;
  const _TrendLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ChartPainter(data, const Color(0xFF4953B9)),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Map<String, int> data;
  final Color color;
  _ChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
      
    final Paint dotPaint = Paint()..color = color;

    final TextPainter textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    double maxVal = 1;
    data.forEach((_, v) => maxVal = v > maxVal ? v.toDouble() : maxVal);
    
    final Paint gridPaint = Paint()..color = Colors.grey.shade200..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), gridPaint);
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), gridPaint);
    canvas.drawLine(Offset(0, size.height/2), Offset(size.width, size.height/2), gridPaint);

    List<Offset> points = [];
    double stepX = size.width / (data.length - 1);
    int i = 0;

    data.forEach((key, val) {
      double x = i * stepX;
      double y = size.height - ((val / maxVal) * (size.height - 20)); // -20 for text space
      
      points.add(Offset(x, y));

      textPainter.text = TextSpan(text: key, style: TextStyle(color: Colors.grey.shade500, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width/2, size.height + 5));
      
      i++;
    });

    Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (var p in points) path.lineTo(p.dx, p.dy);
    canvas.drawPath(path, linePaint);

    for (var p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}