import 'package:flutter/material.dart';
import '../../models.dart';
import '../../strings.dart';
import '../../theme.dart';
import '../../utils/glass_effect.dart';
import '../../widgets/app_section_header.dart';

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
    return widget.providers
        .map((p) {
          final matched = p.models
              .where(
                (m) =>
                    m.name.toLowerCase().contains(q) ||
                    m.id.toLowerCase().contains(q) ||
                    p.name.toLowerCase().contains(q),
              )
              .toList();
          return Provider(id: p.id, name: p.name, models: matched);
        })
        .where((p) => p.models.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return GlassSheet(
      borderRadius: 20,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
                      ? Center(
                          child: Text(
                            S.noMatchModel,
                            style: TextStyle(
                              color: isDarkMode(context)
                                  ? DarkColors.textTertiary
                                  : AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.only(bottom: 16),
                          children: _filtered
                              .map((p) => _buildProviderGroup(p))
                              .toList(),
                        ),
                ),
              ],
            ),
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
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDarkMode(context)
                  ? DarkColors.textTertiary
                  : AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            S.selectModel,
            style: TextStyle(
              color: isDarkMode(context)
                  ? DarkColors.textPrimary
                  : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            style: TextStyle(
              color: isDarkMode(context)
                  ? DarkColors.textPrimary
                  : AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: S.searchModelHint,
              hintStyle: TextStyle(
                color: isDarkMode(context)
                    ? DarkColors.textTertiary
                    : AppColors.textTertiary,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDarkMode(context)
                    ? DarkColors.textSecondary
                    : AppColors.textSecondary,
                size: 20,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDarkMode(context)
                            ? DarkColors.textSecondary
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDarkMode(context)
                  ? DarkColors.background
                  : AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDarkMode(context)
                      ? DarkColors.primary
                      : AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
        AppSectionHeader(p.name),
        ...p.models.map((m) => _buildModelTile(m, p.id)),
      ],
    );
  }

  Widget _buildModelTile(ProviderModel m, String providerId) {
    final fullId = '$providerId/${m.id}';
    final isSelected =
        fullId == widget.selectedId || m.id == widget.defaultModel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode(context) ? DarkColors.surface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ResponsiveTheme.getShadow(context, level: 1),
        ),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            m.name,
            style: TextStyle(
              color: isDarkMode(context)
                  ? DarkColors.textPrimary
                  : AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check,
                  color: isDarkMode(context)
                      ? DarkColors.primary
                      : AppColors.primary,
                  size: 18,
                )
              : null,
          onTap: () => widget.onSelect(fullId),
        ),
      ),
    );
  }
}
