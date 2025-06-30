import 'package:calicut_textile_app/controller/supplier_group_controller.dart';
import 'package:calicut_textile_app/controller/supplier_list_controller.dart';
import 'package:calicut_textile_app/view/main_screen/supplier/supplier_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SuppliersPage extends StatefulWidget {
  @override
  _SuppliersPageState createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _searchController;
  late ScrollController _scrollController;

  bool showGroupFilter = false;

  @override
  void initState() {
    super.initState();
    final suppliersController = Provider.of<SuppliersController>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    
    // Load suppliers and supplier groups
    suppliersController.loadSuppliers(isInitialLoad: true);
    supplierProvider.fetchSupplierGroups();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _searchController = TextEditingController();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        suppliersController.loadMoreSuppliers();
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

  void _performSearch(String query) {
    final controller = Provider.of<SuppliersController>(context, listen: false);
    controller.searchSuppliers(query);
  }

  void _selectSupplierGroup(String? groupName) {
    final controller = Provider.of<SuppliersController>(context, listen: false);
    controller.filterByGroup(groupName);
  }

  void _toggleGroupFilter() {
    setState(() {
      showGroupFilter = !showGroupFilter;
    });
  }

  void _clearFilters() {
    final controller = Provider.of<SuppliersController>(context, listen: false);
    _searchController.clear();
    controller.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SuppliersController, SupplierProvider>(
      builder: (context, suppliersController, supplierProvider, child) {
        final suppliers = suppliersController.suppliers;

        return Scaffold(
          appBar: AppBar(
            title: Text('Suppliers'),
            centerTitle: true,
            actions: [
              // Filter toggle button
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: showGroupFilter ? Colors.blue : null,
                ),
                onPressed: _toggleGroupFilter,
              ),
              // Clear filters button
              if (suppliersController.searchQuery.isNotEmpty || suppliersController.selectedGroup != null)
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: _clearFilters,
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _performSearch,
                  decoration: InputDecoration(
                    labelText: 'Search Suppliers',
                    hintText: 'Search by name or ID',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Supplier Group Filter (Collapsible)
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: showGroupFilter ? null : 0,
                  child: showGroupFilter
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.group, color: Colors.indigo),
                                  SizedBox(width: 8),
                                  Text(
                                    'Filter by Supplier Group',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              
                              if (supplierProvider.isLoading)
                                Center(child: CircularProgressIndicator())
                              else if (supplierProvider.hasError)
                                Text(
                                  'Error loading groups: ${supplierProvider.errorMessage}',
                                  style: TextStyle(color: Colors.red),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // "All Groups" chip
                                    FilterChip(
                                      label: Text('All Groups'),
                                      selected: suppliersController.selectedGroup == null,
                                      onSelected: (selected) {
                                        if (selected) _selectSupplierGroup(null);
                                      },
                                      selectedColor: Colors.indigo.withOpacity(0.2),
                                      checkmarkColor: Colors.indigo,
                                    ),
                                    
                                    // Individual group chips
                                    ...supplierProvider.supplierGroups.map((group) {
                                      return FilterChip(
                                        label: Text(group.name),
                                        selected: suppliersController.selectedGroup == group.name,
                                        onSelected: (selected) {
                                          _selectSupplierGroup(selected ? group.name : null);
                                        },
                                        selectedColor: Colors.indigo.withOpacity(0.2),
                                        checkmarkColor: Colors.indigo,
                                      );
                                    }).toList(),
                                  ],
                                ),
                            ],
                          ),
                        )
                      : SizedBox.shrink(),
                ),
                
                if (showGroupFilter) SizedBox(height: 16),
                
                // Active Filters Display
                if (suppliersController.searchQuery.isNotEmpty || suppliersController.selectedGroup != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getActiveFiltersText(suppliersController),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearFilters,
                          child: Icon(Icons.close, size: 16, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                
                // Results Summary
                if (suppliers.isNotEmpty || suppliersController.isLoading)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${suppliers.length} of ${suppliersController.totalSuppliers} suppliers',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        if (suppliersController.hasMore)
                          Text(
                            'Page ${suppliersController.currentPage - 1} of ${suppliersController.totalPages}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                
                // Error Display
                if (suppliersController.hasError)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suppliersController.errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.red),
                          onPressed: () => suppliersController.refreshSuppliers(),
                        ),
                      ],
                    ),
                  ),
                
                // Suppliers List
                Expanded(
                  child: suppliers.isEmpty && !suppliersController.isLoading
                      ? _buildEmptyState(suppliersController)
                      : RefreshIndicator(
                          onRefresh: suppliersController.refreshSuppliers,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: suppliers.length + (suppliersController.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < suppliers.length) {
                                final supplier = suppliers[index];

                                final animation = Tween<Offset>(
                                  begin: Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    index * (1 / (suppliers.length > 0 ? suppliers.length : 1)),
                                    ((index + 1) * (1 / (suppliers.length > 0 ? suppliers.length : 1))).clamp(0.0, 1.0),
                                    curve: Curves.easeOutCubic,
                                  ),
                                ));

                                return SlideTransition(
                                  position: animation,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SupplierDetails(supplier: supplier),
                                        ),
                                      );
                                    },
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
                                              radius: 20,
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
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'ID: ${supplier.supplierId}',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  // Display group name
                                                  Padding(
                                                    padding: EdgeInsets.only(top: 4),
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.indigo.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        supplier.supplierGroup,
                                                        style: TextStyle(
                                                          color: Colors.indigo,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Display address if available
                                                  
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                // Bottom Loader
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: suppliersController.isLoading
                                        ? CircularProgressIndicator()
                                        : Text('No more suppliers'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(SuppliersController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No suppliers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            controller.searchQuery.isNotEmpty || controller.selectedGroup != null
                ? 'Try adjusting your filters'
                : 'No suppliers available',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (controller.searchQuery.isNotEmpty || controller.selectedGroup != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              child: Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  String _getActiveFiltersText(SuppliersController controller) {
    List<String> filters = [];
    
    if (controller.searchQuery.isNotEmpty) {
      filters.add('Search: "${controller.searchQuery}"');
    }
    
    if (controller.selectedGroup != null) {
      filters.add('Group: ${controller.selectedGroup}');
    }
    
    return 'Active filters: ${filters.join(', ')}';
  }
}