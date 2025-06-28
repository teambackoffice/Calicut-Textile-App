import 'package:calicut_textile_app/modal/add_supplier_order_modal.dart';
import 'package:calicut_textile_app/service/add_supplier_order_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateSupplierOrderController extends ChangeNotifier {
    bool _isLoading = false;
    String? _errorMessage;
    bool _isOrderCreated = false;
    
    // Current supplier order being created
    SupplierOrderModal? _currentOrder;
    
    // Product list for the order
    List<Product> _products = [];
    
    // Image paths for upload
    List<String> _imagePaths = [];
    
    // Form controllers
    final TextEditingController supplierController = TextEditingController();
    final TextEditingController orderDateController = TextEditingController();
    
    // Getters
    bool get isLoading => _isLoading;
    String? get errorMessage => _errorMessage;
    bool get isOrderCreated => _isOrderCreated;
    List<Product> get products => _products;
    List<String> get imagePaths => _imagePaths;
    SupplierOrderModal? get currentOrder => _currentOrder;
    double get grandTotal => _products.fold(0.0, (sum, product) => sum + product.amount);
    
    // Add product to the order
    void addProduct(Product product) {
        _products.add(product);
        _updateCurrentOrder();
        notifyListeners();
    }
    
    // Update product in the order
    void updateProduct(int index, Product updatedProduct) {
        if (index >= 0 && index < _products.length) {
            _products[index] = updatedProduct;
            _updateCurrentOrder();
            notifyListeners();
        }
    }
    
    // Remove product from the order
    void removeProduct(int index) {
        if (index >= 0 && index < _products.length) {
            _products.removeAt(index);
            _updateCurrentOrder();
            notifyListeners();
        }
    }
    
    // Clear all products
    void clearProducts() {
        _products.clear();
        _updateCurrentOrder();
        notifyListeners();
    }
    
    // Add image path
    void addImagePath(String imagePath) {
        _imagePaths.add(imagePath);
        _updateCurrentOrder();
        notifyListeners();
    }
    
    // Remove image path
    void removeImagePath(String imagePath) {
        _imagePaths.remove(imagePath);
        _updateCurrentOrder();
        notifyListeners();
    }
    
    // Pick image from gallery or camera
    Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
        try {
            final ImagePicker picker = ImagePicker();
            final XFile? image = await picker.pickImage(source: source);
            
            if (image != null) {
                addImagePath(image.path);
            }
        } catch (e) {
            _errorMessage = 'Error picking image: $e';
            notifyListeners();
        }
    }
    
    // Pick multiple images
    Future<void> pickMultipleImages() async {
        try {
            final ImagePicker picker = ImagePicker();
            final List<XFile> images = await picker.pickMultiImage();
            
            for (XFile image in images) {
                addImagePath(image.path);
            }
        } catch (e) {
            _errorMessage = 'Error picking images: $e';
            notifyListeners();
        }
    }
    
    // Update current order object
    void _updateCurrentOrder() {
        if (supplierController.text.isNotEmpty && orderDateController.text.isNotEmpty) {
            _currentOrder = SupplierOrderModal(
                supplier: supplierController.text,
                orderDate: orderDateController.text,
                grandTotal: grandTotal,
                products: _products,
                imagePaths: _imagePaths.isNotEmpty ? _imagePaths : null,
            );
        }
    }
    
    // Create supplier order with images
    Future<bool?> createSupplierOrder({
        required String supplier,
        required String orderDate,
        required BuildContext context, required SupplierOrderModal createsupplierorder,
    }) async {
        // Update controllers
        supplierController.text = supplier;
        orderDateController.text = orderDate;
        
        // Create order object
        final supplierOrder = SupplierOrderModal(
            supplier: supplier,
            orderDate: orderDate,
            grandTotal: grandTotal,
            products: _products,
            imagePaths: _imagePaths.isNotEmpty ? _imagePaths : null,
        );
        
        setIsLoading(true);
        _errorMessage = null;
        
        try {
            final result = await SupplierOrderService.createSupplierOrder(
                context: context,
                supplierOrder: supplierOrder,
                imagePaths: _imagePaths.isNotEmpty ? _imagePaths : null,
            );
            
            setIsLoading(false);
            
            if (result != null && result) {
                _isOrderCreated = true;
                // Clear data after successful creation
                clearAllData();
                notifyListeners();
                return true;
            } else if (result == null) {
                _errorMessage = 'Network error or authentication failed';
                notifyListeners();
                return null;
            } else {
                _errorMessage = 'Failed to create supplier order';
                notifyListeners();
                return false;
            }
        } catch (e) {
            setIsLoading(false);
            _errorMessage = 'Error: $e';
            notifyListeners();
            return false;
        }
    }
    
    // Alternative method using SupplierOrderModal object
    Future<bool?> createSupplierOrderFromModal({
        required SupplierOrderModal supplierOrder,
        required BuildContext context,
    }) async {
        setIsLoading(true);
        _errorMessage = null;
        
        try {
            final result = await SupplierOrderService.createSupplierOrder(
                context: context,
                supplierOrder: supplierOrder,
                imagePaths: supplierOrder.imagePaths,
            );
            
            setIsLoading(false);
            
            if (result != null && result) {
                _isOrderCreated = true;
                notifyListeners();
                return true;
            } else if (result == null) {
                _errorMessage = 'Network error or authentication failed';
                notifyListeners();
                return null;
            } else {
                _errorMessage = 'Failed to create supplier order';
                notifyListeners();
                return false;
            }
        } catch (e) {
            setIsLoading(false);
            _errorMessage = 'Error: $e';
            notifyListeners();
            return false;
        }
    }
    
    void setIsLoading(bool value) {
        _isLoading = value;
        notifyListeners();
    }
    
    // Validate form
    bool validateForm() {
        if (supplierController.text.isEmpty) {
            _errorMessage = 'Supplier is required';
            notifyListeners();
            return false;
        }
        
        if (orderDateController.text.isEmpty) {
            _errorMessage = 'Order date is required';
            notifyListeners();
            return false;
        }
        
        if (_products.isEmpty) {
            _errorMessage = 'At least one product is required';
            notifyListeners();
            return false;
        }
        
        _errorMessage = null;
        notifyListeners();
        return true;
    }
    
    // Helper method to create a product
    Product createProduct({
        required String productName,
        required int quantity,
        required double rate,
        double? pcs,
        double? netQty,
        String? uom,
        String? color,
        DateTime? requiredDate,
    }) {
        final amount = Product.calculateAmount(quantity, rate);
        
        return Product(
            product: productName,
            qty: quantity,
            pcs: pcs,
            netQty: netQty,
            uom: uom ?? "Nos",
            rate: rate,
            amount: amount,
            color: color,
            requiredDate: requiredDate,
        );
    }
    
    // Clear all data
    void clearAllData() {
        _products.clear();
        _imagePaths.clear();
        _currentOrder = null;
        _isOrderCreated = false;
        _errorMessage = null;
        supplierController.clear();
        orderDateController.clear();
        notifyListeners();
    }
    
    // Reset order creation status
    void resetOrderStatus() {
        _isOrderCreated = false;
        _errorMessage = null;
        notifyListeners();
    }
    
    @override
    void dispose() {
        supplierController.dispose();
        orderDateController.dispose();
        super.dispose();
    }
}