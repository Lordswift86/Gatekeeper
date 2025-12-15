import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/security_service.dart';
import '../../models/data_models.dart';

class IntercomView extends StatefulWidget {
  const IntercomView({super.key});

  @override
  State<IntercomView> createState() => _IntercomViewState();
}

class _IntercomViewState extends State<IntercomView> {
  List<User> _residents = [];
  List<User> _filteredResidents = [];
  String _search = '';
  String? _callingId;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  void _loadResidents() {
    final list = SecurityService().getEstateResidents('est_1');
    setState(() {
      _residents = list;
      _filteredResidents = list;
    });
  }

  void _filter(String query) {
    setState(() {
      _search = query;
      _filteredResidents = _residents.where((u) => 
        u.name.toLowerCase().contains(query.toLowerCase()) || 
        (u.unitNumber?.contains(query) ?? false)
      ).toList();
    });
  }

  void _call(String id) {
    setState(() => _callingId = id);
    SecurityService().initiateCall('u_3', id); // u_3 is Sam Security (Hardcoded for demo)
    
    // Simulate Call End
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _callingId = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Call Ended (Simulation)")));
      }
    });
  }

  void _openChat(User resident) {
    // We need current user (Security). In real app, get from Provider/Context.
    // For demo, we assume Sam Security (u_3).
    SecurityService().login('sam@sunset.com').then((user) {
        if (user != null && mounted) {
           Navigator.pushNamed(context, '/chat', arguments: {'currentUser': user, 'chatUser': resident});
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: _filter,
            decoration: InputDecoration(
              prefixIcon: const Icon(LucideIcons.search),
              hintText: "Search Resident or Unit...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12
            ),
            itemCount: _filteredResidents.length,
            itemBuilder: (context, index) {
              final res = _filteredResidents[index];
              final isCalling = _callingId == res.id;
              
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(res.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text("Unit ${res.unitNumber}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           IconButton.filled(
                             onPressed: () => _openChat(res), 
                             icon: const Icon(LucideIcons.messageSquare, size: 18),
                             style: IconButton.styleFrom(backgroundColor: Colors.indigo.shade50, foregroundColor: Colors.indigo),
                           ),
                           IconButton.filled(
                             onPressed: isCalling ? null : () => _call(res.id),
                             icon: Icon(isCalling ? LucideIcons.mic : LucideIcons.phone, size: 18),
                             style: IconButton.styleFrom(
                               backgroundColor: isCalling ? Colors.green : Colors.grey.shade100, 
                               foregroundColor: isCalling ? Colors.white : Colors.grey.shade800
                             ),
                           )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
