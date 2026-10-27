import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:resourceapp/Services/Supabase service.dart';
enum CourseResourceTab { pdfs, videos, pastQuestions }

class CourseDetail extends StatefulWidget {
  final String courseCode;
  final String level;
  final String semester;
  final bool isAdmin;

  const CourseDetail({
    super.key,
    required this.courseCode,
    required this.level,
    required this.semester,
    this.isAdmin = false,
  });

  @override
  State<CourseDetail> createState() => _CourseDetailState();
}

class _CourseDetailState extends State<CourseDetail> {
  static const Color kBackground = Color(0xFFF0ECF9);
  static const Color kPurple = Color(0xFF6A3DF0);
  static const Color kTitle = Color(0xFF2D1B69);

  CourseResourceTab _selectedTab = CourseResourceTab.pdfs;
  final SupabaseService _service = SupabaseService();

  // Upload's course list has no spaces ('CSC201'), but the Level pages
  // display/pass codes with a space ('CSC 201') for readability. Strip
  // the space only for the database lookup so the two formats match —
  // the displayed title (widget.courseCode) stays exactly as given.
  String get _queryCourseCode => widget.courseCode.replaceAll(' ', '');

  List<Map<String, dynamic>> _materials = [];
  bool _loading = true;
  String? _busyMaterialId; // shows a spinner on just the row being worked on

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  String get _materialTypeString => switch (_selectedTab) {
        CourseResourceTab.pdfs => 'pdf',
        CourseResourceTab.videos => 'video',
        CourseResourceTab.pastQuestions => 'pq',
      };

  Future<void> _loadMaterials() async {
    setState(() => _loading = true);
    final rows = await _service.materialsForCourse(
      courseCode: _queryCourseCode,
      materialType: _materialTypeString,
    );
    if (!mounted) return;
    setState(() {
      _materials = rows;
      _loading = false;
    });
  }

  void _onTabChanged(CourseResourceTab tab) {
    setState(() => _selectedTab = tab);
    _loadMaterials();
  }

  /// Downloads the file to a local temp path and hands it to the OS,
  /// which shows the native "Open with..." chooser (WPS Office, a PDF
  /// viewer, MX Player, etc.) — this needs an actual local file; a
  /// browser link can't trigger that chooser.
  Future<String> _saveLocally(Map<String, dynamic> material, {bool permanent = false}) async {
    final bytes = await _service.downloadFileBytes(material['file_url']);
    final dir = permanent
        ? await getApplicationDocumentsDirectory()
        : await getTemporaryDirectory();
    final fileName = material['file_name'] ?? 'file';
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<void> _openMaterial(Map<String, dynamic> material) async {
    setState(() => _busyMaterialId = material['id']);
    try {
      final path = await _saveLocally(material);
      // Only students' opens count toward "Recently Opened" — an admin
      // opening a file to check it isn't the same as a student reading it.
      if (!widget.isAdmin) {
        await _service.logActivity(
          materialId: material['id'],
          action: 'opened',
          fileName: material['file_name'] ?? 'file',
          materialType: material['material_type'] ?? '',
          level: widget.level,
          semester: widget.semester,
          courseCode: widget.courseCode,
          storagePath: material['file_url'],
        );
      }
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        _showSnack('Could not open: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnack('Could not open file: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busyMaterialId = null);
    }
  }

  Future<void> _downloadMaterial(Map<String, dynamic> material) async {
    setState(() => _busyMaterialId = material['id']);
    try {
      await _saveLocally(material, permanent: true);
      await _service.logActivity(
        materialId: material['id'],
        action: 'downloaded',
        fileName: material['file_name'] ?? 'file',
        materialType: material['material_type'] ?? '',
        level: widget.level,
        semester: widget.semester,
        courseCode: widget.courseCode,
        storagePath: material['file_url'],
      );
      _showSnack('Downloaded!', isError: false);
    } catch (e) {
      _showSnack('Could not download file: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busyMaterialId = null);
    }
  }

  Future<void> _deleteMaterial(Map<String, dynamic> material) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Delete Material', style: TextStyle(fontWeight: FontWeight.bold, color: kTitle)),
        content: Text('Delete "${material['file_name']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // Deleting only removes the storage file + the materials row.
      // material_activity keeps its own snapshot of this file's
      // details, so anyone's Recently Opened / Downloads history that
      // already logged it is untouched.
      await _service.deleteMaterial(
        materialId: material['id'],
        storagePath: material['file_url'],
      );
      _showSnack('Deleted successfully!', isError: false);
      _loadMaterials();
    } catch (e) {
      _showSnack('Could not delete: $e', isError: true);
    }
  }

  Future<void> _editMaterial(Map<String, dynamic> material) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: _selectedTab == CourseResourceTab.videos ? FileType.video : FileType.custom,
        allowedExtensions: _selectedTab == CourseResourceTab.videos ? null : ['pdf', 'doc', 'docx'],
      );
      if (result == null || result.files.isEmpty || result.files.first.path == null) return;

      final path = result.files.first.path!;
      final bytes = await File(path).readAsBytes();

      await _service.replaceMaterialFile(
        materialId: material['id'],
        oldStoragePath: material['file_url'],
        newBytes: bytes,
        newFileName: result.files.first.name,
        level: widget.level,
        semester: widget.semester,
        courseCode: _queryCourseCode,
      );
      _showSnack('Updated successfully!', isError: false);
      await _loadMaterials();
    } catch (e) {
      _showSnack('Could not update: $e', isError: true);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 38),

            // Back arrow -> pops back to the level's course grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kTitle),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 70),
                  Text(
                    widget.courseCode,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                       color: Color(0xD9150054),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PDFs / Videos / Past Questions toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: kPurple.withOpacity(0.22),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: _tab('PDFs', CourseResourceTab.pdfs)),
                    Expanded(child: _tab('Videos', CourseResourceTab.videos)),
                    Expanded(
                      child: _tab('Past Questions', CourseResourceTab.pastQuestions),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Content area for the selected tab
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPurple))
                  : _materials.isEmpty
                      ? Center(child: Text(_emptyMessage(), style: const TextStyle(color: kPurple)))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: GridView.builder(
                            itemCount: _materials.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 25,
                              childAspectRatio: 0.85,
                            ),
                            itemBuilder: (context, index) {
                              final material = _materials[index];
                              return _MaterialCard(
                                fileName: material['file_name'] ?? 'file',
                                dateLabel: _formatDate(material['created_at']),
                                tab: _selectedTab,
                                isAdmin: widget.isAdmin,
                                isBusy: _busyMaterialId == material['id'],
                                onOpen: () => _openMaterial(material),
                                onDownload: () => _downloadMaterial(material),
                                onEdit: () => _editMaterial(material),
                                onDelete: () => _deleteMaterial(material),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _emptyMessage() {
    switch (_selectedTab) {
      case CourseResourceTab.pdfs:
        return 'No PDFs uploaded yet for ${widget.courseCode}.';
      case CourseResourceTab.videos:
        return 'No videos uploaded yet for ${widget.courseCode}.';
      case CourseResourceTab.pastQuestions:
        return 'No past questions uploaded yet for ${widget.courseCode}.';
    }
  }

  Widget _tab(String label, CourseResourceTab tab) {
    final bool isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () => _onTabChanged(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? kPurple.withOpacity(0.95) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
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

class _MaterialCard extends StatelessWidget {
  final String fileName;
  final String dateLabel;
  final CourseResourceTab tab;
  final bool isAdmin;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.fileName,
    required this.dateLabel,
    required this.tab,
    required this.isAdmin,
    required this.isBusy,
    required this.onOpen,
    required this.onDownload,
    required this.onEdit,
    required this.onDelete,
  });

  String get _typeAssetPath => switch (tab) {
        CourseResourceTab.pdfs => 'assets/images/manage_materials2.png',
        CourseResourceTab.videos => 'assets/images/video icon.png',
        CourseResourceTab.pastQuestions => 'assets/images/past questions icon.png',
      };

  IconData get _typeFallbackIcon => switch (tab) {
        CourseResourceTab.pdfs => Icons.picture_as_pdf,
        CourseResourceTab.videos => Icons.videocam,
        CourseResourceTab.pastQuestions => Icons.quiz,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(15),
      child: Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECF9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: isBusy
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A3DF0), strokeWidth: 2))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  _typeAssetPath,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(_typeFallbackIcon, color: const Color(0xFF6A3DF0), size: 36),
                ),
                const SizedBox(height: 10),
                Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xD9150054)),
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(dateLabel, style: TextStyle(fontSize: 13, color: const Color(0xD9150054).withOpacity(0.85))),
                ],
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: isAdmin
                      ? [
                          _miniIcon(Icons.open_in_new, onOpen),
                          _miniIcon(Icons.delete_outline, onDelete, color: Colors.red),
                        ]
                      : [
                          _miniIcon(Icons.open_in_new, onOpen),
                          _miniIcon(Icons.download, onDownload),
                        ],
                ),
              ],
            ),
      ),
    );
  }

  Widget _miniIcon(IconData icon, VoidCallback onTap, {Color color = const Color(0xFF6A3DF0)}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}