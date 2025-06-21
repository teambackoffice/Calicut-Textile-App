import 'package:flutter/material.dart';

class PurchaseOrderPage extends StatelessWidget {
  const PurchaseOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false,
        title: Text('Purchase Orders',
      style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold)),),

      
    );
  }
}