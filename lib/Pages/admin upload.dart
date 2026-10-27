import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resourceapp/Services/Supabase service.dart';

/// -----------------------------------------------------------------------
/// NOTE: this page uses two extra packages that must be added to
/// pubspec.yaml if they aren't already there:
///
///   dependencies:
///     file_picker: ^8.1.2
///     image_picker: ^1.1.2
///
/// then run `flutter pub get`.
/// -----------------------------------------------------------------------

class Upload extends StatefulWidget {
  /// If Upload is one of AdminBottomNav's IndexedStack pages, pass a
  /// callback here (e.g. `() => setState(() => _selectedIndex = 0)`)
  /// so the back arrow switches tabs instead of trying to pop a route
  /// that was never pushed. If null, the back arrow falls back to a
  /// normal Navigator.pop — correct for the case where Upload WAS
  /// pushed directly (e.g. from a "Upload Materials" tile).
  final VoidCallback? onBack;

  const Upload({super.key, this.onBack});

  @override
  State<Upload> createState() => _UploadState();
}

enum MaterialType { pdf, video, pq }

class _UploadState extends State<Upload> {
  // Colors — same palette as Sign Up / Dashboard
  final bgColor = const Color(0xFFF0ECF9);
  final titleColor = const Color(0xD9150054);
  final labelColor = const Color(0x9C150054);
  final fieldBorder = const Color(0x4F6A3DF0);
  final dropdownHintColor = const Color(0xAB150054);
  final btnColor = const Color(0xF26A3DF0);
  final purple = const Color(0xFF6A3DF0);

  String? selectedLevel;
  String? selectedSemester;
  String? selectedCourse;

  MaterialType materialType = MaterialType.pdf;

  String? pickedFileName;
  String? pickedFilePath;

  final SupabaseService _service = SupabaseService();
  bool _submitting = false;

  final levels = ['100 Level', '200 Level', '300 Level', '400 Level', '500 Level'];
  final semesters = ['First Semester', 'Second Semester'];

  // Real FUTA B.Tech Information Technology curriculum (from the course form).
  // Course codes only — no titles.
  final Map<String, Map<String, List<String>>> courseData = {
    '100 Level': {
      'First Semester': [
        'BIO101',
        'BIO103',
        'CSC101',
        'CHE101',
        'CHE103',
        'GNS101',
        'GNS103',
        'MEE101',
        'MTS101',
        'PHY101',
        'PHY107',
      ],
      'Second Semester': [
        'CSC102',
        'IFT102',
        'CHE102',
        'CHE104',
        'GNS102',
        'GNS106',
        'MTS102',
        'PHY102',
        'PHY108',
      ],
    },
    '200 Level': {
      'First Semester': [
        'CSC201',
        'CSC203',
        'CSC205',
        'IFT201',
        'GNS201',
        'MTS201',
        'MTS203',
        'MTS209',
      ],
      'Second Semester': [
        'CSC202',
        'CSC204',
        'SEN204',
        'SEN206',
        'SEN208',
        'IFT202',
        'IFT204',
        'CSP210',
        'ECN214',
      ],
    },
    '300 Level': {
      'First Semester': [
        'CSC305',
        'CSC307',
        'CSC309',
        'CSC315',
        'SEN305',
        'SEN307',
        'IFT301',
        'IFT303',
        'IFT305',
        'EMT301',
      ],
      'Second Semester': [
        'CSC310',
        'SEN306',
        'SEN310',
        'IFT302',
        'IFT304',
        'IFT306',
        'MTS202',
        'STA306',
        'EMT302',
      ],
    },
    '400 Level': {
      'First Semester': [
        'CSC401',
        'CSC403',
        'CSC415',
        'CSC411',
        'SEN403',
        'IFT401',
        'IFT403',
        'IFT405',
        'IFT407',
        'IFT409',
      ],
      'Second Semester': [
        'IFT402',
        'IFT404',
        'IFT406',
      ],
    },
    '500 Level': {
      'First Semester': [
        'CSC505',
        'CSC509',
        'IFT501',
        'IFT503',
        'IFT505',
        'IFT507',
        'IFT509',
        'IFT599',
      ],
      'Second Semester': [
        'CSC508',
        'CSC514',
        'IFT502',
        'IFT504',
        'IFT506',
        'IFT508',
        'IFT510',
        'IFT512',
      ],
    },
  };

  List<String> get availableCourses {
    if (selectedLevel == null || selectedSemester == null) return [];
    return courseData[selectedLevel]?[selectedSemester] ?? [];
  }

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: dropdownHintColor.withOpacity(0.6)),
      filled: true,
      fillColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder, width: 1.4)),
    );
  }

  void _goToDashboard() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _showUploadOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x33150054),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined, color: purple),
                  title: Text('Take a Photo/Video', style: TextStyle(color: titleColor)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromCamera();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: purple),
                  title: Text('Choose from Gallery', style: TextStyle(color: titleColor)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.folder_open_outlined, color: purple),
                  title: Text('Choose from Files', style: TextStyle(color: titleColor)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromFiles();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    try {
      final XFile? file = materialType == MaterialType.video
          ? await picker.pickVideo(source: ImageSource.camera)
          : await picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        setState(() {
          pickedFileName = file.name;
          pickedFilePath = file.path;
        });
      }
    } catch (e) {
      _showError('Could not open camera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    try {
      final XFile? file = materialType == MaterialType.video
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          pickedFileName = file.name;
          pickedFilePath = file.path;
        });
      }
    } catch (e) {
      _showError('Could not open gallery: $e');
    }
  }

  Future<void> _pickFromFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: materialType == MaterialType.video ? FileType.video : FileType.custom,
        allowedExtensions: materialType == MaterialType.video ? null : ['pdf', 'doc', 'docx'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedFileName = result.files.first.name;
          pickedFilePath = result.files.first.path;
        });
      }
    } catch (e) {
      _showError('Could not open files: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (selectedLevel == null ||
        selectedSemester == null ||
        selectedCourse == null ||
        pickedFilePath == null) {
      _showError('Please fill in all fields and select a file.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final bytes = await File(pickedFilePath!).readAsBytes();

      final String materialTypeString = switch (materialType) {
        MaterialType.pdf => 'pdf',
        MaterialType.video => 'video',
        MaterialType.pq => 'pq',
      };

      final String storagePath = await _service.uploadFile(
        bytes: bytes,
        fileName: pickedFileName ?? 'file',
        level: selectedLevel!,
        semester: selectedSemester!,
        courseCode: selectedCourse!,
      );

      await _service.insertMaterialRecord(
        level: selectedLevel!,
        semester: selectedSemester!,
        courseCode: selectedCourse!,
        materialType: materialTypeString,
        fileUrl: storagePath,
        fileName: pickedFileName ?? 'file',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploaded Successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        selectedCourse = null;
        pickedFileName = null;
        pickedFilePath = null;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _materialTypeButton({
    required MaterialType type,
    required String assetPath,
    required String label,
  }) {
    final bool selected = materialType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            materialType = type;
            // Clear a previously picked file since the accepted type changed.
            pickedFileName = null;
            pickedFilePath = null;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? purple : bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? purple : fieldBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                assetPath,
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 46, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: back arrow -> Dashboard, title
              Row(
                children: [
                  GestureDetector(
                    onTap: _goToDashboard,
                    child: Icon(Icons.arrow_back, color: Color(0xFF2D1B69), size: 24),
                  ),
                  const SizedBox(width: 55),
                  Text(
                    'Upload Material',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Color(0xD9150054),),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Level
              Text('Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                icon: Icon(Icons.keyboard_arrow_down, color: purple),
                hint: Text('Select Level', style: TextStyle(color: Color(0x4F150054).withOpacity(0.60), fontSize: 14)),
                decoration: fieldDecoration(''),
                style: TextStyle(color: titleColor, fontSize: 14),
                items: levels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedLevel = value;
                    selectedCourse = null; // reset dependent field
                  });
                },
              ),
              const SizedBox(height: 17),

              // Semester
              Text('Semester', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedSemester,
                icon: Icon(Icons.keyboard_arrow_down, color: purple),
                hint: Text('Select Semester', style: TextStyle(color: Color(0x4F150054).withOpacity(0.60), fontSize: 14)),
                decoration: fieldDecoration(''),
                style: TextStyle(color: titleColor, fontSize: 14),
                items: semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSemester = value;
                    selectedCourse = null; // reset dependent field
                  });
                },
              ),
              const SizedBox(height: 17),

              // Course — depends on Level + Semester
              Text('Course', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedCourse,
                icon: Icon(Icons.keyboard_arrow_down, color: purple),
                hint: Text(
                  selectedLevel == null || selectedSemester == null
                      ? 'Select Course'
                      : 'Select Course',
                  style: TextStyle(color: Color(0x4F150054).withOpacity(0.60), fontSize: 14),
                ),
                decoration: fieldDecoration(''),
                style: TextStyle(color: titleColor, fontSize: 14),
                items: availableCourses
                    .map((course) => DropdownMenuItem(value: course, child: Text(course, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: availableCourses.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          selectedCourse = value;
                        });
                      },
              ),
              const SizedBox(height: 17),

              // Material Type
              Text('Material Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _materialTypeButton(
                    type: MaterialType.pdf,
                    assetPath: 'assets/images/pdf_icon.png',
                    label: 'PDF',
                  ),
                  _materialTypeButton(
                    type: MaterialType.video,
                    assetPath: 'assets/images/video icon.png',
                    label: 'Video',
                  ),
                  _materialTypeButton(
                    type: MaterialType.pq,
                    assetPath: 'assets/images/past questions icon.png',
                    label: 'PQ',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Upload box
              GestureDetector(
                onTap: _showUploadOptions,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 21),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: fieldBorder),
                  ),
                  child: Column(
                    children: [
                      Image.asset('assets/images/upload_cloud2.png', width: 30, height: 30),
                      const SizedBox(height: 6),
                      Text(
                        pickedFileName ?? 'Tap to Upload File',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: titleColor),
                      ),
                      if (pickedFileName == null) ...[
                        Text(
                          '(PDF, Video or Document)',
                          style: TextStyle(fontSize: 11, color: dropdownHintColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Max file size 50MB',
                  style: TextStyle(fontSize: 11, color: dropdownHintColor),
                ),
              ),

              // Pushes the button to the bottom of the available space
              // so everything fits on one screen without scrolling.
            const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text(
                          'Upload Material',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}