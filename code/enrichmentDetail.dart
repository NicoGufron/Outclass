import 'package:flutter/material.dart';
import 'package:shiftsoft/models/mchat.dart';
import 'package:shiftsoft/models/mcourse.dart';
import 'package:shiftsoft/models/mcourseuser.dart';
import 'package:shiftsoft/models/mresult.dart';
import 'package:shiftsoft/models/mteacher.dart';
import 'package:shiftsoft/resources/chatApi.dart';
import 'package:shiftsoft/resources/courseApi.dart';
import 'package:shiftsoft/resources/teacherApi.dart';
import 'package:shiftsoft/resources/transactionApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/OCCountdown.dart';
import 'package:shiftsoft/widgets/OCTextField.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:intl/intl.dart';
import 'package:shiftsoft/widgets/enrichment.dart';
import 'package:shiftsoft/widgets/imageBox.dart';
import 'package:shiftsoft/widgets/starRating.dart';

class EnrichmentDetail extends StatefulWidget {
  final int mode, id, fromWhere;

  const EnrichmentDetail({Key key, this.mode, this.id, this.fromWhere}) : super(key: key);
  @override
  _EnrichmentDetailState createState() => _EnrichmentDetailState();
}

class _EnrichmentDetailState extends State<EnrichmentDetail> {

  int timeDiff = 7200;
  int fromWhere;
  int hours = 0;
  int minutes = 0;
  int seconds = 0;

  String courseId = "";

  DateTime tempDate;

  Map<String, String> message = new Map();

  bool courseLoading = true;
  bool courseUserLoading = true;
  bool isTeacher = false;
  bool isStudent = false;
  bool haveBooked = false;
  bool timePassed = false;
  bool havePaid = false;
  bool courseFull = false;
  bool waitingPayment = false;
  bool chatLoading = true;

  OCCountdown ocCountdown;

  List<String> messageList = [
    "sessionDetail", "payNow", "sessionDescription", "theme", "subTheme", "addNewReview", "yesRegister", "sessionRegister", "registerConfirmation", "send", 
    "sharetoClass", "registerNow", "bookedPayNow", "registerConfirmationContd", "registerThanks", "paid", "numberOfParticipants", "payBefore", "payBeforeContd",
    "bookSession", "classFull", "sessionDone", "lesson", "paymentInProgress", "paymentFailed", "bookingInProgress", "student", "students", "waitingPayment", "toClass"
  ];
  
  Course course;
  List<CourseUser> courseUser;
  List<Chat> chatList;
  
  @override
  void initState() {
    super.initState();
    courseId = widget.id.toString();
  }

  void didChangeDependencies() async {
    super.didChangeDependencies();
    
    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    // await checkUser();
    if(courseLoading){
      initCourseById();
    }
    
  }

  initChatList()async{
    Configuration config = Configuration.of(context);
    setState(() {
      chatLoading = true;
    });

    // dapatkan chat list user dan chat list teacher dari api chat member
    String parameter = "0,";
    var chatIdList = []; 
    final userChatList = await chatApi.getChatMemberList(context, parameter: "filtersArr[0][]=user_id|=|${config.user.id}|god");
    // final teacherChatList = await chatApi.getChatMemberList(context, parameter: "filtersArr[0][]=user_id|=|${course.teacherId}|god");

    if(userChatList.length > 0){
      userChatList.map((item){
        chatIdList.add(item.chatId);
      }).toList();
    }

    // if(teacherChatList.length > 0){
    //   teacherChatList.map((item){
    //     chatIdList.add(item.chatId);
    //   }).toList();
    // }
    parameter += chatIdList.join(',');

    chatList = await chatApi.getChatList(context, 1, parameter: "filtersArr[0][]=course_id|=|$courseId|god&filtersArr[1][]=id|in|$parameter|god");

    setState(() {
      chatLoading = false;
      chatList = chatList;
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

  initCourseUser() async {
    Configuration config = Configuration.of(context);
    setState(() {
      courseUserLoading = true;
    });

    courseUser = await courseApi.getCourseUserList(context, parameter: "filtersArr[0][]=course_id|=|"+courseId+"|god&filtersArr[0][]=user_id|=|"+ config.user.id.toString() +"|god");
    
    if(courseUser == null || courseUser.isEmpty) {
      haveBooked = false;
      timePassed = false;
      havePaid = false;
      waitingPayment = false;
    } else {
      if(courseUser[0].status == 0) {
        waitingPayment = true;
        haveBooked = true;
        if(DateTime.now().difference(courseUser[0].createdAt).inHours >= 2) {
          timePassed = true;
          course.pricePayment = course.priceBooking;
        }
      } else if(courseUser[0].status >= 2) {
        haveBooked = true;
        timePassed = true;
        havePaid = true;
      }
    }

    if(timePassed == false && haveBooked == true) {
      tempDate = courseUser[0].createdAt.add(Duration(hours: 2));
      ocCountdown = OCCountdown(tempDate);
      if(ocCountdown != null){
        ocCountdown.streamController.stream.listen((data){
          setState(() {
            hours = data ~/ (60 * 60) % 24;
            minutes = (data ~/ 60) % 60;
            seconds = data % 60;
            // timeDiffHours = data ~/ ;
          });
        });
      }
    }

    initChatList();
    
    setState(() {
      courseUserLoading = false;
      courseUser = courseUser;
      haveBooked = haveBooked;
      waitingPayment = waitingPayment;
      hours = hours;
      minutes = minutes;
      seconds = seconds;
    });
  }

  @override
  void dispose(){
    if (ocCountdown != null) {
      ocCountdown.cancelCountdown();
    }
    super.dispose();
  }

  initCourseById() async {
    setState(() {
      courseLoading = true;
    });

    course = await courseApi.getCourse(context, widget.id, parameter: "with[0]=Teacher.User&with[1]=Lesson&with[2]=Circle");

    if(course.status == 3)
      course.pricePayment = course.priceBooking;
    if(course.maxStudent <= course.totalPaidStudent){
      courseFull = true;
    } else {
      courseFull = false;
    }

    initCourseUser();

    setState(() {
      courseLoading = false;
      course = course;
      courseFull = courseFull;
    });
  }

  bool bookmarked = false;

  Future<Null> _refresh() async {
    initCourseById();
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);

    String tempHour = hours.toString();
    String tempMinute = minutes.toString();
    String tempSecond = seconds.toString();

    if(hours < 10)
      tempHour = "0" + tempHour;
    
    if(minutes < 10)
      tempMinute = "0" + tempMinute;
    
    if(seconds < 10)
      tempSecond = "0" + tempSecond;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: SSText(message["sessionDetail"], 3, color: config.blueColor),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: config.blueColor), 
        onPressed: (){
          customNavigator(context,"enrichmentDashboard");
        }),
        actions: <Widget>[
          IconButton(
            icon: Image.asset("assets/icon/chat-balloon-blue.png", width: 23, height: 23),
            onPressed: chatLoading ? null : () async{

              if(chatList.length > 0){
                customNavigator(
                  context, 
                  "chatDetail/${chatList[0].id}/1",
                  arguments: chatList[0]
                );

              }else {
                final result = await chatApi.createChat(context, courseId: int.parse(courseId));

                if(result.success == 1){
                  final chatId = result.data['ID'];
                  customNavigator(
                    context, 
                    "chatDetail/${chatId}/1",
                  );
                } else {
                  printHelp(result.message);
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: courseLoading ?
          Center(
            child: CircularProgressIndicator()
          ) 
          :
          ListView.builder(
            itemCount: 1,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, int index){
              final item = course;
              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      child: Enrichment(
                        course: course, 
                        message: message,
                        enrichmentCard: true //jangan sampe false
                      )
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(left: 15, right: 15),
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: 20),
                            SSText(message["theme"],5),
                            SSText(item.topic, 3, color: Colors.black),
                            SizedBox(height: 15),
                            SSText(message["lesson"], 5,),
                            SSText(item.lesson.name, 3, color: Colors.black),
                            isTeacher ? 
                            Column(
                              children: <Widget>[
                                SizedBox(height: 23),
                                SSText(message["numberOfParticipants"], 5),
                                SSText(item.totalPaidStudent.toString(), 3, color: Colors.black),
                              ],
                            ) : Container(),
                            Container(
                              padding: EdgeInsets.only(top: 20),
                              child: Row(
                                children: <Widget>[
                                  Image.asset("assets/icon/notes.png", color: Colors.black, height: 14, width: 11),
                                  SizedBox(width: 18),
                                  SSText(message["sessionDescription"], 5)
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(left: 30),
                              child: SSText(item.description, 5, color: Colors.black, fontWeight: FontWeight.w500 )
                            ),
                            SizedBox(height: 30),
                            item.status == 5 && havePaid ?
                            Container(
                              child: InkWell(
                                splashColor: config.whiteGrayColor,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    SSText(message["addNewReview"], 5, color: config.blueColor),
                                    SizedBox(width: 8),
                                    Image.asset("assets/icon/pencil.png", width: 13, height: 13),
                                  ],
                                ),
                                onTap: (){
                                  customNavigator(context, "reviewForm/$courseId/3", arguments: courseId);
                                }
                              )
                            )
                            :
                            Container(),
                            // courseFull == false && havePaid == false && haveBooked == false && item.status < 3 ?
                            // Container(
                            //   height: 90,
                            //   padding: EdgeInsets.only(top: 23),
                            //   child: InkWell(
                            //     child: Card(
                            //       child: Row(
                            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //         children: <Widget>[
                            //           Expanded(
                            //             flex: 1,
                            //             child: Image.asset("assets/icon/bookmark_session.png", scale: 5)),
                            //             //harusnya kalo status 3 dan orang baru belom join / booking
                            //           SSText(message["bookSession"] + " - "+ numberFormat(item.priceBooking,"idr"), 4, color: config.blueColor),
                            //           Expanded(
                            //             flex: 1,
                            //             child: Icon(Icons.keyboard_arrow_right, color: config.blueColor))
                            //         ],
                            //       ),
                            //     ),
                            //     onTap: (){
                            //       showDialog(context: context, builder: (BuildContext context){
                            //         return AlertDialog(
                            //           content: Column(
                            //             crossAxisAlignment: CrossAxisAlignment.start,
                            //             mainAxisSize: MainAxisSize.min,
                            //             children: <Widget>[
                            //               SSText(message["sessionRegister"], 4),
                            //               SizedBox(height: 10),
                            //               SSText(message["registerConfirmation"] + numberFormat(item.priceBooking, "idr") + message["registerConfirmationContd"].toLowerCase(), 5),
                            //               SizedBox(height: 10),
                            //               Container(
                            //                 width: MediaQuery.of(context).size.width,
                            //                 decoration: BoxDecoration(color: config.orangeColor),
                            //                 child: FlatButton(
                            //                   child: SSText(message["yesRegister"], 4, color: config.whiteGrayColor),
                            //                   onPressed: () async {
                            //                     showDialog(
                            //                       context: context, builder: (BuildContext context){
                            //                         return AlertDialog(
                            //                           content: Row(
                            //                             children: <Widget>[
                            //                               CircularProgressIndicator(),
                            //                               SizedBox(width: 20),
                            //                               SSText(message["bookingInProgress"], 4)
                            //                               ],
                            //                             )
                            //                           );
                            //                         }
                            //                     );
                            //                     Result result = await courseApi.createBooking(context, config.user.id.toString(), courseId);
                            //                     if(result.success == 1){
                            //                       Navigator.pop(context);
                            //                       Navigator.pop(context);
                            //                       setState(() {
                            //                         haveBooked = true;
                            //                       });
                            //                       showDialog(
                            //                         context: context, builder: (BuildContext context){
                            //                           return AlertDialog(
                            //                             content: Column(
                            //                               crossAxisAlignment: CrossAxisAlignment.center,
                            //                               mainAxisSize: MainAxisSize.min,
                            //                               children: <Widget>[
                            //                                 Icon(Icons.check_circle, color: config.darkGreenColor),
                            //                                 SSText(message["registerThanks"] + numberFormat(course.pricePayment, "idr"), 4),
                            //                               ],
                            //                             )
                            //                           );
                            //                         }
                            //                       );
                            //                       setState(() {
                            //                         initCourseById();
                            //                         initCourseUser();
                            //                       });
                            //                     }
                            //                   },
                            //                 ),
                            //               )
                            //             ],
                            //           )
                            //         );
                            //       });
                            //     }
                            //   ),
                            // )
                            // : havePaid == false && haveBooked && item.status < 3 && timePassed == false && courseFull == false ?
                            // Container(
                            //   height: 100,
                            //   padding: EdgeInsets.only(top: 23),
                            //   child: InkWell(
                            //     child: Card(
                            //       child: Row(
                            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //         children: <Widget>[
                            //           Expanded(
                            //             flex: 1,
                            //             child: Icon(Icons.timelapse, color: config.blueColor)
                            //           ),
                            //           Expanded(
                            //             flex: 3,
                            //             // child: SSText(message["payBefore"] + DateFormat("HH:MM").format(item.createdAt.add(Duration(hours: 2))) + message["payBeforeContd"].toLowerCase() , 6, color: config.blueColor)
                            //             child: SSText(message["payBefore"] + " $tempHour:$tempMinute:$tempSecond " + message["payBeforeContd"].toLowerCase() + " " + numberFormat(course.priceBooking, "idr") , 6, color: config.blueColor)
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // ) : Container()
                            havePaid == false && haveBooked && item.status < 3 && timePassed == false && courseFull == false ?
                            Container(
                              height: 100,
                              padding: EdgeInsets.only(top: 23),
                              child: InkWell(
                                child: Card(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Expanded(
                                        flex: 1,
                                        child: Icon(Icons.timelapse, color: config.blueColor)
                                      ),
                                      Expanded(
                                        flex: 3,
                                        // child: SSText(message["payBefore"] + DateFormat("HH:MM").format(item.createdAt.add(Duration(hours: 2))) + message["payBeforeContd"].toLowerCase() , 6, color: config.blueColor)
                                        child: SSText(message["payBefore"] + " $tempHour:$tempMinute:$tempSecond " + message["payBeforeContd"].toLowerCase() + " " + numberFormat(course.priceBooking, "idr") , 6, color: config.blueColor)
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ) : Container()
                          ],
                        )
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: courseLoading || courseUserLoading ?
      Center(
        child: CircularProgressIndicator()
      ) 
      :
      courseFull ?
      Container(
        decoration: BoxDecoration(color: config.lightBlueColor),
        child: FlatButton(
          child: SSText(message["classFull"], 5, color: config.blueColor)
        )
      )
      :
      havePaid ? 
      Container(
        decoration: BoxDecoration(color: config.lightGreenColor),
        child: course.status == 5 && courseUser[0].status < 4? 
        //buat satu pengecekan kalo misalkan kelas lagi dibuat, status 3 ? hrusnya dibuat seberapa lama lagi kelas akan terbuat
        FlatButton(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset("assets/icon/pencil.png", width: 13, height: 13, color: config.darkGreenColor),
              SizedBox(width: 8),
              SSText(message["addNewReview"], 5, color: config.darkGreenColor),
            ],
          ),
          onPressed: (){
            customNavigator(context, "reviewForm/${course.id}/3");
          },
        )
        :
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: FlatButton(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.check, color: config.darkGreenColor),
                    SizedBox(width: 10),
                    SSText(message["toClass"], 5, color: config.darkGreenColor),
                  ],
                ),
                onPressed: (){
                  customNavigator(context, "circleList/${course.circleId}/3", arguments: course.circle);
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(color: Colors.white),
                child: FlatButton(
                  child: Icon(Icons.event_note, color: config.blueColor),
                  onPressed: (){
                    customNavigator(context,"transactionDetail/${courseUser[0].transactionMasterId}/3");
                  },
                ),
              ),
            )
          ]
        )
      )
      :
      waitingPayment ? //menunggu pembayaran
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(color: config.orangeColor),
              child: FlatButton(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.timelapse, color: Colors.white),
                    SizedBox(width: 10),
                    SSText(message["waitingPayment"], 5, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(color: Colors.white),
              child: FlatButton(
                child: Icon(Icons.event_note, color: config.orangeColor),
                onPressed: (){
                  customNavigator(context,"transactionDetail/${courseUser[0].transactionMasterId}/3");
                },
              ),
            ),
          )
        ]
      )
      :
      Container(
        decoration: BoxDecoration(color: havePaid && haveBooked ? config.lightGreenColor : config.blueColor ),
        child: FlatButton(
          child:
          haveBooked && course.status <= 3 ? //harusnya ada pengecekan lagi kalo dalam waktu dua jam, harganya berubah di bottom navigation bar 
          SSText(message['bookedPayNow'] + " - " + numberFormat(course.pricePayment, "idr"), 5, color: config.whiteGrayColor) 
          :
          SSText(message["registerNow"] + " - " + numberFormat(course.pricePayment, "idr"), 5, color: config.whiteGrayColor),
          onPressed: (){ 
            customNavigator(context, "transactionConfirmation/${widget.id}/3");
          },
        ),
      )
    );
  }
}