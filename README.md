# EJUST Attendance 

This Flutter project is designed for EJust Attendance, allowing users to upload class attendance images. The server will respond with an image indicating attendance status and a list of students present in the class. Additionally, the app provides functionality to export a CSV file containing the list of attending students.

### Features
1. Image Upload: Users can upload class attendance images through the app.

2. Server Response: The server responds with an image highlighting attendance status and a list of students present in the class.

3. CSV Export: Users have the option to export a CSV file containing the list of students attending the class.

### Getting Started
1. Clone the Repository:
```bash
git clone https://github.com/MarioMedWilson/ejust_attendance_flutter.git 
```
2. Navigate to Project Directory:
```bash
cd ejust_attendance_flutter
```
3. Install Dependencies & Run:
```bash
flutter pub get && flutter run
```
4. Change the API Route to your own in main file.
```dart
final Uri url = Uri.parse('https://...');
```


### Configuration
- Update the server endpoint in the code to match your backend API.

- Ensure the backend server is set up to handle attendance image uploads and respond with the necessary information.

