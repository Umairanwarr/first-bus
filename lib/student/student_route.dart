import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:first_bus_project/student/menu/student_menu.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:timeline_tile/timeline_tile.dart';

class StudentRoute extends StatefulWidget {
  final String uid;
  UserModel user;
  StudentRoute({super.key, required this.uid, required this.user});

  @override
  State<StudentRoute> createState() => _StudentRouteState();
}

class _StudentRouteState extends State<StudentRoute> {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Marker? pickupMarker;
  Marker? destMarker;
  List<LatLng> allCords = [];
  List<bool> isRemember = [];
  LatLng? pickup, destination;
  Set<Marker> totalMarkers = {};
  Set<Marker> stopMarkers = {};
  BusRouteModel? bus;
  UserModel? driver;
  bool isLoading = true;
  final PanelController _panelController = PanelController();

  @override
  void initState() {
    getData();
    _getCurrentLocation();
    super.initState();
  }

  Future<void> getData() async {
    try {
      DocumentSnapshot busDoc =
          await _firestore.collection('busRoutes').doc(widget.uid).get();
      DocumentSnapshot driverDoc =
          await _firestore.collection('users').doc(widget.uid).get();

      setState(() {
        bus = BusRouteModel.fromFirestore(
            busDoc.data() as Map<String, dynamic>, busDoc.id);
        driver = UserModel.fromFirestore(
            driverDoc.data() as Map<String, dynamic>, driverDoc.id);
        updateData();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateData() {
    allCords.add(bus!.startCords);
    for (var v in bus!.stops) {
      allCords.add(v.stopCords);
      isRemember.add(v.isReached);
    }

    allCords.add(bus!.endCords);
    pickup = bus!.startCords;
    destination = bus!.endCords;
    pickupMarker = Marker(
      markerId: MarkerId("pickupLocation"),
      infoWindow: InfoWindow(
        title: "pickupLocation",
      ),
      position: pickup!,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
    );
    destMarker = Marker(
      markerId: MarkerId("destLocation"),
      infoWindow: InfoWindow(title: "destination"),
      position: destination!,
    );

    for (var stop in bus!.stops) {
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
      CameraUpdate.newLatLngZoom(currentLocation!, 15),
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Comsats Wah routes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                "All station routing on comsats wah",
                style: TextStyle(fontSize: 17),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentMenuScreen(
                      userModel: widget.user,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person),
            ),
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(

            padding: const EdgeInsets.only(top:20.0),
            child: SlidingUpPanel(
                controller: _panelController,
                minHeight: MediaQuery.of(context).size.height * 0.35,
                maxHeight: MediaQuery.of(context).size.height * 0.35,
                panel: Center(
                  child: Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(10),
                        itemCount: bus?.totalStops ?? 0,
                        itemBuilder: (context, index) {
                          return TimelineTile(
                          
                            alignment: TimelineAlign.start,
                            isFirst: index == 0,
                            isLast: bus!.stops.length == index + 1,
                            beforeLineStyle: LineStyle(
                              color: Color.fromARGB(255, 32, 169, 162),
                            ),
                            afterLineStyle: LineStyle(
                              color: Color.fromARGB(255, 32, 169, 162),
                            ),
                            indicatorStyle: IndicatorStyle(
                              
                              width: 25,
                              height: 25,
                              color: Color(0xFF419A95),
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              indicator: Container(
                                alignment: Alignment.center,
                                child: Text((index + 1).toString(),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                decoration: BoxDecoration(
                                  color: Color(0xFF419A95),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            endChild: Container(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  margin: EdgeInsets.all(4),
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bus!.stops[index].stopName,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        bus!.stops[index].time ??
                                            'No time provided',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                ),
                body: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      margin: EdgeInsets.only(bottom: 10),
                      height: MediaQuery.of(context).size.height * 0.55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: GoogleMap(
                          onMapCreated: (GoogleMapController controller) async {
                            setState(() {
                              mapController = controller;
                            });
                            await _getCurrentLocation();
                            mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(pickup!, 11),
                            );
                          },
                          polylines: _createPolylines(),
                          markers: totalMarkers,
                          initialCameraPosition: CameraPosition(
                            target: pickup!,
                            zoom: 14,
                          ),
                        ),
                      ),
                    ),
                    
                  ],
                ),
              ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        child: Icon(Icons.location_searching),
      ),
    );
  }

  Set<Polyline> _createPolylines() {
    Set<Polyline> polylines = {};

    List<LatLng> allCords = [];
    allCords.add(bus!.startCords);
    for (var v in bus!.stops) {
      allCords.add(v.stopCords);
    }
    allCords.add(bus!.endCords);

    polylines.add(
      Polyline(
        polylineId: PolylineId('route'),
        visible: true,
        points: allCords,
        color: Colors.blue,
        width: 4,
      ),
    );

    return polylines;
  }
}
