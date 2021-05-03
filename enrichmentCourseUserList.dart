import 'package:flutter/material.dart';
import 'package:shiftsoft/models/mcourseuser.dart';
import 'package:shiftsoft/resources/courseApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';

class EnrichmentCourseUserList extends StatefulWidget {
  final int mode, id;

  const EnrichmentCourseUserList({Key key, this.mode, this.id}) : super(key: key);
  @override
  _EnrichmentCourseUserListState createState() => _EnrichmentCourseUserListState();
}

class _EnrichmentCourseUserListState extends State<EnrichmentCourseUserList> {

  int courseId;

  bool courseUserListLoading = true;

  List<CourseUser> courseUserList;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    courseId = widget.id;
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    if(courseUserListLoading)
      initCourseUserList();
  }

  initCourseUserList() async {
    setState(() {
      courseUserListLoading = true;
    });

    courseUserList = await courseApi.getCourseUserList(context, parameter: "with[0]=User&filtersArr[0][]=course_id|=|$courseId|god");
    printHelp(courseUserList.length);

    setState(() {
      courseUserListLoading = false;
      courseUserList = courseUserList;
    });
  }

  Future<Null> _refresh() async {
    await initCourseUserList();
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: SSText("Student List", 4, color: config.blueColor),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: config.blueColor), onPressed: (){
          Navigator.pop(context);
        })
      ),
      body: 
      RefreshIndicator(
        onRefresh: _refresh,
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: 
          courseUserListLoading ?
          Center(
            child: CircularProgressIndicator()
          )
          :
          courseUserList.length > 0 ?
          ListView.builder(
            itemCount: courseUserList.length,
            itemBuilder: (BuildContext context, int index){
              final item = courseUserList[index];
              return Card(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: CircleAvatar()
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SSText(item.user.nickname, 4, size: 16),
                            SSText(item.user.email, 4, size: 12),
                          ],
                        )
                      ),
                      Expanded(
                        flex: 1,
                        child: SSText(item.status == 2 ? "Sudah membayar" : "Belum membayar", 5, color: item.status == 2 ? config.darkGreenColor : Colors.red)
                      ),
                      SizedBox(width: 20)
                    ],
                  ),
                ),
              );
            }
          )
          :
          Center(child: PlaceholderList(type: "studentlist"))
        ),
      )
    );
  }
}