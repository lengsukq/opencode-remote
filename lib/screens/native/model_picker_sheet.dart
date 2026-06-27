import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';

/// Bottom sheet for searching and selecting AI models from providers.
class ModelPickerSheet extends StatefulWidget {
  final List<Provider> providers;
  final String? selectedId;
  final String? defaultModel;
  final ValueChanged<String> onSelect;

  const ModelPickerSheet({
    super.key,
    required this.providers,
    this.selectedId,
    this.defaultModel,
    required this.onSelect,
  });

  @override
  State<ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<ModelPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Provider> get _filtered {
    if (_query.isEmpty) return widget.providers;
    final q = _query.toLowerCase();
    return widget.providers.map((p) {
      final matched = p.models.where((m) =>
        m.name.toLowerCase().contains(q) ||
        m.id.toLowerCase().contains(q) ||
        p.name.toLowerCase().contains(q)
      ).toList();
      return Provider(id: p.id, name: p.name, models: matched);
    }).where((p) => p.models.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _query.isNotEmpty && _filtered.isEmpty
                    ? Center(child: Text('无匹配模型', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)))
                    : ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.only(bottom: 16),
                        children: _filtered.map((p) => _buildProviderGroup(p)).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Text('选择模型', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: '搜索模型...',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              suffixIcon: _query.isNotEmpty ? IconButton(
                icon: Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
              ) : null,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderFocused),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderGroup(Provider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(p.name, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        ...p.models.map((m) => _buildModelTile(m, p.id)),
      ],
    );
  }

  Widget _buildModelTile(ProviderModel m, String providerId) {
    final fullId = '$providerId/${m.id}';
    final isSelected = fullId == widget.selectedId || m.id == widget.defaultModel;
    return ListTile(
      dense: true,
      title: Text(m.name, style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
      subtitle: null,
      trailing: isSelected ? Icon(Icons.check, color: AppColors.primary, size: 18) : null,
      onTap: () => widget.onSelect(fullId),
    );
  }
}
