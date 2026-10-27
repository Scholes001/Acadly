import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:resourceapp/Services/Supabase service.dart';
enum FilesTab { recentlyOpened, downloads }

class Files extends StatefulWidget {
  final VoidCallback onBackToHome;
  final FilesTab initialTab;

  const Files({
    super.key,
    required this.onBackToHome,
    this.initialTab = FilesTab.recentlyOpened,
  });

  @override
  State<Files> createState() => _FilesState();
}

class _FilesState extends State<Files> {
  static const Color kBackground = Color(0xFFF0ECF9);
  static const Color kPurple = Color(0xFF6A3DF0);
  static const Color kTitle = Color(0xFF2D1B69);

  late FilesTab _selectedTab = widget.initialTab;
  final SupabaseService _service = SupabaseService();

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final action = _selectedTab == FilesTab.recentlyOpened ? 'opened' : 'downloaded';
    final rows = await _service.getMyActivity(action);
    if (!mounted) return;
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  Future<void> _openItem(Map<String, dynamic> row) async {
    setState(() => _busyId = row['id']);
    try {
      final bytes = await _service.downloadFileBytes(row['storage_path']);
      final dir = await getTemporaryDirectory();
      final fileName = row['file_name'] ?? 'file';
      final path = '${dir.path}/$fileName';
      await File(path).writeAsBytes(bytes, flush: true);
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: ${result.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  String _materialTypeLabel(String? type) {
    switch (type) {
      case 'pdf':
        return 'PDF';
      case 'video':
        return 'Video';
      case 'pq':
        return 'Past Question';
      default:
        return type ?? '';
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 33),

            // Back arrow + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2D1B69)),
                    onPressed: widget.onBackToHome,
                  ),
                  const SizedBox(width: 85),
                  const Text(
                    'Files',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Color(0xD9150054),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),

            // Tab toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: kPurple.withOpacity(0.20),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tab('Recently Opened', FilesTab.recentlyOpened),
                    ),
                    Expanded(
                      child: _tab('Downloads', FilesTab.downloads),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPurple))
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            _selectedTab == FilesTab.recentlyOpened
                                ? 'Nothing opened yet.'
                                : 'Nothing downloaded yet.',
                            style: const TextStyle(color: kPurple),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final row = _items[index];
                            return _FileRow(
                              fileName: row['file_name'] ?? 'file',
                              materialType: row['material_type'] ?? '',
                              typeLabel: _materialTypeLabel(row['material_type']),
                              dateLabel: _formatDate(row['created_at']),
                              level: row['level'] ?? '',
                              semester: row['semester'] ?? '',
                              courseCode: row['course_code'] ?? '',
                              isBusy: _busyId == row['id'],
                              onTap: () => _openItem(row),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, FilesTab tab) {
    final bool isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = tab);
        _loadItems();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? kPurple.withOpacity(0.95) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : const Color(0xFF150054).withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final String fileName;
  final String materialType;
  final String typeLabel;
  final String dateLabel;
  final String level;
  final String semester;
  final String courseCode;
  final bool isBusy;
  final VoidCallback onTap;

  const _FileRow({
    required this.fileName,
    required this.materialType,
    required this.typeLabel,
    required this.dateLabel,
    required this.level,
    required this.semester,
    required this.courseCode,
    required this.isBusy,
    required this.onTap,
  });

  String get _typeAssetPath => switch (materialType) {
        'pdf' => 'assets/images/manage_materials2.png',
        'video' => 'assets/images/video icon.png',
        'pq' => 'assets/images/past questions icon.png',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE9DFFF).withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6A3DF0).withOpacity(0.28)),
        ),
        child: Row(
          children: [
            if (isBusy)
              const SizedBox(
                width: 26, height: 26,
                child: CircularProgressIndicator(color: Color(0xFF6A3DF0), strokeWidth: 2),
              )
            else
              Image.asset(
                _typeAssetPath,
                width: 26,
                height: 26,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.insert_drive_file, color: Color(0xFF6A3DF0), size: 26),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2D1B69)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$typeLabel  •  $courseCode  •  $level  •  $semester',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6A3DF0)),
                  ),
                  if (dateLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(dateLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF150054))),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF2D1B69)),
          ],
        ),
      ),
    );
  }
}