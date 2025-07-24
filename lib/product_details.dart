import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetails({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
// Getting Product from Statefull Widget
  double height = 0, width = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    final product = widget.product;
    double lat = product["StoreLocation"].latitude;
    double lon = product["StoreLocation"].longitude;
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text("Product Details"),
    //   ),
    //   body: Container(
    //     child: Column(
    //       children: [
    //         Text("Category: ${widget.product["Category"]}}"),
    //         Text("ExpireDate: ${widget.product["ExpireDate"]}} "),
    //         Text("Name: ${widget.product["Name"]}}"),
    //         Text("Price: ${widget.product["Price"]}}"),
    //         Text("ProductId: ${widget.product["ProductId"]}}"),
    //         Text("Quantity: ${widget.product["Quantity"]}}"),
    //         Text("StoreId: ${widget.product["StoreId"]}}"),
    //         Text("StoreLocation: ${widget.product["StoreLocation"]}}"),
    //         Text("StoreName: ${widget.product["StoreName"]}}"),
    //         Text("Type: ${widget.product["Type"]}}"),
    //         ElevatedButton(
    //             onPressed: () {
    //               // Open Google Maps
    //             },
    //             child: ElevatedButton(
    //               onPressed: () {
    //                 // String url = "https://www.google.com/maps/@$lat,${lon},10z";
    //                 Uri uri = Uri(
    //                     scheme: 'https',
    //                     host: 'www.google.com',
    //                     path: '/maps',
    //                     queryParameters: {'q': '$lat,$lon'});
    //                 launchUrl(uri);
    //               },
    //               child: Text("Open Google Maps"),
    //             )),
    //       ],
    //     ),
    //   ),
    // );

    return Scaffold(
        body: Stack(
      children: [
        Column(
          children: [
            Container(
              height: height * .3,
              decoration: const BoxDecoration(
                color: Colors.blue,
                image: DecorationImage(
                  image: AssetImage('images/plants2.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.only(top: 27),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Icon(Icons.arrow_back_ios_new_sharp,
                                size: 25, color: Colors.white)),
                      ),
                      const Padding(
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
                color: Colors.blue,
              ),
              child: Container(
                  height: height * .7,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40)))),
            ),
          ],
        ),
        const SizedBox(
          width: 240,
          child: Padding(
            padding: EdgeInsets.only(top: 240.0, left: 140),
            child: Divider(
              thickness: 5.0,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 270, left: 130.0),
          child: Text(
            '${widget.product["StoreName"]}',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 32),
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / 1.05,
          child: const Padding(
            padding: EdgeInsets.only(top: 310.0, left: 20),
            child: Divider(
              thickness: 2.0,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 340, left: 62.0),
          child: Text(
            '${widget.product["Name"]}',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 25),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 375, left: 62.0),
          child: Text(
            '${widget.product["Category"]}',
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.normal,
                fontSize: 22),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 340, left: 268.0),
          child: Text(
            '${widget.product["Price"]}',
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold, fontSize: 25),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 375, left: 260.0),
          child: Text(
            '(Per Unit)',
            style: TextStyle(
                color: Colors.red, fontWeight: FontWeight.normal, fontSize: 22),
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / 1.05,
          child: const Padding(
            padding: EdgeInsets.only(top: 415.0, left: 20),
            child: Divider(
              thickness: 2.0,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 445, left: 62.0),
          child: Text(
            'In Stock',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 25),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 445, left: 280.0),
          child: Text(
            '${widget.product["Quantity"]}',
            style: const TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold, fontSize: 25),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 495, left: 62.0),
          child: Text(
            'Expire Date',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 25),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 495, left: 260.0),
          child: Text(
            '${widget.product["Expire"]}',
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.normal, fontSize: 25),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 560, left: 50.0),
          child: Text(
            "Note",
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 585, left: 28.0),
          child: Text(
            "Do not use medicine without doctor's prescription.",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.normal,
                fontSize: 18),
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / 1.05,
          child: const Padding(
            padding: EdgeInsets.only(top: 540.0, left: 20),
            child: Divider(
              thickness: 2.0,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 272.0, left: 93),
          child: Icon(
            Icons.storefront,
            color: Colors.black,
            size: 35.0,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 442.0, left: 28),
          child: Icon(
            Icons.production_quantity_limits,
            color: Colors.black,
            size: 30.0,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 492.0, left: 28),
          child: Icon(
            Icons.date_range,
            color: Colors.black,
            size: 30.0,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 338.0, left: 28),
          child: Icon(
            Icons.medical_services_outlined,
            color: Colors.black,
            size: 30.0,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 560.0, left: 28),
          child: Icon(
            Icons.note_add,
            color: Colors.red,
            size: 20.0,
          ),
        ),
        // Show distance information
        Padding(
          padding: const EdgeInsets.only(top: 625, left: 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 24.0,
              ),
              SizedBox(width: 8),
              Text(
                product["Distance"] == "Unknown"
                    ? "Distance: Unknown"
                    : "Distance: ${product["Distance"]} km",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),

        // Navigation button
        Padding(
          padding: const EdgeInsets.only(top: 660, left: 125.0),
          child: FloatingActionButton.extended(
            icon: const Icon(Icons.navigation),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: const Text("See on Maps"),
            onPressed: () {
              Uri uri = Uri(
                  scheme: 'https',
                  host: 'www.google.com',
                  path: '/maps',
                  queryParameters: {'q': '$lat,$lon'});
              launchUrl(uri);
            },
          ),
        ),
      ],
    ));
  }
}
