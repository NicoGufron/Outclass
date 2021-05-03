import 'dart:async';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shiftsoft/models/mcourse.dart';
import 'package:shiftsoft/models/mresult.dart';
import 'package:shiftsoft/models/mteacher.dart';
import 'package:shiftsoft/resources/courseApi.dart';
import 'package:shiftsoft/resources/reviewCourseTeacherApi.dart';
import 'package:shiftsoft/resources/teacherApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/OCTextField.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:shiftsoft/widgets/SSTextField.dart';
import 'package:shiftsoft/widgets/imageBox.dart';
import 'package:shiftsoft/widgets/starRating.dart';

class ReviewForm extends StatefulWidget {
  final int mode, id, courseId;

  const ReviewForm({Key key, this.mode, this.id, this.courseId}) : super(key: key);
  @override
  _ReviewFormState createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {

  int courseId;

  double rating = 3;

  Map<String, String> message = new Map();

  List<String> messageList = [
    "writeAReview", "writeYourComment", "reviewComment1", "reviewComment2", "reviewComment3", "reviewComment4", "reviewComment5",
    "sendReview", "submitReview", "thanksReview", "reviewFailed"
  ];

  String reviewComment = "";

  bool courseLoading = true;
  bool haveReviewed = false;

  Course course;

  TextEditingController reviewController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    courseId = widget.id;
    print(courseId);
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    if(courseLoading)
      initTeacherById();
  }

  initTeacherById() async {
    setState(() {
      courseLoading = true;
    });

    course = await courseApi.getCourse(context, courseId, parameter: "with[0]=Teacher.User");

    setState(() {
      courseLoading = false;
      course = course;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);
    if(rating == 1){
      reviewComment = message["reviewComment1"];
    }else if(rating == 2){
      reviewComment = message["reviewComment2"];
    }else if(rating == 3){
      reviewComment = message["reviewComment3"];
    }else if(rating == 4){
      reviewComment = message["reviewComment4"];
    }else if(rating == 5){
      reviewComment = message["reviewComment5"];
    }
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: SSText(message["writeAReview"], 4, color: config.blueColor),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: config.blueColor), 
        onPressed: (){
          customNavigator(context,"enrichmentDetail/$courseId/3");
        }),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        height: MediaQuery.of(context).size.height,
        child: courseLoading ? 
        Center(
          child: CircularProgressIndicator()
        ) :
        ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: 1,
          itemBuilder: (BuildContext context ,int index){
          return Container(
            decoration: BoxDecoration(color: Colors.white),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: ImageBox(
                    CompanyAsset("avatar", config.user.pic), 
                    0, 
                    fit: BoxFit.cover, 
                    width: 90, 
                    height: 90
                  )
                ),
                SizedBox(height: 10),
                SSText(course.teacher.user.name, 4),
                SizedBox(height: 5),
                SSText(course.title, 4),
                SizedBox(height: 15),
                StarRating(
                  rating: rating,
                  size: 65,
                  color: config.orangeColor,
                  onRatingChanged: (rating)=> setState(()=> this.rating = rating),
                ),
                SSText(reviewComment, 2, color: config.orangeColor),
                SizedBox(height: 20),
                OCTextField(
                  hintText: message["writeYourComment"], 
                  maxLines: 8, 
                  controller: reviewController
                  )
                ],
              ),  
            );
          }
        ),
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(color: config.blueColor),
        child: FlatButton(
          child: SSText(message["sendReview"], 4, color: config.whiteGrayColor),
          onPressed: () async {
            showDialog(
              context: context,
              builder: (BuildContext context){
                return AlertDialog(
                  content: Row(
                    children: <Widget>[
                      CircularProgressIndicator(),
                      SizedBox(width: 15),
                      Expanded(child: SSText(message["submitReview"], 4))
                    ],
                  ),
                );
              }
            );
            Result result = await reviewApi.createReview(context, config.user.id.toString(), course.teacher.id.toString(), course.id.toString(), reviewController.text, rating);
            if(result.success == 1){
              setState(() {
                haveReviewed = true;
              });
              Navigator.pop(context);
              customNavigator(context, "enrichmentDetail/$courseId/3");
              showDialog(
                context: context,
                builder: (BuildContext context){
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(Icons.check_circle, color: config.darkGreenColor),
                            SizedBox(width: 15),
                            Expanded(
                              child: SSText(message["thanksReview"], 4)
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                            child: FlatButton(
                              child: SSText("OK", 4, color: Colors.white),
                              onPressed: (){
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        )
                      ],
                    )
                  );
                }
              );
            }else if(result.success == 0){
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (BuildContext context){
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: [
                            Icon(Icons.close, color: Colors.red),
                            SizedBox(width: 15),
                            Expanded(
                              child: SSText(message["reviewFailed"], 4)
                            )
                          ]
                        ),
                        Container(
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          width: MediaQuery.of(context).size.width,
                          child: FlatButton(
                            child: SSText("OK", 4, color: Colors.white),
                            onPressed: (){
                              Navigator.pop(context);
                            },
                          ),
                        )
                      ],
                    )
                  );
                }
              );
            }
          },
        ),
      ),
    );
  }
}