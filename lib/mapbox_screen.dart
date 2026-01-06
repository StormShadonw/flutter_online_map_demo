import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_online_map_demo/helpers/location_helper.dart';
import 'package:flutter_online_map_demo/helpers/shared_preferences_helper.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geotypes/geotypes.dart' as geoTypes;
import 'package:uuid/uuid.dart';

class MapboxScreen extends StatefulWidget {
  @override
  State<MapboxScreen> createState() => _MapboxScreenState();
}

class _MapboxScreenState extends State<MapboxScreen> {
  MapboxMap? mapboxMap;
  geoTypes.Position? centerPosition;
  bool _isLoading = false;
  double longitude = 0.381457;
  double latitude = 6.687337;
  geolocator.LocationSettings? locationSettings;
  StreamSubscription<geolocator.Position>? positionStream;
  StreamSubscription<QuerySnapshot>?
  firestoreSubscription; // Para limpiar el stream de Firebase

  static const String userIdSharedPreferencesKey = "userId";
  static const String userAvatarSharedPreferencesKey = "userAvatar";

  CircleAnnotationManager? circleAnnotationManager;
  List<CircleAnnotation> annotations = [];

  // 1. Corregimos addMarkers para que sea un listener activo
  Future<void> setupMarkersListener() async {
    // Creamos el manager una sola vez
    circleAnnotationManager = await mapboxMap?.annotations
        .createCircleAnnotationManager();

    // Obtenemos el ID del usuario actual una vez para no pedirlo en cada vuelta del loop
    final String currentUserId = await SharedPreferencesHelper.getValue(
      userIdSharedPreferencesKey,
    );

    // Escuchamos los cambios en Firestore
    firestoreSubscription = FirebaseFirestore.instance
        .collection('usersLocations')
        .snapshots()
        .listen((snapshot) async {
          // Limpiamos marcadores previos antes de redibujar (evita duplicados)
          await circleAnnotationManager?.deleteAll();
          List<CircleAnnotationOptions> optionsList = [];

          // Agregamos marcador del usuario actual (Azul)
          optionsList.add(
            CircleAnnotationOptions(
              geometry: Point(coordinates: Position(longitude, latitude)),
              circleColor: Colors.blueAccent.value,
              circleRadius: 8.0,
              circleStrokeWidth: 2,
              circleStrokeColor: Colors.white.value,
            ),
          );

          // Agregamos marcadores de otros usuarios (Naranja)
          for (var doc in snapshot.docs) {
            if (doc.id != currentUserId) {
              double _lat = doc.data()["latitude"];
              double _lng = doc.data()["longitude"];

              optionsList.add(
                CircleAnnotationOptions(
                  geometry: Point(coordinates: Position(_lng, _lat)),
                  circleColor: Colors.orangeAccent.value,
                  circleRadius: 6.0,
                  circleStrokeWidth: 2,
                  circleStrokeColor: Colors.white.value,
                ),
              );
            }
          }

          // 2. IMPORTANTE: createMulti debe ir DENTRO del listener
          if (optionsList.isNotEmpty) {
            circleAnnotationManager?.createMulti(optionsList).then((created) {
              annotations = created.whereType<CircleAnnotation>().toList();
            });
          }
        });
  }

  _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    setupMarkersListener(); // Cambiado a la nueva función
  }

  // --- Mantenemos tus funciones de lógica de ubicación ---

  void startListeningGeolocationChanges() {
    positionStream =
        geolocator.Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((geolocator.Position position) {
          if (mounted) {
            setState(() {
              longitude = position.longitude;
              latitude = position.latitude;
            });
            uploadUserLocation(position.latitude, position.longitude);
          }
        });
  }

  Future<void> getDeviceLocation() async {
    geolocator.Position userPosition = await LocationHelper.getDevicePosition();
    if (mounted) {
      setState(() {
        centerPosition = geoTypes.Position(
          userPosition.longitude,
          userPosition.latitude,
        );
      });
    }
    await uploadUserLocation(userPosition.latitude, userPosition.longitude);
  }

  Future<void> uploadUserLocation(double lat, double lng) async {
    var docId = await SharedPreferencesHelper.getValue(
      userIdSharedPreferencesKey,
    );
    var userAvatar = await SharedPreferencesHelper.getValue(
      userAvatarSharedPreferencesKey,
    );

    await FirebaseFirestore.instance
        .collection('usersLocations')
        .doc(docId)
        .set({
          'latitude': lat,
          'longitude': lng,
          'userAvatar': userAvatar,
        }, SetOptions(merge: true));
  }

  Future<void> getInitData() async {
    setState(() => _isLoading = true);

    var userId = await SharedPreferencesHelper.getValue(
      userIdSharedPreferencesKey,
    );
    if (userId.isEmpty) {
      await SharedPreferencesHelper.setValue(
        userIdSharedPreferencesKey,
        Uuid().v4(),
      );
    }

    var userAvatar = await SharedPreferencesHelper.getValue(
      userAvatarSharedPreferencesKey,
    );
    if (userAvatar.isEmpty) {
      await SharedPreferencesHelper.setValue(
        userAvatarSharedPreferencesKey,
        generate2CharactersStringValue(),
      );
    }

    await getDeviceLocation();
    startListeningGeolocationChanges();

    if (mounted) setState(() => _isLoading = false);
  }

  String generate2CharactersStringValue() {
    const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    return '${letras[random.nextInt(letras.length)]}${letras[random.nextInt(letras.length)]}';
  }

  void _centerCamera() {
    if (mapboxMap != null) {
      mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(longitude, latitude)),
          zoom: 15.0,
          bearing: 0,
          pitch: 0,
        ),
        MapAnimationOptions(duration: 1000), // Animación de 1 segundo
      );
    }
  }

  @override
  void initState() {
    super.initState();
    locationSettings = const geolocator.LocationSettings(
      accuracy: geolocator.LocationAccuracy.high,
      distanceFilter: 2,
    );
    getInitData();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    firestoreSubscription?.cancel(); // Limpieza del stream de Firestore
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MapBox Online Demo")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blueAccent),
        onPressed: _centerCamera, // Llamamos a la función de centrado
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : MapWidget(
              key: const ValueKey("mapWidget"),
              onMapCreated: _onMapCreated,
              cameraOptions: CameraOptions(
                center: Point(
                  coordinates: centerPosition ?? Position(-69.9312, 18.4861),
                ),
                zoom: 14.0,
              ),
              styleUri: MapboxStyles.MAPBOX_STREETS,
            ),
    );
  }
}
