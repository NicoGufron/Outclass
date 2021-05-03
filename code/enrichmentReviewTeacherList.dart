import 'package:flutter/material.dart';
import 'package:shiftsoft/models/mreviewCourseTeacher.dart';
import 'package:shiftsoft/models/mteacher.dart';
import 'package:shiftsoft/resources/reviewCourseTeacherApi.dart';
import 'package:shiftsoft/resources/teacherApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';
import 'package:shiftsoft/widgets/starRating.dart';
import 'package:intl/intl.dart';
import 'package:shiftsoft/models/mresult.dart';
import 'package:shiftsoft/widgets/imageBox.dart';

class EnrichmentReviewTeacherList extends StatefulWidget {
  final int mode, id;

  const EnrichmentReviewTeacherList({Key key, this.mode, this.id}) : super(key: key);
  @override
  _EnrichmentReviewTeacherListState createState() => _EnrichmentReviewTeacherListState();
}

class _EnrichmentReviewTeacherListState extends State<EnrichmentReviewTeacherList> {

  int id;

  bool reviewTeacherListLoading = true;
  bool teacherLoading = true;
  bool isNotEmpty = true;
  bool isTeacher = false, isStudent = false;

  List<ReviewCourseTeacher> reviewTeacherList;
  Teacher teacher;

  Map<String, String> message = new Map();
  
  Map<String, dynamic> allRating;
  List<String> messageList = [
    "totalPrice", "payNow", "writeAReview", "reviews", "yourRating", "myReviewList", "instructorReview", "instructorRating"
  ];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    id = widget.id;
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    await checkUser();

    if(teacherLoading)
      initTeacherById();
    
    if(reviewTeacherListLoading)
      initReviewTeacherList();
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

    setState(() {
      isStudent = isStudent;
      isTeacher = isTeacher;   
    });
  }

  initTeacherById() async {
    setState(() {
      teacherLoading = true;
    });

    teacher = await teacherApi.getTeacherById(context, id, parameter: "with[0]=User");
    //harus ada pengecekan tiap bintang, pake count ?

    setState(() {
      teacherLoading = false;
      teacher = teacher;
    });
  }

  initReviewTeacherList() async {
    setState(() {
      reviewTeacherListLoading = true;
    });

    reviewTeacherList = await reviewApi.getReviewCourseTeacherList(context, parameter: "with[0]=Student&filtersArr[0][]=teacher_id|=|$id|god");
    Result result = await reviewApi.getRatingCourseTeacher(context, id.toString());

    if(result.success == 1){
      allRating = result.data;
    }else{
      isNotEmpty = false;
    }

    setState(() {
      reviewTeacherListLoading = false;
      reviewTeacherList = reviewTeacherList;
      allRating = allRating;
      isNotEmpty = isNotEmpty;
    });
  }

  Future<Null> _refresh() async {
    initTeacherById();
    initReviewTeacherList();
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);

    List<Widget> ratingStudentListWidget = [];
    
    if(!reviewTeacherListLoading){
    for(int i = 0; i < reviewTeacherList.length; i++){
      final item = reviewTeacherList[i];
      ratingStudentListWidget.add(
        Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: ImageBox(
                  CompanyAsset("avatar",  item.user.pic), 
                  0, 
                  fit: BoxFit.cover, 
                  width: 25, 
                  height: 25
                )
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SSText(item.user.name, 6, color: Colors.black, fontWeight: FontWeight.bold),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      StarRating(
                        rating: item.rating.toDouble(),
                        size: 15,
                        starCount: 5,
                        color: config.orangeColor
                      ),
                      SizedBox(width: 5),
                      SSText("("+ item.rating.toString() +")", 8, color: config.orangeColor),
                      SizedBox(width: 15),
                      SSText(DateFormat("dd MMMM yyyy").format(item.createdAt), 8, color: config.lightGrayColor),
                    ],
                  ),
                  SizedBox(height: 15),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: SSText(item.review, 8),
                  ),
                ],
              )
            ],
          ),
        )
      );
    }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: SSText(isTeacher ? message["myReviewList"] : message["instructorReview"], 4, color: config.blueColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: config.blueColor), 
          onPressed: (){
            Navigator.pop(context);
          },
        )
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(color: Colors.white),
          child: reviewTeacherListLoading ?
          Center(
            child: CircularProgressIndicator()
          )
          :
          ListView.builder(
            itemCount: 1,
            itemBuilder: (BuildContext context, int index){
              return Column(
                children: <Widget>[
                  SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: ImageBox(
                      CompanyAsset("avatar", teacher.user.pic), 
                      0, 
                      fit: BoxFit.cover, 
                      width: 100, 
                      height: 100
                    )
                  ),
                  SizedBox(height: 10),
                  SSText(teacher.user.name, 2),
                  SizedBox(height: 30),
                  SSText(isTeacher ? message["yourRating"] : message["instructorRating"], 2),
                  Column(
                    children: <Widget>[
                      SSText(isNotEmpty ? double.parse((allRating["allratingtotal"] / allRating["allratinglength"]).toString()).toStringAsFixed(1) : "0", 1, size: 32, color: Colors.black),
                      StarRating(
                        rating: isNotEmpty ? (allRating["allratingtotal"] / allRating["allratinglength"]) : 0,
                        starCount: 5,
                        color: config.orangeColor,
                        size: 35
                      ),
                  SizedBox(height: 10),
                  SSText(isNotEmpty ? allRating["allratinglength"].toString() + " " + message["reviews"] : "0" + " " + message["reviews"], 6),
                  SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.only(left: 10),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              width: 20,
                              child: Icon(Icons.star, color: config.orangeColor, size: 15)),
                            Container(
                              width: 20,
                              child: SSText("5", 8, color: Colors.black)),
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: config.lightGrayColor, borderRadius: BorderRadius.circular(10)),
                                  width: MediaQuery.of(context).size.width - 110,
                                  height: 5,
                                ),
                                isNotEmpty ? Container(
                                  decoration: BoxDecoration(color: config.darkGreenColor, borderRadius: BorderRadius.circular(10)),
                                  width: (MediaQuery.of(context).size.width - 110) * (allRating["rating5length"] / allRating["allratinglength"]),
                                  height: 5
                                ) :
                                Container(
                                  decoration: BoxDecoration(color: config.lightGrayColor, borderRadius: BorderRadius.circular(10)),
                                  width: (MediaQuery.of(context).size.width - 110) * 0,
                                  height: 5
                                )
                              ]
                            ),
                            Container(
                              width: 40,
                              child: SSText(isNotEmpty ? allRating["rating5length"].toString() : "0", 8 , color: config.lightGrayColor, align: TextAlign.center,)
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              width: 20,
                              child: Icon(Icons.star, color: config.orangeColor, size: 15)),
                            Container(
                              width: 20,
                              child: SSText("4", 8, color: Colors.black)),
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: config.lightGrayColor, borderRadius: BorderRadius.circular(10)),
                                  width: MediaQuery.of(context).size.width - 110,
                                  height: 5,
                                ),
                                isNotEmpty ? 
                                Container(
                                  decoration: BoxDecoration(color: config.greenColor, borderRadius: BorderRadius.circular(10)),
                                  width: (MediaQuery.of(context).size.width - 110) * (allRating["rating4length"] / allRating["allratinglength"]),
                                  height: 5
                                ) :
                                Container(
                                  decoration: BoxDecoration(color: config.lightGrayColor, borderRadius: BorderRadius.circular(10)),
                                  width: (MediaQuery.of(context).size.width - 110) * 0,
                                  height: 5
                                )
                              ]
                            ),
                            Container(
                              width: 40,
                              child: SSText(isNotEmpty ? allRating["rating4length"].toString() : "0", 8 , color: config.lightGrayColor,align: TextAlign.center)
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              width: 20,
                              child: Icon(Icons.star, color: config.orangeColor, size: 15)),
                            Container(
                              width: 20,
                              child: SSText("3", 8, color: Colors.black)),
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: config.lightGrayColor, borderRadius: BorderRadius.circular(10)),
                                  width: MediaQuery.of(context).size.width - 110,
                                  height: 5,
                                ),
                                isNotEmpty ? Container(
                                  decoration: BoxDecoration(color: config.orangeColor, borderRadius: BorderRadius.circular(10)),
                                  width: (MediaQuery.of(context).size.width - 110) * (allRating["rating3length"] / allRating["allratinglength"]),
                                  height: 5
                                ) :
                                Container(
                                  decoration: BoxDecoration(color: config.darkGreenColor, borderRadius: BorderRadius.circular(10)),
                                  width: (MediaQuery.of(context).size.width - 110) * 0,
                                  height: 5
                                )
                              ]
                            ),
                            Container(
                              width: 40,
                              child: SSText(isNotEmpty ? allRating["rating3length"].toString() : "0", 8 , color: config.lightGrayColor,align: TextAlign.center)
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              width: 20,
                              child: Icon(Icons.star, color: config.orangeColor, size: 15)),
                            Container(
                              width: 20,
                              child: SSText("2", 8, color: Colors.black)),
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: config.lightGrayColor, borderRadius: BorderRadius.circular(10)),
                                  width: MediaQuery.of(context).size.width - 110,
                                  height: 5,
                                ),
                                isNotEmpty ? Container(
                                  decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(10)),
                                  width: (MediaQuery.of(context).size.width - 110) * (allRating["rating2length"] / allRating["allratinglength"]),
                                  height: 5
                                ) : Container(
                                  decoration: BoxDecoration(color: config.darkGreenColor, borderRadius: BorderRadius.circular(10)),
                                  width: (MediaQuery.of(context).size.width - 110) * 0,
                                  height: 5
                                )
                              ]
                            ),
                            Container(
                              width: 40,
                              child: SSText(isNotEmpty ? allRating["rating2length"].toString() : "0", 8 , color: config.lightGrayColor, align: TextAlign.center)
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              width: 20,
                              child: Icon(Icons.star, color: config.orangeColor, size: 15)),
                            Container(
                              width: 20,
                              child: SSText("1", 8, color: Colors.black)),
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: config.lightGrayColor, borderRadius: BorderRadius.circular(10)),
                                  width: MediaQuery.of(context).size.width - 110,
                                  height: 5,
                                ),
                                isNotEmpty ? Container(
                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                  width: (MediaQuery.of(context).size.width - 110) * (allRating["rating1length"] / allRating["allratinglength"]),
                                  height: 5
                                ) : 
                                Container(
                                  decoration: BoxDecoration(color: config.lightGrayColor, borderRadius: BorderRadius.circular(10)),
                                  width: MediaQuery.of(context).size.width - 110,
                                  height: 5,
                                )
                              ]
                            ),
                            Container(
                              width: 40,
                              child: SSText(isNotEmpty ? allRating["rating1length"].toString() : "0", 8 , color: config.lightGrayColor, align: TextAlign.center)
                            ),
                          ],
                        ), 
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: 10),
              if(reviewTeacherList.length > 0)
                ...ratingStudentListWidget
              else
                PlaceholderList(type: "productReview", paddingTop: 90,)
            ],
          );
        }
      )
    ),
  ));
  }
}