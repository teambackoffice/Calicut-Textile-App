import 'package:flutter/material.dart';

class DialogBoxItems extends StatelessWidget {
  const DialogBoxItems({
    super.key,
    required GlobalKey<FormState> formKey,
    required TextEditingController itemCodeController,
    required TextEditingController itemNameController,
    required TextEditingController quantityController,
    required TextEditingController rateController,
    required TextEditingController colorController,
  }) : _formKey = formKey, _itemCodeController = itemCodeController, _itemNameController = itemNameController, _quantityController = quantityController, _rateController = rateController, _colorController = colorController;

  final GlobalKey<FormState> _formKey;
  final TextEditingController _itemCodeController;
  final TextEditingController _itemNameController;
  final TextEditingController _quantityController;
  final TextEditingController _rateController;
  final TextEditingController _colorController;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Code & Name Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _itemCodeController,
                          validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          decoration: InputDecoration(
                            hintText: 'Enter item code',
                            
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              
                            ),
                           
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              
                  // QR Code Scanner Button
                  
                ],
              ),
    
              const SizedBox(height: 24),
    
              // Item Name
              Text(
                'Item Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _itemNameController,
                validator: (value) => value?.isEmpty == true ? 'Item name is required' : null,
                decoration: InputDecoration(
                  hintText: 'Enter item name',
                  
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                   
                  ),
                  
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                ),
              ),
    
              const SizedBox(height: 24),
    
              // Quantity and Rate Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            if (int.tryParse(value!) == null) return 'Invalid';
                            if (int.parse(value) <= 0) return 'Must be > 0';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: '0',
                            
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                           
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            if (double.tryParse(value!) == null) return 'Invalid';
                            if (double.parse(value) <= 0) return 'Must be > 0';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: '0.00',
                           
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                           
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    
              const SizedBox(height: 24),
    
              // Color
              Text(
                'Color (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _colorController,
                decoration: InputDecoration(
                  hintText: 'Enter color',
                  
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                ),
              ),
    
              // const SizedBox(height: 24),
    
              // Quick calculation preview
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: Colors.blue.shade50,
              //     borderRadius: BorderRadius.circular(16),
              //     border: Border.all(
              //       width: 1,
              //     ),
              //   ),
              //   child: Row(
              //     children: [
                    
              //       const SizedBox(width: 12),
              //       Text(
              //         'Total: ',
              //         style: TextStyle(
              //           fontSize: 16,
              //           fontWeight: FontWeight.w600,
              //           color: Colors.blue.shade800,
              //         ),
              //       ),
              //       Text(
              //         '200',
              //         style: TextStyle(
              //           fontSize: 18,
              //           fontWeight: FontWeight.bold,
              //           color: Colors.blue.shade700,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

