import 'dart:io';
import 'package:ejust_attendance/loading.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MaterialApp(
      home: Home(),
      debugShowCheckedModeBanner: false,
      
    ));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  XFile? image;
  final ImagePicker picker = ImagePicker();
  bool isDialogActive = false;
  String dialogMessage = '';
  List<Map<String, dynamic>> data = [];
  bool isLoading = false;
  var imageLink;
  late Uri csvLink;


  //we can upload image from camera or from gallery based on parameter
  Future getImage(ImageSource media) async {
    await Permission.camera.status;
    await Permission.photos.status;
    await Permission.storage.status;
    var img = await picker.pickImage(source: media);
    var image_url;
    var csv_url;
    setState(() {
      isLoading = true;
      isDialogActive = false;
    });
    if (img != null) {
      // Convert XFile to bytes
      Uint8List imageBytes = await img.readAsBytes();
      // Encode bytes to base64
      String base64Image = base64Encode(imageBytes);
      
      if (imageBytes.length <= 10000000){
        final response = await sendImage(base64Image);
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'error' ) {
          setState(() {
            isDialogActive = true;
            dialogMessage = "There is problem with server please try again later";
            isLoading = false;
          });
          return;
        }
        List<dynamic> responseData = responseBody['result']['data'];
        // Ensure that the data is of type List<Map<String, dynamic>>
        data = List<Map<String, dynamic>>.from(responseData);
        dialogMessage = responseBody['message'];
        image_url = responseBody['image_url'];
        csv_url = responseBody['csv_url'];
      }
      else {
        setState(() {
          isDialogActive = true;
          dialogMessage = 'Image too large (max 10MB)';
        });
      }
      setState(() {
        isLoading = false;
        imageLink = image_url;
        csvLink = Uri.parse(csv_url);
        data = data;
      });
    }
    else {
      setState(() {
        isDialogActive = true;
        dialogMessage = 'Please Select Image';
        isLoading = false;
      });
    }
  }
  
  Future<http.Response> sendImage(String img) async {
    final Uri url = Uri.parse('https://serverless-ejust.onrender.com/upload');
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'image_data': img,
        }),
      );
      return response;
    } catch (e) {
      print('Error sending image: $e');
      rethrow; // You can choose to rethrow the exception or handle it accordingly.
    }
  }

  Future<void> exportCSV() async {
    try {
      if (!await canLaunchUrl(csvLink)) {
        throw Exception('Could not launch $csvLink');
      }
      await launchUrl(csvLink);
    } catch (e, stackTrace) {
      print('Error launching URL: $e\n$stackTrace');
      // Handle the error or log it for further investigation.
    }
  }

  //show popup dialog
  void myAlert() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: Text('Please choose media to select'),
            content: Container(
              height: MediaQuery.of(context).size.height / 6,
              child: Column(
                children: [
                  ElevatedButton(
                    //if user click this button, user can upload image from gallery
                    onPressed: () {
                      Navigator.pop(context);
                      getImage(ImageSource.gallery);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.image),
                        Text('From Gallery'),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    //if user click this button. user can upload image from camera
                    onPressed: () {
                      Navigator.pop(context);
                      getImage(ImageSource.camera);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.camera),
                        Text('From Camera'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EJUST Attendance'),
        backgroundColor: Colors.blue[900],
      ),
      body: isLoading ? Loading() : Center (
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              ElevatedButton(
                onPressed: () {
                  myAlert();
                },
                child: Text('Upload Photo'),
              ),
              SizedBox(
                height: 10,
              ),
              //if image not null show the image
              //if image null show text
              !isDialogActive
                ? (imageLink != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageLink,
                            fit: BoxFit.cover,
                            width: MediaQuery.of(context).size.width,
                            height: 300,
                          ),
                        ),
                      )
                    : Text(
                        "No Image",
                        style: TextStyle(fontSize: 20),
                      ))
                  : Center(
                    child: Text(
                      dialogMessage,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),
                    // Display the DataTable if the response has names and IDs
                    data != null && data.isNotEmpty
                        ? Column(
                          children: [
                            DataTable(
                              columns: [
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Name')),
                              ],
                              rows: data
                                  .map((person) => DataRow(cells: [
                                        DataCell(Text(person['id'].toString())),
                                        DataCell(Text(person['name'])),
                                      ]))
                                  .toList(),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                exportCSV();
                              },
                              child: Text('Export to CSV'),
                            ),
                          ],
                        )
                      : Container(),
            ],
        ),
      ),
    ),
    );
  }
}
