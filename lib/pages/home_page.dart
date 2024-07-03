import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mymoney/models/database.dart';
import 'package:mymoney/models/transaction_with_category.dart';
import 'package:mymoney/pages/transaction_page.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  final DateTime selectedDate;

  const HomePage({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppDb db = AppDb();
  final ValueNotifier<double> totalIncome = ValueNotifier<double>(0);
  final ValueNotifier<double> totalExpense = ValueNotifier<double>(0);

  void _calculateTotals(List<TransactionWithCategory> transactions) {
    double income = 0;
    double expense = 0;

    for (var transaction in transactions) {
      if (transaction.category.type == 1) {
        income += transaction.transaction.amount;
      } else {
        expense += transaction.transaction.amount;
      }
    }

    totalIncome.value = income;
    totalExpense.value = expense;
  }

  Future<void> deleteTransaction(int id) async {
    await db.deleteTransaction(id);
  }

  @override
  Widget build(BuildContext context) {
    String monthYear =
        DateFormat('MMMM yyyy', 'id_ID').format(widget.selectedDate);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<TransactionWithCategory>>(
          stream: db.getTransactionsByMonth(widget.selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              _calculateTotals(snapshot.data!);

              // Aggregate transactions by category type
              Map<int, double> categoryTotals = {};
              for (var transaction in snapshot.data!) {
                if (categoryTotals.containsKey(transaction.category.type)) {
                  categoryTotals[transaction.category.type] =
                      categoryTotals[transaction.category.type]! +
                          transaction.transaction.amount;
                } else {
                  categoryTotals[transaction.category.type] =
                      transaction.transaction.amount.toDouble();
                }
              }

              List<BarChartGroupData> chartData =
                  categoryTotals.entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                        y: entry.key == 1 ? entry.value.toDouble() : 0,
                        colors: [Colors.green]),
                    BarChartRodData(
                        y: entry.key == 0 ? entry.value.toDouble() : 0,
                        colors: [Colors.red]),
                  ],
                );
              }).toList();

              // Filter transactions by selected date
              List<TransactionWithCategory> transactionsForSelectedDate =
                  snapshot.data!.where((transaction) {
                return transaction.transaction.transactionDate.day ==
                    widget.selectedDate.day;
              }).toList();

              return CustomScrollView(
                slivers: [
                  // Chart data
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 1000000,
                            groupsSpace: 20,
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: SideTitles(
                                showTitles: true,
                                getTextStyles:
                                    (BuildContext context, double value) =>
                                        const TextStyle(
                                  color: Color.fromARGB(255, 38, 155, 153),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                margin: 20,
                                getTitles: (double value) {
                                  if (value.toInt() == 0) {
                                    return 'Expense';
                                  } else if (value.toInt() == 1) {
                                    return 'Income';
                                  } else {
                                    return '';
                                  }
                                },
                              ),
                              leftTitles: SideTitles(showTitles: false),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.5),
                                  width: 1),
                            ),
                            barGroups: chartData.map((data) {
                              final gradientColors =
                                  data.barRods[0].y > data.barRods[1].y
                                      ? [Colors.greenAccent, Colors.green]
                                      : [Colors.redAccent, Colors.red];
                              return BarChartGroupData(
                                x: data.x,
                                barRods: [
                                  BarChartRodData(
                                    y: data.barRods[0].y,
                                    colors: [
                                      gradientColors[0],
                                      gradientColors[1]
                                    ],
                                    gradientColorStops: [0.5, 1.0],
                                    gradientFrom: const Offset(0, 0),
                                    gradientTo: const Offset(0, 1),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                  BarChartRodData(
                                    y: data.barRods[1].y,
                                    colors: [
                                      gradientColors[0].withOpacity(0.5),
                                      gradientColors[1].withOpacity(0.5)
                                    ],
                                    gradientColorStops: [0.5, 1.0],
                                    gradientFrom: const Offset(0, 0),
                                    gradientTo: const Offset(0, 1),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                ],
                              );
                            }).toList(),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.blueGrey,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    rod.y.round().toString(),
                                    TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(11.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.fromARGB(255, 244, 230, 195),
                                  Color.fromARGB(255, 255, 235, 186),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 183, 182, 182)
                                      .withOpacity(0.5),
                                  spreadRadius: 1,
                                ),
                              ],
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.attach_money,
                                      color: Color.fromARGB(255, 36, 161, 105),
                                      size: 40,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Income',
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 86, 82, 82),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ValueListenableBuilder<double>(
                                      valueListenable: totalIncome,
                                      builder: (context, value, child) {
                                        return Text(
                                          '${NumberFormat.currency(
                                            locale: 'id_ID',
                                            symbol: 'Rp',
                                            decimalDigits: 0,
                                          ).format(value)}',
                                          style: TextStyle(
                                            color: Color.fromARGB(
                                                255, 36, 161, 105),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(right: 14.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.money_off,
                                      color: Color.fromARGB(255, 227, 119, 119),
                                      size: 40,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Expense',
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 86, 82, 82),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ValueListenableBuilder<double>(
                                      valueListenable: totalExpense,
                                      builder: (context, value, child) {
                                        return Text(
                                          '${NumberFormat.currency(
                                            locale: 'id_ID',
                                            symbol: 'Rp',
                                            decimalDigits: 0,
                                          ).format(value)}',
                                          style: TextStyle(
                                            color: Color.fromARGB(
                                                255, 227, 119, 119),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Text(
                                'Transaction',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 38, 155, 153),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final transaction = transactionsForSelectedDate[index];
                        Color backgroundColor = transaction.category.type == 0
                            ? Color.fromARGB(255, 219, 125, 123)
                            : Colors.green;
                        IconData icon = transaction.category.type == 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 17, vertical: 2),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 12.0),
                              trailing: Container(
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 246, 244, 242),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.all(4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_sweep,
                                        size: 30,
                                        color:
                                            Color.fromARGB(255, 219, 125, 123),
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              title: Row(
                                                children: [
                                                  Icon(Icons.warning,
                                                      color: Colors.red),
                                                  SizedBox(width: 10),
                                                  Text('Confirmation',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete this transaction?',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                        color: Colors.black87),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    await deleteTransaction(
                                                        transaction
                                                            .transaction.id);
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    backgroundColor: Colors.red,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    VerticalDivider(color: Colors.grey),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        size: 30,
                                        color:
                                            Color.fromARGB(255, 109, 178, 239),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TransactionPage(
                                                    transactionWithCategory:
                                                        transaction),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              leading: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              title: Text(
                                'Rp ${transaction.transaction.amount}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Text(
                                '${transaction.category.name} - ${transaction.transaction.name}',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontSize: 16),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: transactionsForSelectedDate.length,
                    ),
                  ),
                ],
              );
            } else {
              return Center(child: Text('No data'));
            }
          },
        ),
      ),
    );
  }
}
