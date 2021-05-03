import 'package:flutter/material.dart';
import 'package:shiftsoft/models/mteacher.dart';
import 'package:shiftsoft/resources/teacherApi.dart';
import 'package:shiftsoft/screens/bookingList.dart';
import 'package:shiftsoft/screens/enrichmentList.dart';
import 'package:shiftsoft/screens/enrichmentProfilePage.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';

class EnrichmentDashboard extends StatefulWidget {
  @override
  _EnrichmentDashboardState createState() => _EnrichmentDashboardState();
}

class _EnrichmentDashboardState extends State<EnrichmentDashboard> {

  int mCurrentIndex = 0;

  bool isExit = false;  
  bool isTeacher = false, isStudent = false;

  Map<String, String> message = new Map();

  List<String> messageList = [
    "seeMore",
    "popularTeacher",
    "popularTrainer",
    "improveYourself",
    "account",
    "browse",
    "studySchedule",
    "upcomingSession",
    "students",
    "student",
    "session"
  ];

  List<Teacher> teacher;

  void didChangeDependencies() async {
    super.didChangeDependencies();

    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    await checkUser();
  }

  checkUser() async {
    Configuration config = Configuration.of(context);
    var tempIsStudent = await checkPermission(
        context, "master.member.role", "BackendRole.IsStudent",
        mustLogin: true);
    var tempIsTeacher = await checkPermission(
        context, "master.member.role", "BackendRole.IsTeacher",
        mustLogin: true);

    isStudent = tempIsStudent ? true : false;
    isTeacher = tempIsTeacher ? true : false;

    if (isTeacher)
      teacher = await teacherApi.getTeacherList(context,
          parameter: "with[0]=User&filtersArr[0][]=user_id|=|" +
              config.user.id.toString() +
              "|god");


    setState(() {
      isStudent = isStudent;
      isTeacher = isTeacher;
      teacher = teacher;
    });
  }

  Future<bool> willPopScope() async {
    if (mCurrentIndex != 0) {
      setState(() {
        mCurrentIndex = mCurrentIndex - 1;
      });
    }else if (mCurrentIndex == 0){
      return true;
    }
    return false;
  }

  void onTabTapped(int index) async {
    setState(() {
      isExit = false; // reset counter is exit, ketika pindah tab
      mCurrentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);

    List<Widget> _childrenMenu = [
      EnrichmentList(),
      BookingList(mode: 3, id:config.user.id),
      EnrichmentProfilePage(mode: 3, id: config.user.id)
    ];

    return Scaffold(
      body: WillPopScope(
        onWillPop: willPopScope,
        child: Container(
          child: _childrenMenu[mCurrentIndex]
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: config.primaryColor,
        type: BottomNavigationBarType.shifting,
        currentIndex: mCurrentIndex,
        onTap: onTabTapped,
        items: 
          [
            BottomNavigationBarItem(
                icon: mCurrentIndex == 0
                    ? Container(
                        width: 20,
                        height: 20,
                        child: Image.asset("assets/icon/search-white.png",
                            color: config.blueColor))
                    : Container(
                        width: 20,
                        height: 20,
                        child: Image.asset("assets/icon/search-white.png",
                            color: Colors.grey[500])),
                title: SSText(
                    mCurrentIndex == 0 ? message["browse"] : "", 4,
                    size: 12,
                    color: mCurrentIndex == 0
                        ? config.blueColor
                        : Colors.grey[500])),
            BottomNavigationBarItem(
              icon: mCurrentIndex == 1
                  ? Container(
                      width: 20,
                      height: 20,
                      child: Image.asset("assets/icon/class-active.png",
                          color: config.blueColor))
                  : Container(
                      width: 20,
                      height: 20,
                      child: Image.asset("assets/icon/class-inactive.png",
                          color: Colors.grey[500])),
              title: SSText(
                  mCurrentIndex == 1 ? message["upcomingSession"] : "", 4,
                  size: 12,
                  color: mCurrentIndex == 1
                      ? config.blueColor
                      : Colors.grey[500]),
            ),
            BottomNavigationBarItem(
              icon: mCurrentIndex == 2
                  ? Container(
                      width: 20,
                      height: 20,
                      child: Icon(Icons.person, color: config.blueColor))
                  : Container(
                      width: 20,
                      height: 20,
                      child: Icon(Icons.person, color: Colors.grey[500])),
              title: SSText(
                  mCurrentIndex == 2 ? message["account"] : "", 4,
                  size: 12,
                  color: mCurrentIndex == 2
                      ? config.blueColor
                      : Colors.grey[500]),
            ),
          ]
      ),
    );
  }
}