import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:first_bus_project/driver/menu/driver_menu.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class DriverMapScreen extends StatefulWidget {
  final UserModel userModel;
  final BusRouteModel? busRouteModel;

  DriverMapScreen({
    Key? key,
    required this.userModel,
    required this.busRouteModel,
  }) : super(key: key);

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  Marker? pickupMarker;
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Marker? destMarker;
  List<LatLng> allCords = [];
  List<bool> isRemember = [];
  LatLng? pickup, destination;
  Set<Marker> totalMarkers = {};
  Set<Marker> stopMarkers = {};
  BusRouteModel? bus;
  bool isOnline = false;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    bus = widget.busRouteModel;
    allCords.add(widget.busRouteModel!.startCords);
    for (var v in widget.busRouteModel!.stops) {
      allCords.add(v.stopCords);
      isRemember.add(v.isReached);
    }

    allCords.add(widget.busRouteModel!.endCords);
    pickup = widget.busRouteModel!.startCords;
    destination = widget.busRouteModel!.endCords;
    pickupMarker = Marker(
        markerId: MarkerId("pickupLocation"),
        infoWindow: InfoWindow(
          title: "pickupLocation",
        ),
        position: pickup!);
    destMarker = Marker(
        markerId: MarkerId("destLocation"),
        infoWindow: InfoWindow(title: "destination"),
        position: destination!);

    for (var stop in widget.busRouteModel!.stops) {
      setMarker(
        stop.stopCords,
        stop.stopName,
        stop.time,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }
    totalMarkers.add(destMarker!);
    totalMarkers.addAll(stopMarkers);
    totalMarkers.add(pickupMarker!);
    _getCurrentLocation();
    _checkOnlineStatus();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkOnlineStatus() async {
    final doc = await _firestore
        .collection('driverLocations')
        .doc(auth.currentUser!.uid)
        .get();
    if (doc.exists) {
      setState(() {
        isOnline = doc.data()?['isOnline'] ?? false;
      });
      if (isOnline) {
        _startLocationUpdates();
      }
    }
  }

  void _toggleOnlineStatus() async {
    setState(() {
      isOnline = !isOnline;
    });

    if (isOnline) {
      _startLocationUpdates();
    } else {
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      // Update driver status in Firestore
      await _firestore
          .collection('driverLocations')
          .doc(auth.currentUser!.uid)
          .update({
        'isOnline': false,
      });
    }
  }

  void _startLocationUpdates() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        currentLocation = location;
      });

      // Update location in Firestore
      await _firestore
          .collection('driverLocations')
          .doc(auth.currentUser!.uid)
          .set({
        'location': GeoPoint(position.latitude, position.longitude),
        'lastUpdated': FieldValue.serverTimestamp(),
        'driverId': auth.currentUser!.uid,
        'busNumber': widget.userModel.busNumber,
        'busColor': widget.userModel.busColor,
        'isOnline': true,
      });
    });
  }

  final RoutesService _routesService = RoutesService();

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _onFabPressed() async {
    await _getCurrentLocation();
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation!, 13),
    );
  }

  void setMarker(
      LatLng point, String name, String? time, BitmapDescriptor icon) {
    final MarkerId markerId = MarkerId(name);

    // Convert stopMarkers Set to a List to find existing markers
    List<Marker> markersList = stopMarkers.toList();

    // Check if the marker with the given name already exists
    int existingIndex =
        markersList.indexWhere((marker) => marker.markerId.value == name);

    setState(() {
      if (existingIndex != -1) {
        // Update existing marker if found
        markersList[existingIndex] = Marker(
          markerId: MarkerId(name),
          position: point,
          infoWindow: (time != null)
              ? InfoWindow(title: name + time)
              : InfoWindow(title: name),
          draggable: true,
          icon: icon,
        );

        // Convert back to Set after modification
        stopMarkers = markersList.toSet();
      } else {
        // Add new marker if not found
        stopMarkers.add(
          Marker(
            markerId: MarkerId(name),
            position: point,
            infoWindow: (time != null)
                ? InfoWindow(title: name + time)
                : InfoWindow(title: name),
            draggable: true,
            icon: icon,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Driver Map'),
        actions: [
          // Online status button
          TextButton.icon(
            onPressed: _toggleOnlineStatus,
            icon: Icon(
              isOnline ? Icons.location_on : Icons.location_off,
              color: isOnline ? Colors.green : Colors.red,
            ),
            label: Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.red,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverMenuScreen(
                    userId: auth.currentUser!.uid,
                    busRouteModel: bus,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person),
          )
        ],
      ),
      body: SlidingUpPanel(
        maxHeight: MediaQuery.of(context).size.height * 0.38,
        minHeight: MediaQuery.of(context).size.height * 0.38,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        panel: Column(
          children: [
            SizedBox(
                width: 70,
                child: Divider(thickness: 5, color: Colors.grey[400])),
            (bus?.driverId != null && bus!.driverId.isNotEmpty)
                ? Expanded(
                    child: Container(
                      // decoration: BoxDecoration(border: Border.all()),
                      padding: EdgeInsets.all(8),
                      child: ListView.builder(
                        padding: EdgeInsets.all(10),
                        itemCount: widget.busRouteModel!.totalStops,
                        itemBuilder: (context, index) {
                          return TimelineTile(
                            alignment: TimelineAlign.start,
                            isFirst: index == 0,
                            isLast: bus!.stops.length == index + 1,
                            indicatorStyle: IndicatorStyle(
                              width: 20,
                              color: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              indicator: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            endChild: GestureDetector(
                              onTap: () => toggleReached(index),
                              child: Container(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    margin: EdgeInsets.all(4),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isRemember[index]
                                          ? Colors.green
                                          : Colors.white,
                                      border: Border.all(),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 200,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                bus!.stops[index].stopName,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: isRemember[index]
                                                      ? const Color.fromRGBO(
                                                          255, 255, 255, 1)
                                                      : Colors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                bus!.stops[index].time,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: isRemember[index]
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            beforeLineStyle: LineStyle(
                              color: isRemember[index]
                                  ? Colors.teal
                                  : Colors.teal.shade200,
                              thickness: 6,
                            ),
                          );
                        },
                      ),
                    ),
                  )
                : Container(),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        "Are you sure",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      content: Text("You want to delete this route? - "),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('busRoutes')
                                  .doc(bus!.driverId)
                                  .delete();
                              setState(() {
                                bus = BusRouteModel.empty();
                                totalMarkers.clear();
                                allCords.clear();
                              });
                            } catch (e) {
                              print("error ------- $e");
                            }

                            Navigator.of(context).pop();
                          },
                          child: Text("OK"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Cancel"),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                    color: Color(0Xff419A95),
                    borderRadius: BorderRadius.circular(5)),
                child: Text(
                  "Delete Routes",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              // padding: EdgeInsets.symmetric(horizontal: 10),
              margin: EdgeInsets.only(bottom: 10),
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    setState(() {
                      mapController = controller;
                      controller.setMapStyle('''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#E8F3F1"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#2D6660"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#B5D8D3"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#489c94"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#D4E9E6"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#C2E6E1"
      }
    ]
  },
  {
    "featureType": "poi.business",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#D4E9E6"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#357871"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#F8F9F9"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#F8F9F9"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#357871"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#489c94"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#D4E9E6"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#D4E9E6"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#90CAF9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#64B5F6"
      }
    ]
  }
]
                      ''');
                    });
                    if (currentLocation != null) {
                      mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(currentLocation!, 11));
                    }
                  },
                  polylines: _createPolylines(),
                  markers: totalMarkers,
                  initialCameraPosition: CameraPosition(
                    target: currentLocation ?? LatLng(33.7445, 72.7867),
                    zoom: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _onFabPressed, child: Icon(Icons.room)),
    );
  }

// -----------------with PolyLines ----------------------------------------------

  Set<Polyline> _createPolylines() {
    Set<Polyline> polylines = {};

    List<LatLng> allPoints = [];
    allPoints.addAll(allCords);

    if (allPoints.length > 1) {
      List<LatLng> polylinePoints = [];
      for (int i = 0; i < allPoints.length; i++) {
        polylinePoints.add(allPoints[i]);
      }

      polylines.add(Polyline(
        polylineId: PolylineId('route'),
        color: Colors.blue,
        width: 5,
        points: polylinePoints,
      ));
    }

    return polylines;
  }

  toggleReached(int index) {
    // Show a dialog when the state changes to 'reached'
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Are you sure",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
              "you have reached Stop - ${widget.busRouteModel!.stops[index].stopName}"),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  update(index);

                  isRemember[index] = !isRemember[index];
                });
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  update(index) async {
    LatLng v = bus!.stops[index].stopCords;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final querySnapshot = await _firestore
        .collection('busRoutes')
        .doc(_firebaseAuth.currentUser!.uid)
        .update({
      'stops.$index': {
        'stopCords': {'latitude': v.latitude, 'longitude': v.longitude},
        'isReached': false,
        'stopLocation': bus!.stops[index].stopLocation,
        'stopName': bus!.stops[index].stopName,
        'time': bus!.stops[index].time,
      },
    });
  }
}
