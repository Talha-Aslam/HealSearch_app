import "package:flutter/material.dart";
// Card View Class
import 'package:healsearch_app/product_details.dart';

class CardView extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CardView({
    super.key,
    required this.productList,
  });
  final Map<String, dynamic> productList;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      height: 100,
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.5),
                blurRadius: 5,
                offset: Offset(0, 3))
          ]),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 07.0, left: 20),
            child: CircleAvatar(
              maxRadius: 22,
              minRadius: 22,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage("images/box.png"),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
          ),
          const SizedBox(
            width: 10,
          ),

          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Text(
                    "${productList['Name']}",
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  '${productList["Price"]}',
                  style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.normal,
                      fontSize: 15),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  'In Stock: ${productList["Quantity"]}',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.normal,
                      fontSize: 16),
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${productList["StoreName"]}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Distance pill
                    if (productList["Distance"] != null)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 10,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              productList["Distance"] == "Unknown"
                                  ? "Unknown"
                                  : "${productList["Distance"]} km",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Tap Button with forward icon for Product Description, blue color with

          Expanded(
            flex: 1,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.1,
              child: ButtonTheme(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProductDetails(
                                  product:
                                      productList, // sending Product Document to the Product Details Page for showing all the details
                                )));
                  },
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}












/*Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.15,
      child: Card(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.02,
        ),
        shadowColor: Colors.grey[50],
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        color: Colors.grey[50],
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.01,
              ),
              width: MediaQuery.of(context).size.width * 0.055,
              child: SizedBox(
                child: Text(
                  product['name'],
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w400,
                    fontSize: MediaQuery.of(context).size.width / 100,
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.04,
              ),
              transformAlignment: Alignment.center,
              alignment: Alignment.center,
              child: Text(
                "Id: ${product['id']}",
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  color: Color.fromARGB(255, 74, 135, 249),
                  fontWeight: FontWeight.w100,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.06,
              ),
              transformAlignment: Alignment.center,
              alignment: Alignment.center,
              child: Text(
                'Qty: ' + product['quantity'].toString(),
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: Color.fromARGB(255, 74, 135, 249),
                  fontWeight: FontWeight.w100,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.06,
              ),
              transformAlignment: Alignment.center,
              alignment: Alignment.center,
              child: Text(
                "Rs. ${product['price']}",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: Color.fromARGB(255, 231, 79, 87),
                  fontWeight: FontWeight.w100,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.06,
              ),
              child: Card(
                color: Color.fromARGB(255, 74, 135, 249),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.03,
                  height: MediaQuery.of(context).size.height * 0.03,
                  alignment: Alignment.center,
                  transformAlignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      navigate(context, product["id"]);
                    },
                    child: Text(
                      "Edit",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w100,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.06,
              ),
              child: Card(
                color: Color.fromARGB(255, 255, 125, 125),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.04,
                  height: MediaQuery.of(context).size.height * 0.03,
                  alignment: Alignment.center,
                  transformAlignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      // Delete product
                      var productID = product["id"];
                      // Are you sure?
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Are you sure?"),
                            content: Text("This action cannot be undone."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Delete product
                                  if (await deleteProduct(productID) == true) {
                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Product deleted, "),
                                      ),
                                    );
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const Product()));
                                  }
                                },
                                child: const Text("Delete"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(
                      "Delete",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        color: Colors.white,
                        fontWeight: FontWeight.w100,
                        fontSize: MediaQuery.of(context).size.width / 110,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );*/