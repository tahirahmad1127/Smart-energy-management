// Keep your imports the same
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class SensorDataScreen extends StatefulWidget {
  const SensorDataScreen({Key? key}) : super(key: key);

  @override
  _SensorDataScreenState createState() => _SensorDataScreenState();
}

class _SensorDataScreenState extends State<SensorDataScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref('sensorData');

  double _voltage = 0.0;
  double _current = 0.0;

  StreamSubscription<DatabaseEvent>? _databaseSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    _databaseSubscription = _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _voltage = double.tryParse(data['voltage'].toString()) ?? 0.0;
          _current = double.tryParse(data['current'].toString()) ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _databaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Voltage & Current Meter',
          style: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [Shadow(blurRadius: 10, color: Colors.amber)],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                const Text(
                  'Realtime Sensor Data',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 12, color: Colors.amber)],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: _buildVoltageGauge()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCurrentGauge()),
                  ],
                ),
                const SizedBox(height: 30),
                _buildDataTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoltageGauge() {
    return _buildGaugeContainer(
      gauge: SfRadialGauge(
        title: _gaugeTitle('Voltage (V)'),
        axes: [
          _gaugeAxis(
            max: 250,
            value: _voltage,
            annotation: '${_voltage.toStringAsFixed(2)} V',
            ranges: [
              _gaugeRange(0, 80, Colors.greenAccent),
              _gaugeRange(80, 180, Colors.orangeAccent),
              _gaugeRange(180, 250, Colors.redAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCurrentGauge() {
    return _buildGaugeContainer(
      gauge: SfRadialGauge(
        title: _gaugeTitle('Current (A)'),
        axes: [
          _gaugeAxis(
            max: 20,
            value: _current,
            annotation: '${_current.toStringAsFixed(2)} A',
            ranges: [
              _gaugeRange(0, 5, Colors.greenAccent),
              _gaugeRange(5, 15, Colors.orangeAccent),
              _gaugeRange(15, 20, Colors.redAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGaugeContainer({required SfRadialGauge gauge}) {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.amberAccent,
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: gauge,
    );
  }

  GaugeTitle _gaugeTitle(String title) {
    return GaugeTitle(
      text: title,
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [Shadow(blurRadius: 8, color: Colors.amber)],
      ),
    );
  }

  RadialAxis _gaugeAxis({
    required double max,
    required double value,
    required String annotation,
    required List<GaugeRange> ranges,
  }) {
    return RadialAxis(
      minimum: 0,
      maximum: max,
      showLabels: false,
      showTicks: false,
      axisLineStyle: const AxisLineStyle(
        thickness: 0.1,
        thicknessUnit: GaugeSizeUnit.factor,
        color: Colors.white24,
      ),
      ranges: ranges,
      pointers: [
        NeedlePointer(
          value: value,
          enableAnimation: true,
          animationDuration: 1000,
          needleColor: Colors.amber,
          knobStyle: const KnobStyle(knobRadius: 0.07, color: Colors.white),
        )
      ],
      annotations: [
        GaugeAnnotation(
          widget: Text(
            annotation,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          angle: 90,
          positionFactor: 0.6,
        )
      ],
    );
  }

  GaugeRange _gaugeRange(double start, double end, Color color) {
    return GaugeRange(startValue: start, endValue: end, color: color);
  }

  Widget _buildDataTable() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.amberAccent,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Current Values',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 6, color: Colors.amber)],
            ),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: Colors.white54, width: 1),
            children: [
              _buildTableRow('Parameter', 'Value', isHeader: true),
              _buildTableRow('Voltage', '${_voltage.toStringAsFixed(2)} V'),
              _buildTableRow('Current', '${_current.toStringAsFixed(2)} A'),
              _buildTableRow('Power', '${(_voltage * _current).toStringAsFixed(2)} W'),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String col1, String col2, {bool isHeader = false}) {
    final textStyle = TextStyle(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? Colors.amberAccent : Colors.white,
      fontSize: 14,
    );

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(col1, style: textStyle, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(col2, style: textStyle, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
