import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/address_api.dart';
import '../models/customer_address.dart';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({this.address, super.key});

  final CustomerAddress? address;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final AddressApi _addressApi = AddressApi();
  late final TextEditingController _recipientController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressLineController;
  late final TextEditingController _wardController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _noteController;
  late bool _isDefault;
  bool _isSubmitting = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _recipientController = TextEditingController(text: address?.recipientName);
    _phoneController = TextEditingController(text: address?.phone);
    _addressLineController = TextEditingController(text: address?.addressLine);
    _wardController = TextEditingController(text: address?.ward);
    _districtController = TextEditingController(text: address?.district);
    _cityController = TextEditingController(text: address?.city);
    _noteController = TextEditingController(text: address?.note);
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      if (_isEditing) {
        await _addressApi.updateAddress(
          id: widget.address!.id,
          recipientName: _recipientController.text,
          phone: _phoneController.text,
          addressLine: _addressLineController.text,
          ward: _wardController.text,
          district: _districtController.text,
          city: _cityController.text,
          note: _noteController.text,
          isDefault: _isDefault,
        );
      } else {
        await _addressApi.createAddress(
          recipientName: _recipientController.text,
          phone: _phoneController.text,
          addressLine: _addressLineController.text,
          ward: _wardController.text,
          district: _districtController.text,
          city: _cityController.text,
          note: _noteController.text,
          isDefault: _isDefault,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Đã cập nhật địa chỉ' : 'Đã thêm địa chỉ'),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu địa chỉ. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Thông tin người nhận',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _recipientController,
                textInputAction: TextInputAction.next,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Họ tên người nhận',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _requiredValidator('Vui lòng nhập tên người nhận'),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: _requiredValidator('Vui lòng nhập số điện thoại'),
              ),
              const SizedBox(height: 16),
              Text(
                'Địa chỉ nhận hàng',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressLineController,
                textInputAction: TextInputAction.next,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Số nhà, tên đường',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: _requiredValidator('Vui lòng nhập địa chỉ'),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _wardController,
                textInputAction: TextInputAction.next,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Phường/Xã'),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _districtController,
                textInputAction: TextInputAction.next,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Quận/Huyện'),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _cityController,
                textInputAction: TextInputAction.next,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Tỉnh/Thành phố'),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  value: _isDefault,
                  onChanged: widget.address?.isDefault == true
                      ? null
                      : (value) => setState(() => _isDefault = value),
                  title: const Text(
                    'Đặt làm địa chỉ mặc định',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: widget.address?.isDefault == true
                      ? const Text('Đây đang là địa chỉ mặc định.')
                      : const Text('Dùng địa chỉ này khi chọn giao hàng.'),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSubmitting ? 'Đang lưu...' : 'Lưu địa chỉ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _requiredValidator(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }
}
