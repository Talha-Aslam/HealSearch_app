import 'package:flutter/material.dart';
// import 'package:flutter/src/widgets/container.dart';
// import 'package:flutter/src/widgets/framework.dart';
import 'package:toggle_switch/toggle_switch.dart';

class Product extends StatefulWidget {
  const Product({super.key});

  @override
  State<Product> createState() => _ProductState();
}

class _ProductState extends State<Product> {
  double height = 0, width = 0;
  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
        body: Stack(
      children: [
        Column(
          children: [
            Container(
              height: height * .3,
              decoration: const BoxDecoration(
                color: Color(0xff123456),
              ),
              child: const Column(children: [
                Padding(
                  padding: EdgeInsets.only(top: 27),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.arrow_back_ios_new_sharp,
                              size: 25, color: Colors.white)),
                      Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.more_horiz,
                              size: 25, color: Colors.white)),
                    ],
                  ),
                ),
              ]),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xff123456),
              ),
              child: Container(
                  height: height * .7,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50)))),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 200.0, left: 65),
          // ignore: avoid_unnecessary_containers
          child: Container(
            child: ToggleSwitch(
              minWidth: 110.0,
              cornerRadius: 20.0,
              activeBgColors: [
                [Colors.green[800]!],
                [Colors.red[800]!]
              ],
              activeFgColor: Colors.white,
              inactiveBgColor: Colors.grey,
              inactiveFgColor: Colors.white,
              initialLabelIndex: 1,
              totalSwitches: 2,
              labels: const ['Description', 'Maps'],
              radiusStyle: true,
              onToggle: (index) {
                // ignore: avoid_print
                print('switched to: $index');
              },
            ),
          ),
        ),
      ],
    ));
  }
}
