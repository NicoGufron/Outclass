import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shiftsoft/models/mcourseuser.dart';
import 'package:shiftsoft/models/mteacher.dart';
import 'package:shiftsoft/resources/courseApi.dart';
import 'package:shiftsoft/resources/teacherApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:intl/intl.dart';
import 'package:shiftsoft/widgets/enrichment.dart';
import 'package:shiftsoft/widgets/imageBox.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

class BookingList extends StatefulWidget {
  final int mode, id;

  const BookingList({Key key, this.mode, this.id}) : super(key: key);
  @override
  _BookingListState createState() => _BookingListState();
}

class _BookingListState extends State<BookingList> {

  int payNowPrice = 0;

  bool isExit;
  bool isTeacher = false, isStudent = false;
  bool courseUserBookingLoading = true;
  bool teacherLoading = true;

  int mCurrentIndex = 1;
  int fromBookingList = 1;
  int daysLeft = 0, hoursLeft = 0;
  int id;

  Teacher teacher;

  Map<String, String> message = new Map();

  List<String> messageList = [
    "browse", "studySchedule", "account", "upcomingSessions", "addNewReview", "session", "student", "students", 
    "daysLeft", "dayLeft", "paid", "notPaid", "payNow", "bookingList", "history", "toClass"
  ];

  List<CourseUser> courseUserBookingList;

  DateTime tempDate = DateTime.now();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    id = widget.id;
  }

  void didChangeDependencies() async {
    super.didChangeDependencies();
    
    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    await checkUser();

    if(courseUserBookingLoading)
      initCourseUserList();

    if(teacherLoading)
      initUserById();
  }

  initUserById() async {
    setState(() {
      teacherLoading = true;
    });

    if(isTeacher)
      teacher = await teacherApi.getTeacherById(context, id);

    setState(() {
      teacherLoading = false;
      teacher = teacher;
    });
  }

  initCourseUserList() async {
    Configuration config = Configuration.of(context);
    setState(() {
      courseUserBookingLoading = true;
    });

    if(isTeacher){
      courseUserBookingList = await courseApi.getCourseUserList(context, parameter: "with[0]=Course.Teacher.User&with[1]=Course.Circle&filtersArr[0][]=user_id|=|"+ id.toString() + "|god&filtersArr[0][]=status|in|0,2,3" );
    }else{
      courseUserBookingList = await courseApi.getCourseUserList(context, parameter: "with[0]=Course.Teacher.User&with[1]=Course.Circle&filtersArr[0][]=user_id|=|" + config.user.id.toString() + "|god&filtersArr[0][]=status|in|0,2,3");
    }

    setState(() {
      courseUserBookingLoading = false;
      courseUserBookingList = courseUserBookingList;
    });
  }

  checkUser() async {
    var tempIsStudent = await checkPermission(
        context, "master.member.role", "BackendRole.IsStudent",
        mustLogin: true);
    var tempIsTeacher = await checkPermission(
        context, "master.member.role", "BackendRole.IsTeacher",
        mustLogin: true);

    isStudent = tempIsStudent ? true : false;
    isTeacher = tempIsTeacher ? true : false;

    setState(() {
      isStudent = isStudent;
      isTeacher = isTeacher;
    });
  }

  Future<Null> _refresh() async {
    await initUserById();
    await initCourseUserList();
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: SSText(message["bookingList"], 3, color: config.blueColor),
        actions: <Widget>[
          IconButton(icon: Image.asset("assets/icon/search-white.png", width: 23.5, height: 23), onPressed: (){
            customNavigator(context, "enrichmentSearch");
          },),
          // IconButton(icon: Image.asset("assets/icon/bookmark-white.png", width: 16, height: 23), onPressed: (){
          //   customNavigator(context, "bookmarkList");
          // }),
          IconButton(icon: Image.asset("assets/icon/notification-white.png", width: 23.4, height: 25.5), onPressed: (){
            customNavigator(context, "notificationList");
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: ListView.builder(
            itemCount: 1,
            scrollDirection: Axis.vertical,
            itemBuilder: (BuildContext context, int index){
              return Container(
                padding: EdgeInsets.only(left:10 ,right:10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        InkWell(
                            child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Center(
                                child: SSText(message["history"], 8, color: config.blueColor),
                                ),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: config.lightBlueColor, 
                                ),
                              ),
                              onTap:(){
                                customNavigator(
                                  context,"enrichmentHistory", 
                                );
                              }
                            ),
                      ],
                    ),
                    SizedBox(height: 20),
                    courseUserBookingLoading ?
                    buildShimmerEnrichment() 
                    :
                    courseUserBookingList.length > 0 ?
                    StaggeredGridView.countBuilder(
                      physics: ScrollPhysics(),
                      shrinkWrap: true,
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        staggeredTileBuilder: (int index) {
                          // return StaggeredTile.count(1, index.isEven ? 1.8 : 1.8);
                          return StaggeredTile.fit(1);
                        },
                        itemCount: courseUserBookingList.length,
                        itemBuilder: (BuildContext context, int index){
                          return Enrichment(
                            courseUser: courseUserBookingList[index], 
                            message: message, 
                            inBookingList: 1
                          );
                        },
                      )
                    :
                    PlaceholderList(type: "bookinglist")
                  ],
                )
              );
            },
          ),
        ),
      ),
    );
  }
}
Widget buildShimmerEnrichment(){
  return GridView.builder(
    shrinkWrap: true,
    physics: ScrollPhysics(),
    gridDelegate:
        SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.42,
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
                      SizedBox(height: 10),
                      Container(
                        width: 75,
                        height: 10,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 130,
                          height: 50,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
                        ),
                      )
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