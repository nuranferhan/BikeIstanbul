import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/repositories/bike_repository.dart';
import 'data/repositories/trip_repository.dart';
import 'presentation/screens/bike_map_screen.dart';
import 'presentation/viewmodels/bike_map_viewmodel.dart';

void main() {
  runApp(const BikeIstanbulApp());
}

class BikeIstanbulApp extends StatelessWidget {
  const BikeIstanbulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BikeMapViewModel(
            bikeRepository: BikeRepository(),
            tripRepository: TripRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'BikeIstanbul',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF22C55E),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const BikeMapScreen(),
      ),
    );
  }
}
