import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class BildirimYardimcisi {
  static final FlutterLocalNotificationsPlugin _bildirimPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> baslat() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidAyarlar = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosAyarlar = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings ayarlar = InitializationSettings(
      android: androidAyarlar,
      iOS: iosAyarlar,
    );

    await _bildirimPlugin.initialize(ayarlar);

    // Kullanıcıdan bildirim izni isteme
    await _bildirimPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> hatirlaticiOlustur() async {
    const AndroidNotificationDetails androidDetay = AndroidNotificationDetails(
      'lavena_gunluk_kanal',
      'Günlük Hatırlatıcı',
      channelDescription: 'Her akşam günlük yazmayı hatırlatır',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails detaylar = NotificationDetails(android: androidDetay);

    await _bildirimPlugin.zonedSchedule(
      0,
      'Lavena Seni Bekliyor ✨',
      'Günün nasıl geçti? ',
      _saatiAyarla(20, 30),
      //tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)), deneme için
      detaylar,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // her gün aynı saatte at
    );
  }

  // Günü ve Saati Hesaplama
  static tz.TZDateTime _saatiAyarla(int saat, int dakika) {
    final tz.TZDateTime simdi = tz.TZDateTime.now(tz.local);
    tz.TZDateTime planlananZaman = tz.TZDateTime(tz.local, simdi.year, simdi.month, simdi.day, saat, dakika);

    if (planlananZaman.isBefore(simdi)) {
      planlananZaman = planlananZaman.add(const Duration(days: 1));
    }
    return planlananZaman;
  }


  static Future<void> planHatirlaticiKur(int id, String baslik, String aciklama, DateTime planZamani) async {
    const AndroidNotificationDetails androidDetay = AndroidNotificationDetails(
      'lavena_plan_kanal',
      'Plan Hatırlatmaları',
      channelDescription: 'Takvime eklenen planları hatırlatır',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF918EF4),
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails detaylar = NotificationDetails(android: androidDetay);

    final tz.TZDateTime zaman = tz.TZDateTime.from(planZamani, tz.local);


    if (zaman.isAfter(tz.TZDateTime.now(tz.local))) {
      await _bildirimPlugin.zonedSchedule(
        id,
        'Lavena Planı: $baslik',
        aciklama.isEmpty ? 'Planını uygulama vakti geldi ✨' : aciklama,
        zaman,
        detaylar,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // plan silinirse bildirimi iptal et
  static Future<void> planBildiriminiIptalEt(int id) async {
    await _bildirimPlugin.cancel(id);
  }

}