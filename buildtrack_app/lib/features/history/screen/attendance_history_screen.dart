// features/history/screens/attendance_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/attendance_model.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceService = Provider.of<AttendanceService>(context);
    final currentUser = context.read<AuthService>().currentUser;
    final employeeId = currentUser?.uid;

    if (employeeId == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Pointages'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Statistiques résumées
          _buildStatsHeader(context, employeeId, attendanceService),
          // Liste des pointages
          Expanded(
            child: _buildAttendanceList(context, employeeId, attendanceService),
          ),
        ],
      ),
    );
  }

  // MÉTHODE POUR PRENDRE LE SERVICE EN PARAMÈTRE
  Widget _buildStatsHeader(BuildContext context, String employeeId, AttendanceService attendanceService) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: attendanceService.getWorkStats(employeeId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final totalHours = stats['totalHours']?.toDouble() ?? 0;
        final weekHours = stats['currentWeekHours']?.toDouble() ?? 0;
        final monthHours = stats['currentMonthHours']?.toDouble() ?? 0;
        final totalAttendances = stats['totalAttendances'] ?? 0;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Statistiques de travail',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total heures', '${totalHours.toStringAsFixed(1)}h'),
                    _buildStatItem('Cette semaine', '${weekHours.toStringAsFixed(1)}h'),
                    _buildStatItem('Ce mois', '${monthHours.toStringAsFixed(1)}h'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Pointages', '$totalAttendances'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceList(BuildContext context, String employeeId, AttendanceService attendanceService) {
    return StreamBuilder<List<Attendance>>(
      stream: attendanceService.getEmployeeAttendances(employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        final attendances = snapshot.data ?? [];
        if (attendances.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucun pointage historique'),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: attendances.length,
          itemBuilder: (context, index) {
            final attendance = attendances[index];
            return _buildAttendanceItem(attendance);
          },
        );
      },
    );
  }

  Widget _buildAttendanceItem(Attendance attendance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  attendance.projectName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: attendance.isActive ? Colors.green[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: attendance.isActive ? Colors.green : Colors.blue,
                    ),
                  ),
                  child: Text(
                    attendance.isActive ? 'En cours' : 'Terminé',
                    style: TextStyle(
                      color: attendance.isActive ? Colors.green : Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTimeInfo('Entrée', attendance.formattedCheckInTime),
                const SizedBox(width: 16),
                _buildTimeInfo('Sortie', attendance.formattedCheckOutTime),
                const Spacer(),
                _buildTimeInfo('Durée', attendance.formattedDuration),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${attendance.formattedDate}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
