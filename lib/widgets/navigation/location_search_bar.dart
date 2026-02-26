import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/navigation_service.dart';
import '../../models/route_option.dart';

class LocationSearchBar extends StatefulWidget {
  final TextEditingController originController;
  final TextEditingController destController;
  final UserMode selectedMode;
  final VoidCallback onFindRoutes;
  final Function(String) onSpeak;

  const LocationSearchBar({
    super.key,
    required this.originController,
    required this.destController,
    required this.selectedMode,
    required this.onFindRoutes,
    required this.onSpeak,
  });

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final NavigationService _navService = NavigationService();
  List<dynamic> _placeSuggestions = [];
  Timer? _debounceTimer;
  bool _isEditingOrigin = false;

  void _onSearchChanged(String input) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (input.isNotEmpty) {
        _fetchSuggestions(input);
      } else {
        setState(() => _placeSuggestions = []);
      }
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    try {
      final results = await _navService.fetchPlaceSuggestions(input);
      setState(() => _placeSuggestions = results);
    } catch (e) {
      print(e);
    }
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    if (_isEditingOrigin) {
      widget.originController.text = suggestion['description'];
    } else {
      widget.destController.text = suggestion['description'];
    }
    setState(() => _placeSuggestions = []);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            TextField(
              controller: widget.originController,
              onTap: () => setState(() {
                _isEditingOrigin = true;
                _placeSuggestions = [];
              }),
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Your location",
                prefixIcon: Icon(Icons.my_location, color: Colors.blue, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              ),
            ),
            const Divider(height: 1, indent: 15, endIndent: 15),
            
            TextField(
              controller: widget.destController,
              onTap: () => setState(() {
                _isEditingOrigin = false;
                _placeSuggestions = [];
              }),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Choose destination",
                prefixIcon: const Icon(Icons.location_on, color: Colors.red, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                suffixIcon: widget.selectedMode == UserMode.voice
                    ? IconButton(
                        icon: const Icon(Icons.mic, color: Colors.teal),
                        onPressed: () => widget.onSpeak("Listening..."),
                      )
                    : null,
              ),
            ),

            if (_placeSuggestions.isNotEmpty)
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3, 
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _placeSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    return ListTile(
                      leading: const Icon(Icons.place_outlined, size: 18),
                      title: Text(
                        _placeSuggestions[index]['description'],
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectSuggestion(_placeSuggestions[index]),
                    );
                  },
                ),
              ),

            if (widget.destController.text.isNotEmpty && _placeSuggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: ElevatedButton(
                      onPressed: widget.onFindRoutes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Find Route"),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}