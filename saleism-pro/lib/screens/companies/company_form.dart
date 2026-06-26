import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/company_provider.dart';

class CompanyForm extends StatefulWidget {
  final Map<String, dynamic>? company;
  const CompanyForm({super.key, this.company});

  @override
  State<CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends State<CompanyForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _contact;
  late TextEditingController _phone;
  late TextEditingController _address;
  late TextEditingController _openingBalance;
  late TextEditingController _creditLimit;
  bool _saving = false;

  bool get isEdit => widget.company != null;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _name = TextEditingController(text: c?['name'] ?? '');
    _contact = TextEditingController(text: c?['contact_person'] ?? '');
    _phone = TextEditingController(text: c?['phone'] ?? '');
    _address = TextEditingController(text: c?['address'] ?? '');
    _openingBalance = TextEditingController(text: c != null ? '${c['opening_balance'] ?? 0}' : '0');
    _creditLimit = TextEditingController(text: c != null ? '${c['credit_limit'] ?? 0}' : '0');
  }

  @override
  void dispose() {
    _name.dispose(); _contact.dispose(); _phone.dispose();
    _address.dispose(); _openingBalance.dispose(); _creditLimit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _name.text.trim(),
      'contact_person': _contact.text.trim(),
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
      'opening_balance': double.tryParse(_openingBalance.text) ?? 0,
      'credit_limit': double.tryParse(_creditLimit.text) ?? 0,
    };
    final prov = context.read<CompanyProvider>();
    bool ok;
    if (isEdit) {
      ok = await prov.updateCompany(widget.company!['id'], data);
    } else {
      ok = await prov.addCompany(data);
    }
    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Company updated!' : 'Company added!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save company'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Company' : 'Add Company'),
        backgroundColor: AppColors.bgBlack,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Field(label: 'Company Name *', controller: _name, required: true),
            _Field(label: 'Contact Person', controller: _contact),
            _Field(label: 'Phone Number', controller: _phone, keyboardType: TextInputType.phone),
            _Field(label: 'Address', controller: _address, maxLines: 2),
            _Field(label: 'Opening Balance', controller: _openingBalance, keyboardType: TextInputType.number),
            _Field(label: 'Credit Limit', controller: _creditLimit, keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Update Company' : 'Add Company'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final TextInputType keyboardType;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      ),
    );
  }
}
