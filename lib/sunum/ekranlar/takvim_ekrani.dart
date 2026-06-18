import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../veri/modeller/plan_modeli.dart';
import '../durum_yonetimi/plan_saglayicisi.dart';
import '../../cekirdek/servisler/bildirim_yardimcisi.dart';

class TakvimEkran extends StatefulWidget {
  const TakvimEkran({super.key});

  @override
  State<TakvimEkran> createState() => _TakvimEkranState();
}

class _TakvimEkranState extends State<TakvimEkran> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int? _aktifKullaniciId;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _kullaniciIdYukle();
  }

  Future<void> _kullaniciIdYukle() async {
    final prefs = await SharedPreferences.getInstance();
    _aktifKullaniciId = prefs.getInt('aktifKullaniciId');
    if (_aktifKullaniciId != null && mounted) {
      context.read<PlanSaglayicisi>().planlariYukle(_aktifKullaniciId!);
    }
  }

  void _planEkleSheet() {
    final baslikCtrl = TextEditingController();
    final aciklamaCtrl = TextEditingController();
    TimeOfDay secilenSaat = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(30, 20, 30, MediaQuery.of(ctx).viewInsets.bottom + 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Kozmik Plan Oluştur ✨", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A), letterSpacing: 0.5)),
              const SizedBox(height: 20),
              TextField(
                controller: baslikCtrl,
                decoration: InputDecoration(
                  labelText: "Planın Başlığı nedir?",
                  prefixIcon: const Icon(Icons.star_purple500_rounded, color: Color(0xFF918EF4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: aciklamaCtrl,
                decoration: InputDecoration(
                  labelText: "Küçük bir not bırak (Opsiyonel)",
                  prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFFB5A8F9)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: const Color(0xFFF4F3FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  leading: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF918EF4)),
                  title: Text("Hatırlatma Saati: ${secilenSaat.format(context)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () async {
                    final TimeOfDay? time = await showTimePicker(context: context, initialTime: secilenSaat);
                    if (time != null) setModalState(() => secilenSaat = time);
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF918EF4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () async {
                    if (baslikCtrl.text.trim().isEmpty || _aktifKullaniciId == null || _selectedDay == null) return;

                    String formatliTarih = "${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}";
                    String formatliSaat = "${secilenSaat.hour.toString().padLeft(2, '0')}:${secilenSaat.minute.toString().padLeft(2, '0')}";

                    final yeniPlan = PlanModeli(
                      kullaniciId: _aktifKullaniciId!,
                      baslik: baslikCtrl.text.trim(),
                      aciklama: aciklamaCtrl.text.trim(),
                      tarih: formatliTarih,
                      saat: formatliSaat,
                    );

                    await context.read<PlanSaglayicisi>().planEkle(yeniPlan);

                    final planDateTime = DateTime(
                      _selectedDay!.year,
                      _selectedDay!.month,
                      _selectedDay!.day,
                      secilenSaat.hour,
                      secilenSaat.minute,
                    );

                    int benzersizId = planDateTime.millisecondsSinceEpoch.remainder(100000);

                    await BildirimYardimcisi.planHatirlaticiKur(
                        benzersizId,
                        baslikCtrl.text.trim(),
                        aciklamaCtrl.text.trim(),
                        planDateTime
                    );

                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text("GÖKYÜZÜNE KAYDET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFE),
      appBar: AppBar(
        title: const Text("Zaman Çizelgem", style: TextStyle(color: Color(0xFF4A4A4A), letterSpacing: 2, fontWeight: FontWeight.w300)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF4A4A4A)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF918EF4),
        onPressed: _planEkleSheet,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      body: Consumer<PlanSaglayicisi>(
        builder: (context, saglayici, child) {
          if (saglayici.yukleniyor) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF918EF4)));
          }

          String formatliSeciliTarih = _selectedDay != null
              ? "${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}"
              : "";

          final seciliGunPlanlari = saglayici.getGunlukPlanlar(formatliSeciliTarih);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE0EAFC), Color(0xFFFDFCFE)],
              ),
            ),
            child: Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      startingDayOfWeek: StartingDayOfWeek.monday,

                      eventLoader: (day) {
                        String formatliKey = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                        return saglayici.planlarMap[formatliKey] ?? [];
                      },

                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
                        leftChevronIcon: Icon(Icons.chevron_left_rounded, color: Color(0xFF918EF4)),
                        rightChevronIcon: Icon(Icons.chevron_right_rounded, color: Color(0xFF918EF4)),
                      ),
                      selectedDayPredicate: (day) {
                        return _selectedDay != null && day.year == _selectedDay!.year && day.month == _selectedDay!.month && day.day == _selectedDay!.day;
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) => setState(() => _calendarFormat = format),
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(color: Color(0xFFE0DBFF), shape: BoxShape.circle),
                        todayTextStyle: TextStyle(color: Color(0xFF918EF4), fontWeight: FontWeight.bold),
                        selectedDecoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF918EF4)]),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(color: Color(0xFF8176AF), shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1FE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDCDFFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_twilight_rounded, size: 18, color: Color(0xFF8A82E6)),
                      const SizedBox(width: 10),
                      Text(
                        "${_selectedDay!.day} ${_ayIsmiBul(_selectedDay!.month)} Günü Planları",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5A5A7A), letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),

                Expanded(
                  child: seciliGunPlanlari.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wb_twilight_rounded, size: 50, color: const Color(0xFF918EF4).withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          "Bu güne ait bir planlanmış aktivite yok.\nYıldız eklemek için + butonuna dokun.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: seciliGunPlanlari.length,
                    itemBuilder: (context, index) {
                      final plan = seciliGunPlanlari[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFDFF),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE4E7FF), width: 1.5),
                          boxShadow: [BoxShadow(color: const Color(0xFF918EF4).withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF918EF4), width: 5))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("SAAT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
                                      const SizedBox(height: 2),
                                      Text(plan.saat, style: const TextStyle(color: Color(0xFF5A5A7A), fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'Courier')),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Container(width: 1, height: 30, color: Colors.black12),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(plan.baslik, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333), fontSize: 15, letterSpacing: 0.1)),
                                        if (plan.aciklama != null && plan.aciklama!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(plan.aciklama!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.2)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                    onPressed: () async {
                                      if (plan.id != null && _aktifKullaniciId != null) {
                                        await saglayici.planSil(plan.id!, _aktifKullaniciId!);

                                        try {
                                          final parcalar = plan.tarih.split('-');
                                          final saatParcalar = plan.saat.split(':');
                                          final pTarih = DateTime(int.parse(parcalar[0]), int.parse(parcalar[1]), int.parse(parcalar[2]), int.parse(saatParcalar[0]), int.parse(saatParcalar[1]));
                                          int iptalId = pTarih.millisecondsSinceEpoch.remainder(100000);
                                          await BildirimYardimcisi.planBildiriminiIptalEt(iptalId);
                                        } catch (_) {}
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _ayIsmiBul(int ayKodu) {
    const aylar = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];
    return aylar[ayKodu - 1];
  }
}