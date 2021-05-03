import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shiftsoft/models/mcourse.dart';
import 'package:shiftsoft/models/mcourseuser.dart';
import 'package:shiftsoft/resources/courseApi.dart';
import 'package:shiftsoft/screens/challengeSubmissionDetail.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:intl/intl.dart';
import 'package:shiftsoft/widgets/enrichment.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';
import 'package:shimmer/shimmer.dart';

class EnrichmentHistory extends StatefulWidget {
  final int mode, id;

  const EnrichmentHistory({Key key, this.mode, this.id}) : super(key: key);
  @override
  _EnrichmentHistoryState createState() => _EnrichmentHistoryState();
}

class _EnrichmentHistoryState extends State<EnrichmentHistory> {

  int mCurrentIndex = 1;

  double payNowPrice = 0;

  bool courseUserHistoryLoading = true;
  bool isExit = false;
  bool isStudent = false, isTeacher = false;

  List<CourseUser> courseUserHistory = [];

  Map<String, String> message = new Map();

  List<String> messageList = [
    "browse", "studySchedule", "account", "upcomingSessions", "students", "student", "addNewReview", "historyList", "session", "sessionDone"
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    await checkUser();

    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    if(courseUserHistoryLoading)
      initCourseUserHistory();
  }

  initCourseUserHistory() async {
    Configuration config = Configuration.of(context);
    setState(() {
      courseUserHistoryLoading = true;
    });

    courseUserHistory = await courseApi.getCourseUserList(context, parameter: "with[0]=Course.Teacher.User&filtersArr[0][]=user_id|=|"+ config.user.id.toString() + "|god&filtersArr[0][]=status|in|3,4,5");

    setState(() {
      courseUserHistoryLoading = false;
      courseUserHistory = courseUserHistory;
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
    await initCourseUserHistory();
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: SSText(message["historyList"], 3, color: config.blueColor),
        leading: 
          IconButton(
            icon: Icon(Icons.arrow_back, color: config.blueColor),
            onPressed: (){
              Navigator.pop(context);
          }
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: courseUserHistoryLoading ?
          buildShimmerEnrichment()
          :
          ListView.builder(
            itemCount: 1,
            scrollDirection: Axis.vertical,
            itemBuilder: (BuildContext context, int index){
              return Container(
                padding: EdgeInsets.only(left:10 ,right:10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 20),
                    courseUserHistory.length > 0 ?
                    StaggeredGridView.countBuilder(
                      physics: ScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      staggeredTileBuilder: (int index) {
                          // return StaggeredTile.count(1, index.isEven ? 1.8 : 1.8);
                        return StaggeredTile.fit(1);
                      },
                      itemCount: courseUserHistory.length,
                      itemBuilder: (BuildContext context, int index){
                        return Enrichment(courseUser: courseUserHistory[index], message: message, inBookingList: 1);
                      },
                    )
                    :
                    PlaceholderList(type: "enrichmenthistory")
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
      childAspectRatio: 0.45,
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