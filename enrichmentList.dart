import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shiftsoft/models/mcourse.dart';
import 'package:shiftsoft/models/mdashboard.dart';
import 'package:shiftsoft/models/mlesson.dart';
import 'package:shiftsoft/models/mteacher.dart';
import 'package:shiftsoft/models/muser.dart';
import 'package:shiftsoft/resources/dashboardApi.dart';
import 'package:shiftsoft/screens/bookingList.dart';
import 'package:shiftsoft/screens/enrichmentProfilePage.dart';
import 'package:shiftsoft/resources/courseApi.dart';
import 'package:shiftsoft/resources/lessonApi.dart';
import 'package:shiftsoft/resources/teacherApi.dart';
import 'package:shiftsoft/resources/userApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:intl/intl.dart';
import 'package:shiftsoft/widgets/bannerCarousel.dart';
import 'package:shiftsoft/widgets/enrichment.dart';
import 'package:shiftsoft/widgets/imageBox.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';
import 'package:shimmer/shimmer.dart';

class EnrichmentList extends StatefulWidget {
  @override
  _EnrichmentListState createState() => _EnrichmentListState();
}

class _EnrichmentListState extends State<EnrichmentList> {
  int mCurrentIndex = 0;
  int fromWhere;
  int teacherId;

  double rating = 3.5;

  bool isExit = false;
  bool isTeacher = false, isStudent = false;
  bool courseListLoading = true;
  bool teacherListLoading = true;
  bool lessonListLoading = true;
  // bool userLoading = true;
  bool dashboardCourseListLoading = true;

  List<Course> courseList = [];
  List<Teacher> teacherList = [];
  List<Lesson> lessonList = [];
  List<Teacher> teacher;
  List<MDashboard> dashboardCourseList = [];
  // User user;

  Map<String, String> message = new Map();

  List<String> messageList = [
    "seeMore",
    "popularTeacher",
    "popularTrainer",
    "improveYourself",
    "account",
    "browse",
    "studySchedule",
    "upcomingSessions",
    "students",
    "student",
    "session",
    "enrichmentList"
  ];

  void didChangeDependencies() async {
    super.didChangeDependencies();

    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    // await checkUser();

    if (courseListLoading) {
      initCourseList();
    }
    if (teacherListLoading) {
      initTeacherList();
    }
    if (lessonListLoading) {
      initLessonList();
    }
    // if (userLoading) {
    //   initUserById();
    // }
    if (dashboardCourseListLoading){
      initDashboardCourse();
    }
  }

  initDashboardCourse() async {
    setState(() {
      dashboardCourseListLoading = true;
    });

    dashboardCourseList = await dashboardApi.getDashboardCourseList(context);

    setState(() {
      dashboardCourseListLoading = false;
    });
  }

  // initUserById() async {
  //   Configuration config = Configuration.of(context);
  //   setState(() {
  //     userLoading = true;
  //   });

  //   user = await userApi.getUser(context, config.user.id);

  //   setState(() {
  //     userLoading = false;
  //     user = user;
  //   });
  // }

  initLessonList() async {
    setState(() {
      lessonListLoading = true;
    });

    lessonList = await lessonApi.getLessonList(context, 0);

    setState(() {
      lessonListLoading = false;
      lessonList = lessonList;
    });
  }

  initTeacherList() async {
    setState(() {
      teacherListLoading = true;
    });

    teacherList = await teacherApi.getTeacherList(context, parameter: "with[0]=User");

    setState(() {
      teacherListLoading = false;
      teacherList = teacherList;
    });
  }
  
  initCourseList() async {
    setState(() {
      courseListLoading = true;
    });

    courseList = await courseApi.getCoursesList(context, 0, parameter: "with[0]=Teacher.User&filtersArr[0][]=status|in|2,3");

    setState(() {
      courseListLoading = false;
      courseList = courseList;
    });
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

    if (isStudent)
      fromWhere = 0;
    else
      fromWhere = 1;
  }
  Future<Null> _refresh() async {
    await initTeacherList();
    await initCourseList();
    await initLessonList();
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: config.blueColor),
          onPressed: () {
            customNavigator(context, "dashboard");
          }
        ),
        title: SSText(message["enrichmentList"], 3, color: config.blueColor),
        actions: <Widget>[
          IconButton(
            icon: Image.asset("assets/icon/search-white.png",
                width: 23.5, height: 23),
            onPressed: () {
              customNavigator(context, "enrichmentSearch");
            },
          ),
          // IconButton(
          //     icon: Image.asset("assets/icon/bookmark-white.png",
          //         width: 16, height: 23),
          //     onPressed: () {
          //       customNavigator(context, "bookmarkList");
          //     }),
          IconButton(
              icon: Image.asset("assets/icon/notification-white.png",
                  width: 23.4, height: 25.5),
              onPressed: () {
                customNavigator(context, "notificationList");
              }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          itemCount: 1,
          scrollDirection: Axis.vertical,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              color: Colors.white,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: MediaQuery.of(context).size.width/16*9,
                      child: BannerCarousel(
                        "bannerCourse",
                        dashboardCourseList.map((item) => item.id.toString()).toList(),
                        dashboardCourseList.map((item) => item.pic).toList(),
                        dashboardCourseList.map((item) => item.link).toList(),
                        dashboardCourseList.map((item) => item.name).toList(),
                        dashboardCourseList.map((item) => item.content).toList()),
                    ),
                    Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          SSText(isTeacher? message["popularTrainer"] : message["popularTeacher"], 1, size: 24, color: config.blueColor),
                          InkWell(
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Center(
                                  child: SSText(message["seeMore"], 8,
                                      color: config.blueColor),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: config.lightBlueColor,
                                ),
                              ),
                              onTap: () {
                                customNavigator(context, "teacherList", arguments: fromWhere);
                              }
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(right: 8, left: 8, top: 8),
                      height: 120,
                      child: teacherListLoading ? 
                      buildShimmerInstructor()
                      : 
                      teacherList.length > 0 ?
                      ListView.builder(
                        itemCount: teacherList.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (BuildContext context, int index) {
                          final item = teacherList[index];
                          teacherId = item.id;
                          return InkWell(
                            child: Container(
                              // color: Colors.blue,
                              width: MediaQuery.of(context).size.width / 3.5,
                              padding: EdgeInsets.only(right: 8),
                              child: Column(
                                crossAxisAlignment:CrossAxisAlignment.center,
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: ImageBox(
                                      CompanyAsset("avatar", item.user.pic), 
                                      0, 
                                      fit: BoxFit.cover, 
                                      width: 50, 
                                      height: 50
                                    )
                                  ),
                                  SizedBox(height: 9),
                                  Expanded(
                                    child: SSText(item.user.name, 5, align: TextAlign.center, maxLines: 2)
                                  )
                                  // Padding(
                                  //   padding: const EdgeInsets.only(top: 6),
                                  //   child: SSText("Kelas",5),
                                  // )
                                ],
                              ),
                            ),
                            onTap: () {
                              customNavigator(context, "teacherDetail/${item.id}/3"); //harusnya id disini
                            },
                          );
                        }
                      ) : 
                      PlaceholderList(type: "teacher", paddingTop: 40,)
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          SSText(message["improveYourself"], 1, size: 24, color: config.blueColor),
                          InkWell(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              child: Center(
                                child: SSText(message["seeMore"], 8, color: config.blueColor),
                              ),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: config.lightBlueColor,
                              ),
                            ),
                            onTap: (){
                              customNavigator(context,"enrichmentSearch");
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Container(
                    //   height: 50,
                    //   padding: EdgeInsets.only(left: 15, right: 15),
                    //   child: lessonListLoading ? 
                    //   Center(
                    //     child: CircularProgressIndicator(),
                    //   )
                    //   : 
                    //   ListView.builder(
                    //     itemCount: lessonList.length,
                    //     scrollDirection: Axis.horizontal,
                    //     itemBuilder: (BuildContext context, int index) {
                    //       final itemLesson = lessonList[index];
                    //       return Padding( padding: const EdgeInsets.only(left: 8.0, right: 8),
                    //         child: Container(
                    //           decoration: BoxDecoration(color: config.lightBlueColor),
                    //           child: FlatButton(
                    //             child: SSText(itemLesson.name, 5,color: config.blueColor),
                    //             onPressed: () {

                    //               },
                    //             ),
                    //           ),
                    //         );
                    //       }
                    //     )
                    //   ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      // height: MediaQuery.of(context).size.height,
                      child: courseListLoading ? 

                      buildShimmerEnrichment()
                      : 
                      courseList.length > 0 ?
                      StaggeredGridView.countBuilder(
                        physics: ScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        staggeredTileBuilder: (int index) {
                          // return StaggeredTile.count(1, index.isEven ? 1.8 : 1.8);
                          return StaggeredTile.fit(1);
                        },
                        itemCount: courseList.length,
                        itemBuilder: (BuildContext context, int index){
                          return Enrichment(course: courseList[index], message: message, inBookingList: 0);
                        },
                      )
                      // GridView.builder(
                      //   shrinkWrap: true,
                      //   physics: ScrollPhysics(),
                      //   gridDelegate:
                      //       SliverGridDelegateWithFixedCrossAxisCount(
                      //     crossAxisCount: 2,
                      //     childAspectRatio: 0.49,
                      //   ),
                      //   itemCount: courseList.length,
                      //   itemBuilder:
                      //   (BuildContext context, int index) {
                      //     return Enrichment(course: courseList[index], message: message, inBookingList: 0);
                      //   }
                      // ) 
                    : PlaceholderList(type: "course", paddingTop: 80,)
                  )
                ]
              ),
            );
          }
        ),  
      ),
    );
  }
}

Widget buildShimmerInstructor() {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8),
    height: 120,
    child: ListView.builder(
      itemCount: 5,
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[200],
          highlightColor: Colors.grey[350],
          period: Duration(milliseconds: 800),
          child: Container(
            width: MediaQuery.of(context).size.width / 2.9,
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment:CrossAxisAlignment.center,
              children: <Widget>[
                // ClipRRect(
                //   borderRadius: BorderRadius.circular(10),
                //   child: ImageBox(
                //     CompanyAsset("avatar", item.user.pic), 
                //     0, 
                //     fit: BoxFit.cover, 
                //     width: 50, 
                //     height: 50
                //   )
                // ),
                // CircleAvatar(radius: 30),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(40),color: Colors.grey[200]),
                ),
                SizedBox(height: 9),
                Container(
                  width: 100,
                  height: 35,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200])
                ),
                // pake ini kalo kelasnya udh ada
                // Padding(
                //   padding: const EdgeInsets.only(top: 6),
                //   child: Container(
                //     width: 100,
                //     height: 16,
                //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200])
                //   ),
                // )
              ],
            ),
          ),
        );
      }
    )
  );
}
Widget buildShimmerEnrichment(){
  return GridView.builder(
    shrinkWrap: true,
    physics: ScrollPhysics(),
    gridDelegate:
        SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.49,
    ),
    itemCount: 4,
    itemBuilder: (BuildContext context, int index) {
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
        child: Card(
          child: Shimmer.fromColors(
          baseColor: Colors.grey[200],
          highlightColor: Colors.grey[350],
          period: Duration(milliseconds: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 350, 
                  height: 150,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 10),
                  child: Row(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                        width: 40, 
                        height: 40,
                      ),
                      SizedBox(width: 5),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                        width: 73,
                        height: 14,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 125,
                        height: 15,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: 110,
                        height: 15,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
                      ),
                      SizedBox(height: 5),
                      Container(
                        width: 60,
                        height: 10,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
                      ),
                      SizedBox(height: 15),
                      Container(
                        width: 55,
                        height: 10,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            width: 45,
                            height: 10,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
                          ),
                          Container(
                            width: 55,
                            height: 10,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }
  );
}