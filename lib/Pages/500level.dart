import 'package:flutter/material.dart';
import 'package:resourceapp/Pages/Resources Page.dart';
import 'package:resourceapp/Pages/course detail page.dart';

class _Course {
  final String code;
  final String title;
  const _Course(this.code, this.title);
}

class Level5 extends StatelessWidget {
  final Semester initialSemester;
  final bool isAdmin;
  const Level5({super.key, required this.initialSemester, this.isAdmin = false});

  static const Color kBackground = Color(0xFFF0ECF9);
  static const Color kPurple = Color(0xFF6A3DF0);
  static const Color kTitle = Color(0xFF2D1B69);

  static const List<_Course> _firstSemesterCourses = [
    _Course('CSC 505', 'Fault-Tolerant Computing'),
    _Course('CSC 509', 'AI and Soft Computing'),
    _Course('IFT 501', 'Network Analysis and Design'),
    _Course('IFT 503', 'Information Assurance'),
    _Course('IFT 505', 'System Administration'),
    _Course('IFT 507', 'Social Issues'),
    _Course('IFT 509', 'Research Methodology'),
    _Course('IFT 599', "Final Year Student's Project"),
  ];

  static const List<_Course> _secondSemesterCourses = [
    _Course('CSC 508', 'Modelling and Simulation'),
    _Course('CSC 514', 'Performance Evaluation'),
    _Course('IFT 502', 'Data Analytics'),
    _Course('IFT 504', 'System Integration'),
    _Course('IFT 506', 'Special Topics in Information Technology'),
    _Course('IFT 508', 'Virtual Data Storage'),
    _Course('IFT 510', 'Global IT Project Management'),
    _Course('IFT 512', 'Signals and Networks'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isFirst = initialSemester == Semester.first;
    final List<_Course> courses =
        isFirst ? _firstSemesterCourses : _secondSemesterCourses;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 38),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: kTitle),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 40),
                    Text(
                      isFirst ? 'First Semester' : 'Second Semester',
                      style: const TextStyle(
                        fontSize: 26,
                      fontWeight: FontWeight.w500,
                       color: Color(0xD9150054),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '500 Level (Information Technology)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400,
                       color: Color(0xD9150054).withOpacity(0.85)),
                ),
              ),
              const SizedBox(height: 23),

              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 25,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return _CourseCard(
                    code: course.code,
                    title: course.title,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetail(
                            courseCode: course.code,
                            level: '500 Level',
                            semester: isFirst ? 'First Semester' : 'Second Semester',
                            isAdmin: isAdmin,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String code;
  final String title;
  final VoidCallback onTap;

  const _CourseCard({
    required this.code,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/book.png',
              width: 55,
              height: 55,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A3DF0).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description, color: Colors.white, size: 18),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              code,
              style:  TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 20,
               color: Color(0xD9150054).withOpacity(0.85)
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xD9150054).withOpacity(0.85)
              ),
            ),
          ],
        ),
      ),
    );
  }
}