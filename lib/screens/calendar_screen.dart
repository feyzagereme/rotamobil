import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/mock_data_service.dart';
import '../models/address_model.dart' as address_models;
import '../theme/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentWeekStart;
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedDayIndex = 0;
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = <DateTime>[];
    for (int i = 0; i < 7; i++) {
      weekDays.add(_currentWeekStart.add(Duration(days: i)));
    }

    final selectedDay = weekDays[_selectedDayIndex];
    final todayRoute = MockDataService.getTodayRoute();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Haftalık Takvim',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Week navigation header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousWeek,
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.primary,
                ),
                Text(
                  '${DateFormat('d MMM', 'tr_TR').format(weekDays.first)} - ${DateFormat('d MMM yyyy', 'tr_TR').format(weekDays.last)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  onPressed: _nextWeek,
                  icon: const Icon(Icons.chevron_right),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          // Weekly day tabs
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = weekDays[index];
                final isSelected = _selectedDayIndex == index;
                final isToday = _isToday(day);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                    });
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryDark : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryDark
                            : (isToday ? AppColors.primary : AppColors.border),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E', 'tr_TR').format(day).substring(0, 3),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected ? Colors.white : AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM', 'tr_TR').format(day),
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isSelected ? Colors.white : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Route details for selected day
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected day info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE', 'tr_TR').format(selectedDay),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('d MMMM yyyy', 'tr_TR')
                                    .format(selectedDay),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          if (_isSameDay(selectedDay, DateTime.now()))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Bugün',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Route summary for selected day
                    Text(
                      'Rota Özeti',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            '📍',
                            todayRoute.totalStops.toString(),
                            'Adres',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            '📏',
                            todayRoute.totalDistance.toStringAsFixed(1),
                            'km',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            '⏱️',
                            '2.5',
                            'saat',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Timeline sections
                    _buildTimelineSection(
                      'SABAH',
                      todayRoute.addresses.take(2).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineSection(
                      'EVE DÖNÜŞ',
                      todayRoute.addresses.skip(2).take(2).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineSection(
                      'ÖĞLEDEN SONRA',
                      todayRoute.addresses.skip(4).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(
    String sectionTitle,
    List<address_models.Address> addresses,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (addresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Bu bölümde rota yok',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          )
        else
          Column(
            children: addresses.asMap().entries.map((entry) {
              final idx = entry.key;
              final address = entry.value;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              address.orderNumber.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address.customerName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${address.street}, ${address.district}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (idx < addresses.length - 1) const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
