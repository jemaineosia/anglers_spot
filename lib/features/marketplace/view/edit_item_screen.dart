import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/storage_service.dart';
import '../models/marketplace_item.dart';
import '../providers/marketplace_provider.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final MarketplaceItem item;

  const EditItemScreen({super.key, required this.item});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;

  String? _selectedCategory;
  String? _selectedCondition;
  final List<String> _existingImageUrls = [];
  final List<File> _newImages = [];
  bool _isLoading = false;

  final _categories = [
    'Rods',
    'Reels',
    'Lures',
    'Tackle',
    'Boats',
    'Electronics',
    'Clothing',
    'Accessories',
    'Other',
  ];

  final _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
    _priceController = TextEditingController(
      text: widget.item.price.toStringAsFixed(2),
    );
    _locationController = TextEditingController(
      text: widget.item.location ?? '',
    );
    _selectedCategory = widget.item.category;
    _selectedCondition = widget.item.condition;
    if (widget.item.imageUrls != null && widget.item.imageUrls!.isNotEmpty) {
      _existingImageUrls.addAll(widget.item.imageUrls!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final totalImages = _existingImageUrls.length + _newImages.length;
    if (totalImages >= 5) return;

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(
          pickedFiles.take(5 - totalImages).map((xFile) => File(xFile.path)),
        );
      });
    }
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload new images
      final newImageUrls = <String>[];
      if (_newImages.isNotEmpty) {
        final storageService = StorageService();
        for (final image in _newImages) {
          final url = await storageService.uploadMarketplaceImage(image);
          newImageUrls.add(url);
        }
      }

      // Combine existing and new image URLs
      final allImageUrls = [..._existingImageUrls, ...newImageUrls];

      final service = ref.read(marketplaceServiceProvider);
      await service.updateItem(
        itemId: widget.item.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        condition: _selectedCondition,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        imageUrls: allImageUrls.isEmpty ? null : allImageUrls,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _existingImageUrls.length + _newImages.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images
            if (totalImages > 0) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: totalImages,
                  itemBuilder: (context, index) {
                    final isExisting = index < _existingImageUrls.length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isExisting
                                ? Image.network(
                                    _existingImageUrls[index],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    _newImages[index -
                                        _existingImageUrls.length],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                padding: const EdgeInsets.all(4),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isExisting) {
                                    _existingImageUrls.removeAt(index);
                                  } else {
                                    _newImages.removeAt(
                                      index - _existingImageUrls.length,
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (totalImages < 5)
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text('Add Photos ($totalImages/5)'),
              ),
            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Shimano Fishing Rod',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price *',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Please enter a valid price';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() => _selectedCategory = value);
                    },
            ),
            const SizedBox(height: 16),

            // Condition
            DropdownButtonFormField<String>(
              initialValue: _selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() => _selectedCondition = value);
                    },
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'City, State',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe your item...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _isLoading ? null : _updateItem,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Item'),
            ),
          ],
        ),
      ),
    );
  }
}
