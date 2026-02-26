import 'package:flutter/material.dart';
import '../../models/route_option.dart';

class RouteSheet extends StatelessWidget {
  final List<RouteOption> routes;
  final RouteOption? selectedRoute;
  final Function(RouteOption) onPreviewRoute;
  final VoidCallback onStartNavigation;
  final VoidCallback onClose;

  const RouteSheet({
    super.key,
    required this.routes,
    required this.selectedRoute,
    required this.onPreviewRoute,
    required this.onStartNavigation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.55;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${routes.length} Routes Found",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 20),
                itemCount: routes.length,
                itemBuilder: (ctx, i) {
                  final route = routes[i];
                  final isSelected = selectedRoute == route;
                  final isRecommended = i == 0;

                  return Card(
                    color: isSelected ? Colors.teal.shade50 : Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    shape: isSelected
                        ? RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.teal, width: 2),
                            borderRadius: BorderRadius.circular(10))
                        : null,
                    child: ExpansionTile(
                      leading: Icon(
                        isRecommended ? Icons.star : Icons.directions_walk,
                        color: isRecommended ? Colors.amber : Colors.grey,
                      ),
                      title: Text(
                        isRecommended ? "Best Route (${route.summary})" : route.summary,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isRecommended ? Colors.teal : Colors.black,
                        ),
                      ),
                      subtitle: Text("${route.duration} • ${route.issueCount} Issues"),
                      onExpansionChanged: (expanded) {
                        if (expanded) onPreviewRoute(route);
                      },
                      children: [
                        Container(
                          height: 150,
                          color: Colors.white,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(10),
                            itemCount: route.steps.length,
                            separatorBuilder: (ctx, j) => const Divider(height: 1),
                            itemBuilder: (ctx, j) {
                              final step = route.steps[j];
                              final stepIssues = route.issuesPerStep[j] ?? [];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.turn_right, size: 16),
                                title: Text(step.instruction,
                                    style: const TextStyle(fontSize: 13)),
                                subtitle: stepIssues.isNotEmpty
                                    ? Text("⚠ ${stepIssues.join(', ')}",
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 11))
                                    : null,
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: onStartNavigation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: const Text(
                              "START THIS ROUTE",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}