import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PostAdScreen extends StatefulWidget {
  const PostAdScreen({super.key});

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  int _currentStep = 1;
  bool _isPublishing = false;

  // --- FORM STATE ---
  String _selectedType = 'Property';
  String _propertyStatus = 'For Rent';
  String? _selectedCategory;
  List<XFile> _selectedImages = [];
  int? _selectedCategoryId;

  // --- CONTROLLERS ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bedroomController = TextEditingController();
  final TextEditingController _sqftController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _priceUnitController = TextEditingController(
    text: 'per year',
  );
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _propertyCategories = [
    'Apartment',
    'House',
    'Commercial',
    'Land',
  ];
  final List<String> _productCategories = [
    'Sharp Sand',
    'Granite',
    'Blocks',
    'Cement',
    'Iron Rods',
    'Paints',
    'Furniture',
    'Scaffolding',
  ];
  final List<String> _serviceCategories = [
    'Logistics',
    'Borehole',
    'Cleaning',
    'Fumigation',
  ];

  final Map<String, int> _categoryIdMap = {
    'Sharp Sand': 1,
    'Granite': 2,
    'Blocks': 3,
    'Cement': 4,
    'Iron Rods': 5,
    'Paints': 6,
    'Furniture': 7,
    'Scaffolding': 8,
    'Logistics': 9,
    'Borehole': 10,
    'Cleaning': 11,
    'Fumigation': 12,
    'Apartment': 13,
    'House': 14,
    'Commercial': 15,
    'Land': 16,
  };

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateState);
    _priceController.addListener(_updateState);
    _locationController.addListener(_updateState);
    _bedroomController.addListener(_updateState);
    _sqftController.addListener(_updateState);
    _descriptionController.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _bedroomController.dispose();
    _sqftController.dispose();
    _priceController.dispose();
    _priceUnitController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isStepValid() {
    if (_currentStep == 1) return _selectedCategory != null;
    if (_currentStep == 2) return _selectedImages.isNotEmpty;

    bool commonFields =
        _titleController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        _locationController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;

    if (_selectedType == 'Property') {
      return commonFields &&
          _bedroomController.text.trim().isNotEmpty &&
          _sqftController.text.trim().isNotEmpty;
    }
    return commonFields;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          int spaceLeft = 5 - _selectedImages.length;
          if (spaceLeft > 0) {
            _selectedImages.addAll(images.take(spaceLeft));
          }
        });
      }
    } catch (e) {
      _showCustomToast(message: 'Error picking images: $e', isError: true);
    }
  }

  void _showCustomToast({required String message, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? Colors.red : Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _getVendorToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('vendor_auth_token');
  }

  Future<void> _handlePublish() async {
    setState(() => _isPublishing = true);

    try {
      final token = await _getVendorToken();
      if (token == null) throw 'Authentication required. Please login again.';
      if (_selectedCategoryId == null) throw 'Please select a valid category';

      // 1. DYNAMIC ROUTING
      String endpoint = _selectedType == 'Service' ? 'services' : 'products';
      String categoryKey = _selectedType == 'Service'
          ? 'service_category_id'
          : 'category_id';

      final url = Uri.parse(
        'https://sbraisolutions.com/api/v1/vendor/$endpoint',
      );
      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // 2. COMMON FIELDS
      request.fields[categoryKey] = _selectedCategoryId.toString();
      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['price'] = _priceController.text.trim();
      request.fields['price_unit'] = _priceUnitController.text.trim();
      request.fields['location'] = _locationController.text.trim();

      if (_selectedType == 'Property') {
        request.fields['property_status'] = _propertyStatus;
        request.fields['bedrooms'] = _bedroomController.text.trim();
        request.fields['sqft'] = _sqftController.text.trim();
      }

      // 3. IMAGE HANDLING
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        if (_selectedType == 'Service') {
          // If the server says images.0 must be a string, it wants Base64
          // We use explicit index keys: images.0, images.1 etc.
          final bytes = await File(image.path).readAsBytes();
          final String extension = path
              .extension(image.path)
              .replaceAll('.', '');
          final String base64Image =
              "data:image/${extension.isEmpty ? 'jpeg' : extension};base64,${base64Encode(bytes)}";

          request.fields['images[$i]'] = base64Image;
        } else {
          // Products/Properties use standard Multipart Files
          final file = File(image.path);
          final extension = path.extension(file.path).replaceAll('.', '');
          request.files.add(
            await http.MultipartFile.fromPath(
              'photos[]',
              file.path,
              contentType: MediaType(
                'image',
                extension.isEmpty ? 'jpeg' : extension,
              ),
            ),
          );
        }
      }

      // 4. EXECUTE
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // --- CRITICAL DEBUGGING ---
      debugPrint("--- SBRAI API DEBUG ---");
      debugPrint("Endpoint: $url");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      debugPrint("--- END DEBUG ---");

      if (!mounted) return;

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showCustomToast(
          message: responseData['message'] ?? 'Ad Published Successfully!',
        );
        Navigator.of(context).pop();
      } else {
        String errorMsg =
            responseData['message'] ?? 'Server Error: ${response.statusCode}';
        if (responseData['errors'] != null) {
          // Print nested validation errors if they exist
          errorMsg = responseData['errors'].toString();
        }
        throw errorMsg;
      }
    } catch (e) {
      debugPrint("Catch Error: $e");
      _showCustomToast(message: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post an Ad',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Step $_currentStep of 3',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isPublishing
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7D54)),
            )
          : Column(
              children: [
                const SizedBox(height: 20),
                _buildStepIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentStep = index + 1),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_buildStep1(), _buildStep2(), _buildStep3()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        children: List.generate(5, (index) {
          if (index % 2 == 0) {
            int stepNum = (index ~/ 2) + 1;
            bool active = _currentStep >= stepNum;
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFF7D54)
                    : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$stepNum',
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          return Expanded(
            child: Container(
              height: 2,
              color: _currentStep > (index ~/ 2) + 1
                  ? const Color(0xFFFF7D54)
                  : const Color(0xFFE5E7EB),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    List<String> currentList = _selectedType == 'Property'
        ? _propertyCategories
        : (_selectedType == 'Product'
              ? _productCategories
              : _serviceCategories);
    return _stepWrapper(
      title: 'Select Category',
      children: [
        _label('Listing Type'),
        Row(
          children: [
            _typeBtn('Product', null, const Color(0xFFFF7D54)),
            const SizedBox(width: 8),
            _typeBtn('Service', null, const Color(0xFF1E237E)),
            const SizedBox(width: 8),
            _typeBtn('Property', Icons.home_outlined, const Color(0xFFFF7D54)),
          ],
        ),
        if (_selectedType == 'Property') ...[
          const SizedBox(height: 15),
          _label('Property Type'),
          Row(
            children: [
              _subBtn('For Rent'),
              const SizedBox(width: 8),
              _subBtn('For Sale'),
            ],
          ),
        ],
        const SizedBox(height: 15),
        _label('Category'),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
          decoration: _inputStyle('Choose a category'),
          items: currentList
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() {
            _selectedCategory = v;
            _selectedCategoryId = _categoryIdMap[v];
          }),
        ),
        const SizedBox(height: 30),
        _cta('Next: Upload Media', () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }),
      ],
    );
  }

  Widget _buildStep2() {
    return _stepWrapper(
      title: 'Upload Photos',
      children: [
        const Text(
          'Add up to 5 photos',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _selectedImages.length < 5
              ? _selectedImages.length + 1
              : 5,
          itemBuilder: (context, index) {
            if (index == _selectedImages.length && _selectedImages.length < 5) {
              return GestureDetector(
                onTap: _pickImages,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Colors.black26),
                      Text(
                        'Add',
                        style: TextStyle(color: Colors.black26, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedImages[index].path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedImages.removeAt(index)),
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            _backBtn(),
            const SizedBox(width: 10),
            Expanded(
              child: _cta('Next: Details', () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return _stepWrapper(
      title: 'Listing Details',
      children: [
        _label('Ad Title'),
        TextField(
          controller: _titleController,
          decoration: _inputStyle('e.g. 10 Bags of Dangote Cement'),
        ),
        const SizedBox(height: 12),
        _label('Description'),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: _inputStyle('Describe your product...'),
        ),
        const SizedBox(height: 12),
        if (_selectedType == 'Property') ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Bedrooms'),
                    TextField(
                      controller: _bedroomController,
                      keyboardType: TextInputType.number,
                      decoration: _inputStyle('3'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Size (Sqft)'),
                    TextField(
                      controller: _sqftController,
                      keyboardType: TextInputType.number,
                      decoration: _inputStyle('1200'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Price (₦)'),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputStyle('5000'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Unit'),
                  TextField(
                    controller: _priceUnitController,
                    decoration: _inputStyle('per bag'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _label('Location'),
        TextField(
          controller: _locationController,
          decoration: _inputStyle('State, City or Street'),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            _backBtn(),
            const SizedBox(width: 10),
            Expanded(child: _cta('Publish Ad Now', _handlePublish)),
          ],
        ),
      ],
    );
  }

  Widget _stepWrapper({required String title, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F4F7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5, top: 5),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    ),
  );

  InputDecoration _inputStyle(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF1F4F7),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );

  Widget _typeBtn(String label, IconData? icon, Color activeColor) {
    bool isSelected = _selectedType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedType = label;
          _selectedCategory = null;
          _selectedCategoryId = null;
          if (label == 'Product') _priceUnitController.text = 'per item';
          if (label == 'Service') _priceUnitController.text = 'per job';
          if (label == 'Property') _priceUnitController.text = 'per year';
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.black12,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              if (icon != null) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subBtn(String label) {
    bool isSelected = _propertyStatus == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _propertyStatus = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF7D54) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.black12,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cta(String text, VoidCallback onTap) {
    bool isValid = _isStepValid();
    return ElevatedButton(
      onPressed: isValid ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isValid
            ? const Color(0xFFFF7D54)
            : const Color(0xFFE5E7EB),
        disabledBackgroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.white : Colors.black26,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _backBtn() => OutlinedButton(
    onPressed: () => _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: const Text(
      'Back',
      style: TextStyle(color: Colors.black, fontSize: 14),
    ),
  );
}
