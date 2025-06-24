import 'package:calicut_textile_app/controller/supplier_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:calicut_textile_app/modal/supplier_list._modaldart';

class SuppliersPage extends StatefulWidget {
  @override
  _SuppliersPageState createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _searchController;
  late ScrollController _scrollController;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<SuppliersController>(context, listen: false);
    controller.loadSuppliers();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _searchController = TextEditingController();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        controller.loadSuppliers();
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void filterSuppliers(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SuppliersController>(
      builder: (context, controller, child) {
        // Apply search filter
        final suppliers = controller.suppliers.where((supplier) {
          return supplier.supplierName.toLowerCase().contains(searchQuery) ||
              supplier.supplierId.toLowerCase().contains(searchQuery);
        }).toList();

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
                    controller: _scrollController,
                    itemCount: suppliers.length + (controller.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < suppliers.length) {
                        final supplier = suppliers[index];

                        final animation = Tween<Offset>(
                          begin: Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            index * (1 / suppliers.length),
                            (index + 1) * (1 / suppliers.length),
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
                                          supplier.supplierName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${supplier.address}',
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
                      } else {
                        // Bottom Loader
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: controller.isLoading
                                ? CircularProgressIndicator()
                                : Text('No more suppliers'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
