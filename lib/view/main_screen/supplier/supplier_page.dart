import 'package:flutter/material.dart';

class SuppliersPage extends StatefulWidget {
  @override
  _SuppliersPageState createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _searchController;

  List<Map<String, String>> suppliers = [
    {'name': 'ABC Supplies', 'alias': 'ABC'},
    {'name': 'Global Traders', 'alias': 'GT'},
    {'name': 'Speed Logistics', 'alias': 'Speed'},
    {'name': 'Fresh Mart', 'alias': 'FM'},
    {'name': 'Tech Parts', 'alias': 'TP'},
    {'name': 'Nova Supply', 'alias': 'NS'},
    {'name': 'QuickServe', 'alias': 'QS'},
  ];

  List<Map<String, String>> filteredSuppliers = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _searchController = TextEditingController();
    filteredSuppliers = suppliers;
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void filterSuppliers(String query) {
    final results = suppliers.where((supplier) {
      final nameLower = supplier['name']!.toLowerCase();
      final aliasLower = supplier['alias']!.toLowerCase();
      final searchLower = query.toLowerCase();

      return nameLower.contains(searchLower) || aliasLower.contains(searchLower);
    }).toList();

    setState(() {
      filteredSuppliers = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suppliers'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: filterSuppliers,
              decoration: InputDecoration(
                labelText: 'Search Suppliers',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredSuppliers.length,
                itemBuilder: (context, index) {
                  final supplier = filteredSuppliers[index];
                  final animation = Tween<Offset>(
                    begin: Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index * (1 / filteredSuppliers.length),
                      (index + 1) * (1 / filteredSuppliers.length),
                      curve: Curves.easeOutCubic,
                    ),
                  ));

                  return SlideTransition(
                    position: animation,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.indigo.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.indigo.withOpacity(0.1),
                              child: Icon(Icons.store, color: Colors.indigo, size: 28),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplier['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Alias: ${supplier['alias'] ?? ''}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }
}
