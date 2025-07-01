import 'dart:ui';

import 'package:calicut_textile_app/controller/supplier_list_controller.dart';
import 'package:calicut_textile_app/controller/supplier_group_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SupplierDialogBox extends StatefulWidget {
  const SupplierDialogBox({
    super.key,
    required this.onSupplierSelected,
    required this.suppliers, // Callback function
  });
  final List<dynamic> suppliers; // List of suppliers
  final Function(String supplierId, String supplierName) onSupplierSelected; // Callback function

  @override
  State<SupplierDialogBox> createState() => _SupplierDialogBoxState();
}

class _SupplierDialogBoxState extends State<SupplierDialogBox> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? selectedSupplierId; // Track selected supplier
  bool showGroupFilter = false; // Toggle group filter visibility

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<SuppliersController>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    
    // Load suppliers and supplier groups if not already loaded
    if (controller.suppliers.isEmpty) {
      controller.loadSuppliers(isInitialLoad: true);
    }
    
    // Load supplier groups
    if (supplierProvider.supplierGroups.isEmpty) {
      supplierProvider.fetchSupplierGroups();
    }

    // Add scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        controller.loadMoreSuppliers();
      }
    });
  }

  @override
  void dispose() {
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

  void _selectSupplier(String supplierId, String supplierName) {
    setState(() {
      selectedSupplierId = supplierId;
    });
    
    // Call the callback with both ID and name
    widget.onSupplierSelected(supplierId, supplierName);
    
    // Close dialog after a short delay to show selection
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Consumer2<SuppliersController, SupplierProvider>(
          builder: (context, controller, supplierProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.business_center_sharp,
                        color: Colors.white,
                        size: 24,
                      ),
                      // Filter toggle button
                      // GestureDetector(
                      //   onTap: _toggleGroupFilter,
                      //   child: Container(
                      //     padding: const EdgeInsets.all(6),
                      //     margin: const EdgeInsets.only(right: 8),
                      //     decoration: BoxDecoration(
                      //       color: showGroupFilter 
                      //           ? Colors.white.withOpacity(0.3)
                      //           : Colors.white.withOpacity(0.2),
                      //       borderRadius: BorderRadius.circular(20),
                      //     ),
                      //     child: Icon(
                      //       Icons.filter_list,
                      //       color: Colors.white,
                      //       size: 18,
                      //     ),
                      //   ),
                      // ),
                      // Clear filters button
                      if (controller.searchQuery.isNotEmpty || controller.selectedGroup != null)
                        GestureDetector(
                          onTap: _clearFilters,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.clear_all,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Supplier',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (controller.suppliers.isNotEmpty)
                              Text(
                                '${controller.suppliers.length} suppliers available',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            
                // Search Bar with Integrated Filter
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Main Search TextField with Filter Icon
                      TextField(
                        controller: _searchController,
                        onChanged: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Search by name or ID...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Filter Toggle Button
                              IconButton(
                                icon: Icon(
                                  Icons.filter_list,
                                  color: showGroupFilter 
                                      ? Colors.blueAccent 
                                      : Colors.grey,
                                ),
                                onPressed: _toggleGroupFilter,
                                tooltip: 'Filter by group',
                              ),
                              // Clear Search Button
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                  tooltip: 'Clear search',
                                ),
                              // Clear All Filters Button
                              if (controller.searchQuery.isNotEmpty || controller.selectedGroup != null)
                                IconButton(
                                  icon: const Icon(Icons.clear_all, color: Colors.red),
                                  onPressed: _clearFilters,
                                  tooltip: 'Clear all filters',
                                ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blueAccent),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      
                      // Expandable Group Filter Chips (Below Search)
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: showGroupFilter ? null : 0,
                        child: showGroupFilter
                            ? Container(
                                width: double.infinity,
                                padding: EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.group, color: Colors.indigo, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Filter by Group:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    
                                    if (supplierProvider.isLoading)
                                      Container(
                                        height: 32,
                                        child: Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      )
                                    else if (supplierProvider.hasError)
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Error loading groups',
                                          style: TextStyle(
                                            color: Colors.red.shade700, 
                                            fontSize: 11
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: double.infinity,
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            // "All Groups" chip
                                            _buildCompactFilterChip(
                                              label: 'All',
                                              selected: controller.selectedGroup == null,
                                              onSelected: (selected) {
                                                if (selected) _selectSupplierGroup(null);
                                              },
                                            ),
                                            
                                            // Individual group chips
                                            ...supplierProvider.supplierGroups.map((group) {
                                              return _buildCompactFilterChip(
                                                label: group.name,
                                                selected: controller.selectedGroup == group.name,
                                                onSelected: (selected) {
                                                  _selectSupplierGroup(selected ? group.name : null);
                                                },
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                // Active Filters Display
                if (controller.searchQuery.isNotEmpty || controller.selectedGroup != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            _getActiveFiltersText(controller),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearFilters,
                          child: Icon(Icons.close, size: 16, color: Colors.blue),
                        ),
                      ],
                    ),
                  )
                
                // Search display (only if no group filter active)
                else if (controller.searchQuery.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Searching for: "${controller.searchQuery}"',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                          child: Icon(Icons.close, size: 16, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                
                if (controller.searchQuery.isNotEmpty) SizedBox(height: 8),

                // Error Display
                if (controller.hasError)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            controller.errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.red),
                          onPressed: () => controller.refreshSuppliers(),
                        ),
                      ],
                    ),
                  ),
                
                // Loading Indicator
                if (controller.isLoading && controller.suppliers.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blueAccent),
                          SizedBox(height: 16),
                          Text(
                            'Loading suppliers...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                
                // Suppliers List
                else
                  Flexible(
                    child: controller.suppliers.isEmpty && !controller.isLoading
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  controller.searchQuery.isNotEmpty
                                      ? 'No suppliers found'
                                      : 'No suppliers available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (controller.searchQuery.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Try adjusting your search terms',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 16                                ),
                                ElevatedButton.icon(
                                  onPressed: _clearFilters,
                                  icon: Icon(Icons.clear_all, size: 16),
                                  label: Text('Clear Filters'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: controller.refreshSuppliers,
                            child: ListView.separated(
                              controller: _scrollController,
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: controller.suppliers.length + 
                                        (controller.hasMore ? 1 : 0),
                              separatorBuilder: (context, index) => 
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                if (index < controller.suppliers.length) {
                                  final supplier = controller.suppliers[index];
                                  final isSelected = selectedSupplierId == supplier.supplierId;
                                  
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _selectSupplier(
                                        supplier.supplierId,
                                        supplier.supplierName,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? Colors.blueAccent.withOpacity(0.1)
                                              : Colors.grey[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.blueAccent
                                                : Colors.grey[200]!,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: isSelected
                                                  ? Colors.blueAccent
                                                  : Colors.grey[300],
                                              child: Icon(
                                                Icons.business,
                                                size: 16,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    supplier.supplierName,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      color: isSelected
                                                          ? Colors.blueAccent
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'ID: ${supplier.supplierId}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  if (supplier.supplierGroup.isNotEmpty)
                                                    Padding(
                                                      padding: EdgeInsets.only(top: 4),
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: 6, 
                                                          vertical: 2
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: isSelected
                                                              ? Colors.blueAccent.withOpacity(0.2)
                                                              : Colors.grey.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          supplier.supplierGroup,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: isSelected
                                                                ? Colors.blueAccent
                                                                : Colors.grey[700],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.blueAccent,
                                                size: 20,
                                              )
                                            else
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Colors.grey[400],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  // Bottom loader
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: controller.isLoading
                                          ? CircularProgressIndicator(
                                              color: Colors.blueAccent,
                                            )
                                          : Text(
                                              'No more suppliers',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                  ),

                // Bottom padding
                SizedBox(height: 16),
              ],
            );
          }
        ),
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

  // Helper method to build compact filter chips
  Widget _buildCompactFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return InkWell(
      onTap: () => onSelected(!selected),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected 
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected 
                ? Colors.blueAccent
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(
                Icons.check,
                size: 12,
                color: Colors.blueAccent,
              ),
              SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected 
                    ? Colors.blueAccent
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}