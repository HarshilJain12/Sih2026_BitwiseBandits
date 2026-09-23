import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/firestore/hospital_local_demo_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HospitalLocalDemoStore', () {
    test('seeded dataset has patients, doctors and a live OPD queue', () {
      final store = HospitalLocalDemoStore()..reset();

      expect(store.doctors.length, 4);
      expect(store.patients.length, greaterThanOrEqualTo(8));

      final queue = store.todayQueue();
      expect(queue, isNotEmpty);
      // Queue is time-ordered.
      for (var i = 1; i < queue.length; i++) {
        expect(
          queue[i].scheduledAt.isAfter(queue[i - 1].scheduledAt) ||
              queue[i].scheduledAt.isAtSameMomentAs(queue[i - 1].scheduledAt),
          isTrue,
        );
      }

      final stats = store.overview();
      expect(stats['totalDoctors'], 4);
      expect(stats['doctorsOnDuty'], 4);
      expect(stats['todayAppointments'],
          stats['opdWaiting']! + stats['opdInConsultation']! + stats['completedToday']!);
      expect(stats['pendingAlerts'], 2);
    });

    test('callNext moves the first waiting token into consultation', () {
      final store = HospitalLocalDemoStore()..reset();

      final before = store
          .queueForDoctor('DOC001')
          .where((a) => a.status == 'upcoming')
          .length;
      expect(before, greaterThan(0));

      store.callNext('DOC001');

      final queue = store.queueForDoctor('DOC001');
      expect(queue.where((a) => a.status == 'current').length, greaterThan(0));
      expect(
        queue.where((a) => a.status == 'upcoming').length,
        before - 1,
      );
    });

    test('searchPatients filters by name, id and phone', () {
      final store = HospitalLocalDemoStore()..reset();

      expect(store.searchPatients('rahul').length, 1);
      expect(store.searchPatients('P-1002938472').length, 1);
      expect(store.searchPatients('9822011225').length, 1);
      expect(store.searchPatients('').length, store.patients.length);
      expect(store.searchPatients('zzz-no-match'), isEmpty);
    });

    test('duty toggle and alert verify update the roster and inbox', () {
      final store = HospitalLocalDemoStore()..reset();

      store.setDuty('DOC001', false);
      expect(
        store.roster().firstWhere((d) => d.doctorId == 'DOC001').onDuty,
        isFalse,
      );
      expect(store.overview()['doctorsOnDuty'], 3);

      store.updateAlertStatus('demo_alert_1', 'verified');
      expect(store.pendingAlerts().length, 1);
    });
  });
}
