import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';

class InstructionsPage extends StatefulWidget {
  const InstructionsPage({Key? key}) : super(key: key);

  @override
  State<InstructionsPage> createState() => _InstructionsPageState();
}

class _InstructionsPageState extends State<InstructionsPage> {
  int currentStep = 1;
  int totalSteps = 3;

  final List<InstructionStep> steps = [
    InstructionStep(
      title: 'تكلّم بوضوح',
      description:
          'تكلّم ببطء ووضوح أمام الكاميرا مع تسجيل الصوت — ندمج صورة الشفاه مع الصوت لتحسين الدقة',
      step: 1,
    ),
    InstructionStep(
      title: 'تأكد من وضعية الكاميرا والصوت',
      description:
          'تأكد أن وجهك مضاء جيدًا وأن الكاميرا تلتقط شفتيك بوضوح، وحرصًا على الجودة قلل الضوضاء المحيطة أثناء تسجيل الصوت',
      step: 2,
    ),
    InstructionStep(
      title: 'عرض النتيجة',
      description:
          'سيتم تحويل الكلام إلى نص وسيظهر على الشاشة. التطبيق يدمج الصوت مع صورة الشفاه لتحسين دقة الاستنتاج.',
      step: 3,
    ),
  ];

  void _nextStep() {
    if (currentStep < totalSteps) {
      setState(() {
        currentStep++;
      });
    } else {
      context.push(AppRoutes.permissions);
    }
  }

  void _previousStep() {
    if (currentStep > 1) {
      setState(() {
        currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStep - 1];

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: 20),
                // Back Arrow Button with Red Circle Background
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: _previousStep,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFFEF6E6E),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Title
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 60),
                // Icon with Custom Design - Changes based on step
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main icon changes based on current step
                    if (currentStep == 1)
                      Icon(
                        Icons.volume_up,
                        size: 120,
                        color: Color(0xFFD32F2F),
                      )
                    else if (currentStep == 2)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Person icon background
                          Icon(
                            Icons.person,
                            size: 120,
                            color: Color(0xFFD32F2F),
                          ),
                          // Camera icon in the middle-bottom
                          Positioned(
                            bottom: 10,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Color(0xFFF5F5F5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      // Custom icon for step 3 - List
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Three horizontal lines
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Color(0xFFD32F2F),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD32F2F),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Container(
                                    width: 30,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD32F2F),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD32F2F),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Container(
                                    width: 25,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD32F2F),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
                SizedBox(height: 60),
                // Step Counter and Progress Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Generate indicators for each step
                    ...List.generate(
                      3,
                      (index) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: index == currentStep - 1
                            ? Container(
                                width: 30,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              )
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Description Text
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 80),
                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      currentStep == totalSteps ? 'البدء' : 'التالي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // Progress Indicator
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InstructionStep {
  final String title;
  final String description;
  final int step;

  InstructionStep({
    required this.title,
    required this.description,
    required this.step,
  });
}
