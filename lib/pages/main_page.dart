import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mymoney/pages/category_page.dart';
import 'package:mymoney/pages/home_page.dart';
import 'package:mymoney/pages/transaction_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late DateTime selectedDate;
  late List<Widget> _children;
  late int currentIndex = 0;

  @override
  void initState() {
    updateView(0, DateTime.now());
  }

  void updateView(int index, DateTime? date) {
    setState(() {
      if (date != null) {
        selectedDate = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      }
      currentIndex = index;
      _children = [
        HomePage(selectedDate: selectedDate),
        CategoryPage(),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (currentIndex == 0)
          ? CalendarAppBar(
              backButton: false,
              locale: 'en',
              accent: Color.fromARGB(255, 38, 155, 153),
              onDateChanged: (value) {
                setState(() {
                  print('Selected date: $value'); // Debugging statement
                  selectedDate =
                      value; // Update the selectedDate with the new value
                  updateView(currentIndex,
                      selectedDate); // Refresh the view with the updated date
                });
              },
              firstDate: DateTime.now().subtract(Duration(days: 140)),
              lastDate: DateTime.now(),
            )
          : PreferredSize(
              preferredSize: Size.fromHeight(100),
              child: Container(
                padding: EdgeInsets.all(20), // Menambahkan padding
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 38, 155, 153),
                  borderRadius:
                      BorderRadius.circular(20), // Menambahkan border radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 25, // Mengubah ukuran font
                    fontWeight: FontWeight.bold, // Membuat teks tebal
                    color: Colors.white, // Mengubah warna teks
                    fontFamily:
                        'Lobster', // Changed font family to 'Lobster' for a more attractive look
                  ),
                ),
                alignment: Alignment.center,
              )),
      floatingActionButton: Visibility(
        visible: currentIndex == 0, // Simplified visibility condition
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    TransactionPage(transactionWithCategory: null)));
          },
          backgroundColor: Color.fromARGB(255, 38, 155, 153),
          icon: Icon(Icons.add_box_sharp,
              size: 38.0,
              color: Colors.white), // Increased size and changed color to white
          label: Text('Add',
              style: TextStyle(
                  fontSize: 20.0, // Increased font size
                  fontWeight: FontWeight.bold, // Bold font
                  fontFamily:
                      'Roboto', // Kept 'Roboto' for the label for consistency and readability
                  color: Colors
                      .white)), // Text color changed to white for consistency
        ),
      ),
      body: _children[currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 3.0,
          color: Colors.grey[200], // Changed color for better visibility
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                  onPressed: () => updateView(0, DateTime.now()),
                  icon: Icon(Icons.home_work_rounded,
                      color: currentIndex == 0
                          ? const Color.fromARGB(255, 38, 155, 153)
                          : Color.fromARGB(255, 99, 109, 109),
                      size: 28.0)), // Icon color changes based on current index
              IconButton(
                  onPressed: () => updateView(1, null),
                  icon: Icon(Icons.format_list_bulleted,
                      color: currentIndex == 1
                          ? const Color.fromARGB(255, 38, 155, 153)
                          : Color.fromARGB(255, 99, 109, 109),
                      size: 28.0)), // Icon color changes based on current index
            ],
          )),
    );
  }
}
