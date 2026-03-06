import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  int _currentStep = 1;

  // Form State
  String _selectedType = 'Product';
  String? _selectedCategory;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Image State
  List<XFile> _selectedImages = [];

  final List<String> _categories = [
    'Sharp Sand',
    'Granite',
    'Blocks',
    'Cement',
    'Iron Rods',
    'Paints',
    'Furniture',
    'Scaffolding',
  ];

  // --- LOGIC ---

  void _showCustomToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      _showCustomToast('Maximum 5 photos allowed');
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(0, 5);
        }
      });
      _showCustomToast('Photos added successfully');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _showCustomToast('Photo removed');
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _handlePublish() {
    _showCustomToast('Ad Published Successfully!');
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post an Ad',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Step $_currentStep of 3',
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 1: CATEGORY ---
  Widget _buildStep1() {
    bool isCompleted = _selectedCategory != null;
    return _buildStepCard(
      title: 'Select Category',
      children: [
        const Text(
          'Listing Type',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _typeButton('Product', null),
            const SizedBox(width: 8),
            _typeButton('Service', null),
            const SizedBox(width: 8),
            _typeButton('Property', Icons.home_outlined),
          ],
        ),
        const SizedBox(height: 25),
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
          menuMaxHeight: 300,
          dropdownColor: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          decoration: _inputDecoration('Choose a category').copyWith(
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          items: _categories
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: _actionButton(
            _nextStep,
            'Next: Upload Media',
            isPrimary: isCompleted,
          ),
        ),
      ],
    );
  }

  // --- STEP 2: MEDIA ---
  Widget _buildStep2() {
    bool isCompleted = _selectedImages.isNotEmpty;
    return _buildStepCard(
      title: 'Upload Photos',
      children: [
        const Text(
          'Add up to 5 photos (first photo will be the cover)',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return _buildAddPhotoButton();
              }
              return _buildImagePreview(index);
            },
          ),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                _previousStep,
                'Back',
                isPrimary: false,
                isOutline: true,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _actionButton(
                _nextStep,
                'Next: Details',
                isPrimary: isCompleted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.grey),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(File(_selectedImages[index].path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 15,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 10,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: const Text(
                'Cover',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  // --- STEP 3: DETAILS ---
  Widget _buildStep3() {
    bool isCompleted =
        _titleController.text.isNotEmpty && _priceController.text.isNotEmpty;
    return _buildStepCard(
      title: 'Product Details',
      children: [
        _fieldLabel('Title'),
        TextField(
          controller: _titleController,
          onChanged: (_) => setState(() {}),
          decoration: _inputDecoration('e.g., Premium Sharp Sand'),
        ),
        const SizedBox(height: 20),
        _fieldLabel('Description'),
        TextField(
          maxLines: 4,
          decoration: _inputDecoration('Describe your product...'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Price (₦)'),
                  TextField(
                    controller: _priceController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('75000'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Price Unit'),
                  TextField(decoration: _inputDecoration('per truck')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _fieldLabel('Location'),
        TextField(decoration: _inputDecoration('e.g., Ikeja, Lagos')),
        const SizedBox(height: 30),
        Row(
          children: [
            Flexible(
              flex: 2,
              child: SizedBox(
                width: double.infinity,
                child: _actionButton(
                  _previousStep,
                  'Back',
                  isPrimary: false,
                  isOutline: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 8,
              child: SizedBox(
                width: double.infinity,
                child: _actionButton(
                  _handlePublish,
                  'Publish Ad',
                  isPrimary: isCompleted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildStepCard({
    required String title,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    VoidCallback onTap,
    String text, {
    bool isPrimary = true,
    bool isOutline = false,
  }) {
    Color bgColor = isPrimary
        ? const Color(0xFFFF7043)
        : const Color(0xFFFFAB91);
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutline ? Colors.white : bgColor,
        foregroundColor: isOutline ? Colors.black87 : Colors.white,
        elevation: 0,
        side: isOutline
            ? BorderSide(color: Colors.grey.shade300)
            : BorderSide.none,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _typeButton(String label, IconData? icon) {
    bool isSelected = _selectedType == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF7043) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              if (icon != null) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF5F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _indicatorCircle(1),
        _indicatorLine(1),
        _indicatorCircle(2),
        _indicatorLine(2),
        _indicatorCircle(3),
      ],
    );
  }

  Widget _indicatorCircle(int step) {
    bool isActive = step <= _currentStep;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFF7043) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? const Color(0xFFFF7043) : Colors.grey.shade300,
        ),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _indicatorLine(int step) {
    bool isPassed = step < _currentStep;
    return Container(
      width: 60,
      height: 2,
      color: isPassed ? const Color(0xFFFF7043) : Colors.grey.shade300,
    );
  }
}
