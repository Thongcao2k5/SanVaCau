import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../booking/models/court.dart';
import '../../booking/pages/court_detail_page.dart';
import '../../news/pages/news_detail_page.dart';
import '../../products/pages/product_detail_page.dart';
import '../data/search_api.dart';
import '../models/search_result.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchApi _searchApi = SearchApi();

  Timer? _debounceTimer;
  String _currentQuery = '';
  String _currentType = 'ALL';

  bool _isLoading = false;
  String? _error;
  SearchData? _searchData;

  final List<String> _types = ['ALL', 'PRODUCT', 'COURT', 'BRANCH', 'NEWS'];
  final Map<String, String> _typeLabels = {
    'ALL': 'Tất cả',
    'PRODUCT': 'Sản phẩm',
    'COURT': 'Sân cầu',
    'BRANCH': 'Chi nhánh',
    'NEWS': 'Tin tức',
  };

  final Map<String, String> _metadataLabels = {
    'branchId': 'Mã chi nhánh',
    'branchName': 'Chi nhánh',
    'branchAddress': 'Địa chỉ chi nhánh',
    'status': 'Trạng thái',
    'phone': 'Số điện thoại',
    'openingTime': 'Giờ mở cửa',
    'closingTime': 'Giờ đóng cửa',
    'brandId': 'Mã thương hiệu',
    'brandName': 'Thương hiệu',
    'categoryId': 'Mã danh mục',
    'categoryName': 'Danh mục',
    'isFeatured': 'Nổi bật',
    'publishedAt': 'Ngày đăng',
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _currentQuery) return;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _currentQuery = query;
      });
      _performSearch();
    });
  }

  void _onTypeChanged(String type) {
    if (type == _currentType) return;
    setState(() {
      _currentType = type;
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (_currentQuery.length < 2) {
      setState(() {
        _searchData = null;
        _error = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _searchApi.getSearchResults(
        query: _currentQuery,
        type: _currentType,
      );
      if (mounted) {
        setState(() {
          _searchData = data;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Có lỗi xảy ra khi tìm kiếm';
          _isLoading = false;
        });
      }
    }
  }

  void _showDetailDialog(SearchResultItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.subtitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (item.metadata.isNotEmpty)
                ...item.metadata.entries.map((e) {
                  final label = _metadataLabels[e.key] ?? e.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('$label: ${e.value}'),
                  );
                }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(SearchResultItem item) {
    switch (item.type) {
      case 'PRODUCT':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(productId: item.id),
          ),
        );
        break;
      case 'NEWS':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(newsId: item.id),
          ),
        );
        break;
      case 'COURT':
        final court = Court(
          id: item.id,
          name: item.title,
          branchId: item.metadata['branchId']?.toString() ?? '',
          branchName: item.metadata['branchName']?.toString(),
          branchAddress: item.metadata['branchAddress']?.toString(),
          description: item.subtitle.isNotEmpty ? item.subtitle : null,
          status: item.metadata['status']?.toString() ?? 'ACTIVE',
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CourtDetailPage(court: court),
          ),
        );
        break;
      case 'BRANCH':
      default:
        _showDetailDialog(item);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm (ít nhất 2 ký tự)...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: AppColors.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          style: const TextStyle(color: AppColors.onPrimary),
          cursorColor: AppColors.onPrimary,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
            setState(() {
              _currentQuery = _searchController.text.trim();
            });
            _performSearch();
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _types.map((type) {
                final isSelected = _currentType == type;
                final count = _searchData?.counts[type] ?? 0;
                final label = _typeLabels[type] ?? type;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _searchData != null && type != 'ALL'
                          ? '$label ($count)'
                          : label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (selected) {
                      if (selected) _onTypeChanged(type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Lỗi tìm kiếm',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuery.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'Nhập từ khóa',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_searchData != null && _searchData!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_searchData == null) {
      return const SizedBox.shrink();
    }

    final items = _searchData!.items;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => _onItemTapped(item),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.image,
                                color: AppColors.textSecondary,
                              ),
                        )
                      : const Icon(Icons.image, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeLabels[item.type] ?? item.type,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
