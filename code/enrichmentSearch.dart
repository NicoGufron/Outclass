import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shiftsoft/models/mcourse.dart';
import 'package:shiftsoft/models/mteacher.dart';
import 'package:shiftsoft/resources/courseApi.dart';
import 'package:shiftsoft/resources/teacherApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/OCTextField.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:shiftsoft/widgets/SSTextField.dart';
import 'package:intl/intl.dart';
import 'package:shiftsoft/widgets/enrichment.dart';
import 'package:shiftsoft/widgets/imageBox.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';
import 'package:shimmer/shimmer.dart';

class EnrichmentSearch extends StatefulWidget {
  @override
  _EnrichmentSearchState createState() => _EnrichmentSearchState();
}

class _EnrichmentSearchState extends State<EnrichmentSearch> {

  TextEditingController searchController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  TextEditingController startPriceRange = TextEditingController();
  TextEditingController endPriceRange = TextEditingController();
  TextEditingController subjectLesson = TextEditingController();

  bool isSearching = true;
  bool courseListLoading = true;
  bool highestPrice = false;
  bool highestRating = false;
  bool fourStar = false;
  bool fiveStar = false;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now().add(Duration(days:3));

  String fromDate, toDate;
  String searchQuery = "Search Query";
  String searchText = "";
  String parameter;
  List<String> parameterFilterList = [];

  Map<String, String> message = new Map();

  List<String> messageList = [
    "sort", "apply", "filter", "highestPrice", "lowestPrice", "sortBy", "highestRating", 
    "closestSchedule", "priceRange", "filterDate", "fromDate", "toDate", "lessonFilterTitle", "lessonFilter",
    "session", "searchEnrichment", "students", "student"
  ];
  List<Course> courseList = [];

  @override
  void initState() {
    super.initState();
    
    // nambahin filter untuk mencari course yang dibuat oleh id guru yg dilihat
    // variable parameter untuk mencari filter yang sudah ditekan, rencananya untuk concat setiap filter yang ditekan
  
  }

  void didChangeDependencies() async {
    super.didChangeDependencies();
    
    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    if(courseListLoading)
      initCourseList();
  }

  initCourseList({String parameter = ""}) async {
    setState(() {
      courseListLoading = true;
    });
    
    // ditambahkan default preload
    parameter = "with[0]=Teacher.User&filtersArr[0][]=status|in|2,3&" + parameter;

    courseList = await courseApi.getCoursesList(context, 0, parameter: parameter);
    
    // FILTER KHUSUS RATING
    String tempFilter = "";

    if(fourStar && fiveStar){
      tempFilter = "&filtersArr[0][]=Rating|between|4,5";
    } else if(fourStar){
      tempFilter = "&filtersArr[0][]=Rating|between|4,4.9";
    } else if(fiveStar){
      tempFilter = "&filtersArr[0][]=Rating|=|5";
    }

    if(tempFilter != "") {
      List<Teacher> teacherList = await teacherApi.getTeacherList(context, parameter: tempFilter);
      List<Course> tempCourseList = [];
      
      for(int i = 0; i < courseList.length; i++) {
        final item = courseList[i];
        bool isExist = false;
        
        for(int j = 0; j < teacherList.length; j++) {
          if (item.teacherId == teacherList[j].id) {
            isExist = true;
          }
        }

        if (isExist) {
          tempCourseList.add(item);
        }
      }

      courseList = tempCourseList;
    }
    // FILTER KHUSUS RATING

    setState(() {
      courseListLoading = false;
      courseList = courseList;
    });
  }

  Widget _buildSearchField(){
    return TextField(
      controller: searchController,
      autofocus: true,
      decoration: InputDecoration(
          hintText: message["searchEnrichment"],
          hintStyle: TextStyle(color:Colors.blue, fontSize: 14),
          suffixIcon: IconButton(icon: Icon(Icons.cancel, color: Colors.blue), 
          onPressed: (){
            searchController.clear();
            initCourseList();
          }
        )
      ),
      style: TextStyle(color: Colors.black, fontSize: 16),
      onSubmitted: (value) {
        courseList = [];
        List<String> tempParameterFilterList = parameterFilterList;
        tempParameterFilterList.add("&filtersArr[0][]=title|like|*${searchController.text}*");

        String parameter = tempParameterFilterList.join("&");
        initCourseList(parameter: parameter);
      },
    );
  }

  Future<Null> _selectDateFrom(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: _fromDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != _fromDate)
      setState(() {
        _fromDate = picked;
        fromDate = (DateFormat("yyyy-MM-dd").format(_fromDate)).toString();
        fromDateController.text = fromDate;
      });
      // String dateFilter = '${(DateFormat('yyyy-MM-dd').format(_fromDate)).toString()}, ${(DateFormat('yyyy-MM-dd').format(_toDate)).toString()}';
      // String filter = "filtersArr[0][]=start_time|between|$dateFilter 23:59:59";
      // parameterFilterList.add(filter);
  }
  Future<Null> _selectDateTo(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: _toDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != _fromDate)
      setState(() {
        _toDate = picked;
        toDate = (DateFormat("yyyy-MM-dd").format(_toDate)).toString();
        toDateController.text = toDate;
      });
      // String dateFilter = '${(DateFormat('yyyy-MM-dd').format(_fromDate)).toString()}, ${(DateFormat('yyyy-MM-dd').format(_toDate)).toString()}';
      // String filter = "filtersArr[0][]=start_time|between|$dateFilter 23:59:59";
      // parameterFilterList.add(filter);
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);

    List<Widget> courseWidgetList = [];

    for(int i = 0; i < courseList.length; i++){
      final item = courseList[i];
      if(item.title.toLowerCase().contains(searchText.toLowerCase())){
        courseWidgetList.add(
          Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ImageBox(CompanyAsset("course", item.image), 0, fit: BoxFit.cover, width: 150, height: 150),
                  Container(
                    padding:EdgeInsets.only(left: 15, top:10),
                    child:Row(
                      children: <Widget>[
                        CircleAvatar(backgroundColor: Color(0xFFFFEDFA)),
                        SizedBox(width: 8),
                        SSText(item.teacher.user.name, 8)
                      ]
                    )
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 15, top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SSText(item.title, 4),
                        SSText(DateFormat("EEEE, dd MMM yyyy").format(item.startTime), 8),
                        SSText(DateFormat("HH:mm").format(item.startTime), 8),
                        SizedBox(height: 20),
                        Row(
                          children: <Widget>[
                            Icon(Icons.star,color: config.orangeColor,size: 20),
                            SizedBox(width: 5),
                            SSText(item.teacher.rating.toString(),8,color: Colors.black),
                            SizedBox(width: 5),
                            SSText("·", 2),
                            SizedBox(width: 5),
                            SSText(numberFormat(
                              item.status == 2 ? item.pricePayment : item.priceBooking,
                              "") + "/ sesi",8),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Icon(Icons.account_circle, color: config.blueColor),
                            SizedBox(width: 8),
                            item.minStudent > 0 ?
                              SSText("min " + item.minStudent.toString() + " " +  message["students"].toLowerCase(), 8, color: config.blueColor) 
                              :
                              SSText("min " + item.minStudent.toString() + " " + message["student"].toLowerCase(), 8, color: config.blueColor)
                        ]
                      )
                    ],
                  )),
                ],
              )
            ),
            onTap: (){
              customNavigator(
                context,
                "enrichmentDetail/${item.id}/3"
              );
            }
          )
        ));
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: config.blueColor,), onPressed: (){
          Navigator.pop(context);
        }),
        title: _buildSearchField(),
        actions: <Widget>[
          IconButton(icon: Image.asset("assets/icon/filter.png", width: 21, height: 20, color: config.blueColor), 
          onPressed: () {
            showModalBottomSheet(
              isScrollControlled: true,
              context: context, 
              builder: (BuildContext context){
                return StatefulBuilder(
                  builder: (context, setModalState){
                  return Container(
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30), 
                          topRight: Radius.circular(30),
                          bottomLeft: Radius.zero,
                          bottomRight: Radius.zero,
                        )
                      ),
                      height: MediaQuery.of(context).size.height * 0.85,
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10)
                              ),
                            ),
                          ),
                          SSText("Filter", 2, color: config.blueColor),
                          SizedBox(height: 20),
                          StatefulBuilder(
                            builder: (context, setModalState){
                              return Container(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: ListView.builder(
                                  itemCount: 1,
                                  shrinkWrap: true,
                                  scrollDirection: Axis.vertical,
                                  itemBuilder: (BuildContext context, int index){
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        SSText(message["lessonFilterTitle"], 6, color: Colors.black, fontWeight: FontWeight.bold),
                                        SizedBox(height: 10),
                                        OCTextField(
                                          hintText: message["lessonFilter"], 
                                          controller: subjectLesson
                                        ),
                                        SizedBox(height: 12),
                                        SSText(message["filterDate"], 6, color: Colors.black, fontWeight: FontWeight.bold),
                                        SizedBox(height: 12),
                                        Row(
                                          // crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Container(
                                              width: 150,
                                              height: 50,
                                              child: InkWell(
                                                onTap: () {
                                                  _selectDateFrom(context);
                                                },
                                                child: GestureDetector(
                                                  onTap:(){
                                                    _selectDateFrom(context);
                                                  },
                                                  child: AbsorbPointer(
                                                    child: OCTextField(
                                                      keyboardType: TextInputType.datetime,
                                                      controller: fromDateController,
                                                      data: DateFormat("dd MM yyyy").format(_fromDate),
                                                      hintText: message["fromDate"],
                                                      prefixIcon: Icon(Icons.date_range),
                                                    ),
                                                  ),
                                                )
                                              ),
                                            ),
                                            SSText("-", 6, color: Colors.black),
                                            Container(
                                              width: 150,
                                              height: 50,
                                              child: InkWell(
                                                onTap: (){
                                                  _selectDateTo(context);
                                                },
                                                child: GestureDetector(
                                                  onTap: (){
                                                    _selectDateTo(context);
                                                  },
                                                  child: AbsorbPointer(child: OCTextField(
                                                      controller: toDateController,
                                                      data: DateFormat("dd MMM yyyy").format(_toDate),
                                                      hintText: message["toDate"],
                                                      prefixIcon: Icon(Icons.date_range),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        SSText("Rating", 6, color: Colors.black, fontWeight: FontWeight.bold),
                                        SizedBox(height: 12),
                                        Row(
                                          children: <Widget>[
                                            Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: fourStar ? config.lightBlueColor : null,
                                                border: Border.all(color: fourStar ? config.blueColor : Colors.black)
                                              ),
                                              child: FlatButton(
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                child: Row(
                                                  children: <Widget>[
                                                    Icon(Icons.star, color: config.orangeColor),
                                                    SSText(
                                                      "4 Star", 4, color: fourStar ? config.blueColor : Colors.black
                                                    ),
                                                  ],
                                                ),
                                                onPressed: (){
                                                  setModalState((){
                                                    fourStar = !fourStar;
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 15),
                                            Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: fiveStar ? config.lightBlueColor : null,
                                                border: Border.all(color: fiveStar ? config.blueColor : Colors.black)
                                              ),
                                              child: FlatButton(
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                child: Row(
                                                  children: <Widget>[
                                                    Icon(Icons.star, color: config.orangeColor),
                                                    SSText(
                                                      "5 Star", 4, color: fiveStar ? config.blueColor : Colors.black
                                                    ),
                                                  ],
                                                ),
                                                onPressed: (){
                                                  setModalState((){
                                                    fiveStar = !fiveStar;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        // bintang kecil di langit yang biru, ada 5
                                        SizedBox(height: 12),
                                        SSText(message["priceRange"], 6, color: Colors.black, fontWeight: FontWeight.bold),
                                        SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Container(
                                              width: 150,
                                              height: 50,
                                              child: OCTextField(
                                                controller: startPriceRange,
                                                keyboardType: TextInputType.number,
                                                hintText: "15.000",
                                                //tambahin number format dong kalo tiap kali dia berubah jadi angka ribuan
                                              )
                                            ),
                                            SSText("-", 6, color: Colors.black),
                                            Container(
                                              width: 150,
                                              height: 50,
                                              child: OCTextField(
                                                controller: endPriceRange,
                                                keyboardType: TextInputType.number,
                                                hintText: "35.000",
                                                //tambahin number format dong kalo tiap kali dia berubah jadi angka ribuan
                                              )
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        SSText(message["sortBy"], 6, color: Colors.black, fontWeight: FontWeight.bold),
                                        Container(
                                          height: 150,
                                          padding: EdgeInsets.only(top:12),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: <Widget>[
                                              Container(
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  color: highestPrice ? config.lightBlueColor : Colors.white,
                                                  border: Border.all(color: highestPrice ? config.blueColor : Colors.black)
                                                ),
                                                child: FlatButton(
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  child: SSText(message["highestPrice"], 6, color: highestPrice ? config.blueColor : Colors.black),
                                                  onPressed: (){
                                                    setModalState(() {
                                                      highestRating = false;
                                                      highestPrice = !highestPrice;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Container(
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  color: highestRating ? config.lightBlueColor : Colors.white,
                                                  border: Border.all(color: highestRating ? config.blueColor : Colors.black)
                                                ),
                                                child: FlatButton(
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  child: SSText(message["highestRating"], 6, color: highestRating ?  config.blueColor : Colors.black),
                                                  onPressed: (){
                                                    setModalState(() {
                                                      highestPrice = false;
                                                      highestRating = !highestRating;
                                                    });
                                                  },
                                                ),
                                              )
                                            ],
                                          )
                                        )
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 40),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.white),
                                    child: FlatButton(
                                      child: SSText("Reset Filter", 3, color: Colors.black),
                                      onPressed: (){
                                        setModalState(() {
                                          subjectLesson.clear();
                                          toDateController.clear();
                                          fromDateController.clear();
                                          startPriceRange.clear();
                                          endPriceRange.clear();
                                          fourStar = false;
                                          fiveStar = false;
                                          highestRating = false;
                                          highestPrice = false;
                                          parameterFilterList = [];
                                        });
                                        // initCourseList();
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    decoration: BoxDecoration(color: config.blueColor),
                                    child: FlatButton(
                                      child: SSText(message["apply"] + " "+ message["filter"], 3, color: config.whiteGrayColor),
                                      onPressed: () {
                                        parameterFilterList = [];

                                        //filter nama mata pelajaran
                                        if(subjectLesson.text != ""){
                                          parameterFilterList.add("&filtersArr[0][]=title|like|*${subjectLesson.text}*");
                                        } else if(subjectLesson.text != "" && highestPrice){
                                          parameterFilterList.add("order=price_per_session-desc&filtersArr[0][]=title|like|*${subjectLesson.text}*");
                                        } else if(fromDateController.text != "" && toDateController.text != ""){
                                          //filter Date
                                          parameterFilterList.add("filtersArr[0][]=start_time|between|${fromDateController.text}, ${toDateController.text} 23:59:59");
                                        } else if(fromDateController.text != "" && toDateController.text != "" && highestPrice){
                                          parameterFilterList.add("order=price_per_session-desc&filtersArr[0][]=start_time|between|${fromDateController.text}, ${toDateController.text} 23:59:59");
                                        } else if(fromDateController.text != "" && highestPrice){
                                          parameterFilterList.add("order=price_per_session-desc&filtersArr[0][]=start_time|>|${fromDateController.text} 23:59:59");
                                        } else if(toDateController.text != "" && highestPrice){
                                          parameterFilterList.add("order=price_per_session-desc&filtersArr[0][]=start_time|<|${toDateController.text} 23:59:59");
                                        } else if(fromDateController.text != ""){
                                          parameterFilterList.add("filtersArr[0][]=start_time|>|${fromDateController.text} 23:59:59");
                                        } else if(toDateController.text != ""){
                                          parameterFilterList.add("filtersArr[0][]=start_time|<|${toDateController.text} 23:59:59");
                                        }

                                        //filter price
                                        else if(startPriceRange.text != "" && endPriceRange.text != ""){
                                          parameterFilterList.add("filtersArr[0][]=price_per_session|between|${startPriceRange.text},${endPriceRange.text}");
                                        }else if(startPriceRange.text != "" && endPriceRange.text != "" && highestPrice){
                                          parameterFilterList.add("order=price_per_session-desc&filtersArr[0][]=price_per_session|between|${startPriceRange.text}, ${endPriceRange.text}"); 
                                        }else if(startPriceRange.text != ""){
                                          parameterFilterList.add("filtersArr[0][]=price_per_session|>|${startPriceRange.text}");
                                        }else if(endPriceRange.text != ""){
                                          parameterFilterList.add("filtersArr[0][]=price_per_session|<|${endPriceRange.text}");
                                        }

                                        //filter sort by
                                        if(highestPrice) {
                                          parameterFilterList.add("order=price_per_session-desc");
                                        }
                                        // if(highestRating) {
                                        //   initCourseList();
                                        // }
                                        Navigator.pop(context);
                                        courseList = [];
                                        parameter = parameterFilterList.join("&");
                                        print("parameter: " + parameter);
                                        initCourseList(parameter: "&" + parameter);
                                      },
                                    )
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }
                );
                }
              );
            }
          )
        ],
      ),
      body: ListView.builder(
        itemCount: 1,
        itemBuilder: (BuildContext context, int index){
          return Container(
            decoration: BoxDecoration(color: Colors.white),
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 20),
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
            : 
            PlaceholderList(type: "enrichmentsearch", paddingTop: MediaQuery.of(context).size.width / 1.5)
          );
        }
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
      childAspectRatio: 0.52,
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