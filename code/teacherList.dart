import 'package:flutter/material.dart';
import 'package:shiftsoft/models/mteacher.dart';
import 'package:shiftsoft/resources/teacherApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/OCDropdown.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:shiftsoft/widgets/starRating.dart';
import 'package:shiftsoft/widgets/imageBox.dart';
import 'package:shimmer/shimmer.dart';

class TeacherList extends StatefulWidget {
  final int mode, id, fromWhere;

  const TeacherList({Key key, this.mode, this.id, this.fromWhere}) : super(key: key);
  @override
  _TeacherListState createState() => _TeacherListState();
}

class _TeacherListState extends State<TeacherList> {

  int fromWhere;

  String selectedRole;

  bool teacherListLoading = true;

  Map<String, String> message = new Map();

  List<String> messageList = [
    "instructorList"
  ];

  List<Teacher> teacherList;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    if(teacherListLoading)
      initTeacherList();
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

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: SSText(message["instructorList"], 3, color: config.blueColor),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: config.blueColor), 
        onPressed: (){
          Navigator.pop(context);
        }),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: ListView.builder(
          itemCount: 1,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, int index){
          return Container(
            padding: EdgeInsets.only(left: 15, right: 15, top: 12),
            child: Column(
              children: <Widget>[
                // OCDropdown(
                //   color: config.blueColor,
                //   hintText: "",
                //   value: selectedRole,
                //   onChanged: (String newValue) {
                //     setState(() {
                //         selectedRole = newValue;
                //       });
                //     },
                //   items: <String>["All", "Verified", "Unverified"].map(
                //     (String value) {
                //       return new DropdownMenuItem<String>(
                //         value: value, child: new Text(value)
                //       );
                //     },
                //   ).toList()
                // ),
                Container(
                  height: MediaQuery.of(context).size.height,
                  child:  teacherListLoading ? 
                    buildShimmerInstructor()
                    :
                    ListView.builder(
                      itemCount: teacherList.length,
                      scrollDirection: Axis.vertical,
                      itemBuilder: (context, int index){
                        final item = teacherList[index];
                        return Column(
                          children: <Widget>[
                            InkWell(
                              child: Row(
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: ImageBox(
                                      CompanyAsset("avatar",  item.user.pic), 
                                      0, 
                                      fit: BoxFit.cover, 
                                      width: 55, 
                                      height: 55
                                    )
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            SSText(item.user.name,5),
                                            // SizedBox(width: 5),
                                            // Icon(Icons.check_circle, color: config.blueColor, size: 10)
                                          ],
                                        ),
                                        // SizedBox(height: 3),
                                        // SSText("Fisika, Mandarin",5),
                                        SizedBox(height: 3),
                                        Row(
                                          children: <Widget>[
                                            StarRating(
                                              size: 12,
                                              color: config.orangeColor,
                                              rating: item.rating.toDouble(),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: SSText("(" + double.parse(item.rating.toString()).toStringAsFixed(1) + ")", 8, color: config.orangeColor),
                                            )
                                          ],
                                        ),
                                      ]
                                    ),
                                  )
                                ],
                              ),
                              onTap: (){
                                customNavigator(context, "teacherDetail/${item.id}/3");
                              }
                            ),
                            Divider(color: config.blueColor, thickness: 0.5)
                          ],
                        );
                    },
                  ),
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}
Widget buildShimmerInstructor(){
  return ListView.builder(
    itemBuilder: (BuildContext context, int index){
      return Shimmer.fromColors(
        baseColor: Colors.grey[200],
        highlightColor: Colors.grey[350],
        period: Duration(milliseconds: 800),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), color: Colors.grey[200])
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 125,
                            height: 16,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200])
                          )
                          // SizedBox(width: 5),
                          // Icon(Icons.check_circle, color: config.blueColor, size: 10)
                        ],
                      ),
                      // SizedBox(height: 3),
                      // SSText("Fisika, Mandarin",5),
                      SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                         Container(
                            width: 85,
                            height: 16,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200])
                          )
                        ],
                      ),
                    ]
                  ),
                )
              ],
            ),
          ],
        ),
      );
    },
  );
}