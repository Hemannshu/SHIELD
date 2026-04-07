import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PeriodTrackerPage extends StatefulWidget {
  @override
  _PeriodTrackerPageState createState() => _PeriodTrackerPageState();
}

class _PeriodTrackerPageState extends State<PeriodTrackerPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  DateTime? _periodStartDate;
  DateTime? _periodEndDate;
  int _cycleLength = 28;
  int _periodLength = 5;
  
  List<DateTime> _periodDays = [];
  List<DateTime> _fertileDays = [];
  DateTime? _ovulationDay;
  
  List<Map<String, dynamic>> _periodHistory = [];
  bool _isLoading = true;

  // Symptoms tracking
  Map<DateTime, List<String>> _symptoms = {};
  final TextEditingController _symptomController = TextEditingController();
  String _selectedSymptom = 'Cramps';
  final List<String> _symptomOptions = [
    'Cramps',
    'Headache',
    'Bloating',
    'Fatigue',
    'Mood swings',
    'Acne',
    'Breast tenderness'
  ];

  // Myths and facts
  final List<Map<String, String>> _mythsFacts = [
    {
      'myth': 'You can\'t get pregnant during your period',
      'fact': 'While less likely, pregnancy is still possible during period'
    },
    {
      'myth': 'Period blood is dirty blood',
      'fact': 'Period blood is just like regular blood with uterine tissue'
    },
    {
      'myth': 'You shouldn\'t exercise during your period',
      'fact': 'Exercise can actually help reduce cramps and improve mood'
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadPeriodData();
  }

  Future<void> _loadPeriodData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('periodData').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _cycleLength = doc.data()?['cycleLength'] ?? 28;
          _periodLength = doc.data()?['periodLength'] ?? 5;
          _periodHistory = List<Map<String, dynamic>>.from(doc.data()?['history'] ?? []);
          
          // Load symptoms
          if (doc.data()?['symptoms'] != null) {
            final symptomsData = doc.data()?['symptoms'] as Map<String, dynamic>;
            _symptoms = symptomsData.map((key, value) => 
              MapEntry(DateTime.parse(key), List<String>.from(value)));
          }
          
          // Get the most recent period
          if (_periodHistory.isNotEmpty) {
            final lastPeriod = _periodHistory.last;
            _periodStartDate = (lastPeriod['startDate'] as Timestamp).toDate();
            if (lastPeriod['endDate'] != null) {
              _periodEndDate = (lastPeriod['endDate'] as Timestamp).toDate();
            }
            _calculatePeriodDays();
          }
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading period data: ${e.toString()}')),
      );
    }
  }

  Future<void> _savePeriodData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Convert symptoms to serializable format
      final serializedSymptoms = _symptoms.map((key, value) => 
        MapEntry(key.toIso8601String(), value));
      
      await _firestore.collection('periodData').doc(user.uid).set({
        'cycleLength': _cycleLength,
        'periodLength': _periodLength,
        'history': _periodHistory.map((period) => {
          'startDate': period['startDate'],
          'endDate': period['endDate'],
          'recordedAt': Timestamp.now(),
        }).toList(),
        'symptoms': serializedSymptoms,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: ${e.toString()}')),
      );
    }
  }

  void _calculatePeriodDays() {
    _periodDays = [];
    _fertileDays = [];
    _ovulationDay = null;

    if (_periodStartDate != null) {
      // Calculate period days
      if (_periodEndDate != null) {
        DateTime current = _periodStartDate!;
        while (current.isBefore(_periodEndDate!) || current.isAtSameMomentAs(_periodEndDate!)) {
          _periodDays.add(current);
          current = current.add(Duration(days: 1));
        }
      }

      // Calculate fertile window and ovulation
      DateTime nextPeriodStart = _periodStartDate!.add(Duration(days: _cycleLength));
      _ovulationDay = nextPeriodStart.subtract(Duration(days: 14));
      
      DateTime fertileStart = _ovulationDay!.subtract(Duration(days: 3));
      DateTime fertileEnd = _ovulationDay!.add(Duration(days: 2));
      
      DateTime current = fertileStart;
      while (current.isBefore(fertileEnd) || current.isAtSameMomentAs(fertileEnd)) {
        _fertileDays.add(current);
        current = current.add(Duration(days: 1));
      }
    }
  }

  Future<void> _startPeriod() async {
    if (_selectedDay == null) return;
    
    setState(() {
      _periodStartDate = _selectedDay;
      _periodEndDate = null;
      _calculatePeriodDays();
      
      // Add to history
      _periodHistory.add({
        'startDate': Timestamp.fromDate(_periodStartDate!),
        'endDate': null,
        'recordedAt': Timestamp.now(),
      });
    });
    
    await _savePeriodData();
  }

  Future<void> _endPeriod() async {
    if (_periodStartDate == null || _selectedDay == null) return;
    if (_selectedDay!.isBefore(_periodStartDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('End date cannot be before start date')),
      );
      return;
    }
    
    setState(() {
      _periodEndDate = _selectedDay;
      _calculatePeriodDays();
      
      // Update the last history entry
      if (_periodHistory.isNotEmpty) {
        _periodHistory.last['endDate'] = Timestamp.fromDate(_periodEndDate!);
        _periodHistory.last['recordedAt'] = Timestamp.now();
      } else {
        _periodHistory.add({
          'startDate': Timestamp.fromDate(_periodStartDate!),
          'endDate': Timestamp.fromDate(_periodEndDate!),
          'recordedAt': Timestamp.now(),
        });
      }
    });
    
    await _savePeriodData();
  }

  Future<void> _addSymptom() async {
    if (_selectedDay == null || _selectedSymptom.isEmpty) return;
    
    setState(() {
      _symptoms.putIfAbsent(
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day),
        () => [],
      ).add(_selectedSymptom);
    });
    
    await _savePeriodData();
    _symptomController.clear();
  }

  Future<void> _removeSymptom(DateTime date, String symptom) async {
    setState(() {
      _symptoms[date]?.remove(symptom);
      if (_symptoms[date]?.isEmpty ?? false) {
        _symptoms.remove(date);
      }
    });
    
    await _savePeriodData();
  }

  Widget _buildCalendarDay(DateTime day, DateTime focusedDay) {
    final isPeriodDay = _periodDays.any((d) => isSameDay(d, day));
    final isFertileDay = _fertileDays.any((d) => isSameDay(d, day));
    final isOvulationDay = _ovulationDay != null && isSameDay(_ovulationDay!, day);
    final isToday = isSameDay(day, DateTime.now());
    final isSelected = isSameDay(day, _selectedDay);

    BoxDecoration? decoration;
    Color textColor = Colors.black;
    FontWeight fontWeight = FontWeight.normal;

    if (isPeriodDay) {
      decoration = BoxDecoration(
        color: Colors.pink[100],
        shape: BoxShape.circle,
      );
      textColor = Colors.pink;
      fontWeight = FontWeight.bold;
    } else if (isSelected) {
      decoration = BoxDecoration(
        color: Color(0xFFEC407A),
        shape: BoxShape.circle,
      );
      textColor = Colors.white;
    } else if (isToday) {
      decoration = BoxDecoration(
        color: Colors.pink[50],
        shape: BoxShape.circle,
      );
    }

    List<Widget> markers = [];
    if (isPeriodDay) {
      markers.add(Positioned(
        bottom: 2,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.pink[400],
            shape: BoxShape.circle,
          ),
        ),
      ));
    }
    if (isFertileDay || isOvulationDay) {
      markers.add(Positioned(
        bottom: 2,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.blue[400],
            shape: BoxShape.circle,
          ),
        ),
      ));
    }

    return Container(
      margin: EdgeInsets.all(4),
      decoration: decoration,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: fontWeight,
              fontSize: 16,
            ),
          ),
          if (markers.isNotEmpty)
            Positioned(
              bottom: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: markers,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC407A)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Period Tracker', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFEC407A),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Calendar Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    return _buildCalendarDay(day, focusedDay);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return _buildCalendarDay(day, focusedDay);
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return _buildCalendarDay(day, focusedDay);
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Color(0xFFEC407A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFFEC407A)),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFFEC407A)),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.grey[600]),
                  weekendStyle: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      iconColor: Color(0xFFEC407A),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _startPeriod,
                    child: Text('Start Period', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      iconColor: _periodStartDate != null && _periodEndDate == null
                          ? Color.fromARGB(255, 236, 64, 122)
                          : const Color.fromARGB(255, 253, 61, 189),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: (_periodStartDate != null && _periodEndDate == null)
                        ? _endPeriod
                        : null,
                    child: Text('End Period', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Current Period Info
                  _buildInfoCard(
                    title: 'Current Cycle',
                    icon: Icons.calendar_today,
                    child: _periodStartDate == null
                        ? Text('No active period', style: TextStyle(color: Colors.grey))
                        : Column(
                            children: [
                              _buildInfoRow(
                                Icons.circle,
                                Colors.red,
                                'Start Date',
                                DateFormat('MMM dd, yyyy').format(_periodStartDate!),
                              ),
                              if (_periodEndDate != null)
                                _buildInfoRow(
                                  Icons.circle,
                                  Colors.green,
                                  'End Date',
                                  DateFormat('MMM dd, yyyy').format(_periodEndDate!),
                                ),
                              if (_periodEndDate != null) Divider(height: 24),
                              if (_periodEndDate != null)
                                _buildInfoRow(
                                  Icons.event,
                                  Colors.blue,
                                  'Next Period',
                                  DateFormat('MMM dd, yyyy').format(
                                    _periodStartDate!.add(Duration(days: _cycleLength)),
                                  ),
                                ),
                              if (_ovulationDay != null)
                                _buildInfoRow(
                                  Icons.egg,
                                  Colors.purple,
                                  'Ovulation',
                                  DateFormat('MMM dd, yyyy').format(_ovulationDay!),
                                ),
                            ],
                          ),
                  ),
                  SizedBox(height: 16),
                  // Symptoms Tracker
                  _buildInfoCard(
                    title: 'Symptoms',
                    icon: Icons.medical_services,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedSymptom,
                                items: _symptomOptions
                                    .map((symptom) => DropdownMenuItem<String>(
                                          value: symptom,
                                          child: Text(symptom),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedSymptom = value!);
                                },
                                decoration: InputDecoration(
                                  labelText: 'Select Symptom',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Color(0xFFEC407A), size: 36),
                              onPressed: _addSymptom,
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (_selectedDay != null &&
                            _symptoms.containsKey(DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)))
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _symptoms[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]!
                                .map((symptom) => Chip(
                                      label: Text(symptom),
                                      backgroundColor: Colors.pink[50],
                                      deleteIcon: Icon(Icons.close, size: 16),
                                      onDeleted: () => _removeSymptom(
                                          DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day),
                                          symptom),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Myths and Facts
                  _buildInfoCard(
                    title: 'Myths vs Facts',
                    icon: Icons.lightbulb_outline,
                    child: Column(
                      children: _mythsFacts.map((item) => Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Myth: ${item['myth']}',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Fact: ${item['fact']}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ),
                          Divider(height: 16),
                        ],
                      )).toList(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Period History
                  _buildInfoCard(
                    title: 'History',
                    icon: Icons.history,
                    child: _periodHistory.isEmpty
                        ? Text('No period history available', style: TextStyle(color: Colors.grey))
                        : Column(
                            children: _periodHistory.reversed.map((period) {
                              final startDate = (period['startDate'] as Timestamp).toDate();
                              final endDate = period['endDate'] != null 
                                  ? (period['endDate'] as Timestamp).toDate() 
                                  : null;
                              
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.circle, color: Colors.pink[300], size: 12),
                                title: Text(
                                  '${DateFormat('MMM yyyy').format(startDate)}',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  endDate != null
                                      ? '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)} (${endDate.difference(startDate).inDays + 1} days)'
                                      : 'Started on ${DateFormat('MMM dd').format(startDate)}',
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  SizedBox(height: 16),
                  // Settings
                  _buildInfoCard(
                    title: 'Settings',
                    icon: Icons.settings,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Cycle Length'),
                          trailing: DropdownButton<int>(
                            value: _cycleLength,
                            items: List.generate(45 - 21 + 1, (index) => 21 + index)
                                .map((length) => DropdownMenuItem<int>(
                                      value: length,
                                      child: Text('$length days'),
                                    ))
                                .toList(),
                            onChanged: (value) async {
                              setState(() {
                                _cycleLength = value!;
                                _calculatePeriodDays();
                              });
                              await _savePeriodData();
                            },
                          ),
                        ),
                        Divider(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Period Length'),
                          trailing: DropdownButton<int>(
                            value: _periodLength,
                            items: List.generate(14 - 1 + 1, (index) => 1 + index)
                                .map((length) => DropdownMenuItem<int>(
                                      value: length,
                                      child: Text('$length days'),
                                    ))
                                .toList(),
                            onChanged: (value) async {
                              setState(() => _periodLength = value!);
                              await _savePeriodData();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFFEC407A)),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}