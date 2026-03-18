extends AcceptDialog

@onready var text_label := $MarginContainer/ScrollContainer/RuleText

const RULES_KATLAMASIZ = """KATLAMASIZ 101 OKEY KURALLARI

[b]Taşlar ve Dağıtım[/b]
• 106 taş: 1–13 × 4 renk × 2 takım = 104 + 2 numarasız joker.
• 4 oyuncuya: 1 kişiye 22, diğerlerine 21 taş dağıtılır.
• Kalan 21 taş kapalı yığın. En üstteki açılır → gösterge taşı.
• Göstergenin aynı renginin bir üst sayısı OKEYdir (13 → 1).

[b]Oyun Akışı[/b]
• Sıra saat yönünün tersine (sağdan sola) ilerler.
• Başlayan oyuncu taş ÇEKMEDEN bir taş atar.
• Sıra gelen oyuncu: yıgındaki en üst taşı VEYA kapalı desteden çeker → bir taş atar.
• Yandan (atılan bloktan) taş alırsan, o taşı açarken KULLANMAK zorunda + el AÇMAK zorunlu.

[b]Per ve Çift[/b]
• Per (Seri): Aynı renk art arda en az 3 taş (örn: Kırmızı 7-8-9).
• Per (Renk): Aynı sayı, farklı renk en az 3 taş (örn: 5 Kırmızı-Sarı-Mavi).
• Çift: Aynı sayı, aynı renk 2 taş (örn: iki Mavi 7).
• Okey istediğin yere joker olarak girer. Okeyler çift oluşturamaz (standart kural).

[b]El Açma (Masa Açma)[/b]
• Perler + çiftlerin toplam puanı ≥ 101 olmalı. VEYA en az 5 çift.
• Yanlış açma: 101 puan ceza + taşlar geri alınır.
• El açıkken yerdeki perlere taş ekleyebilirsin.
• Okeyden gerçek taşı varsa el açıkken okeyi yerden alabilirsin.

[b]Bitirme[/b]
• Tüm taşları per/çift yaparak veya yere işleyerek bitir.
• Son taşla da bitirilebilir (gösterge üstüne kapalı at).
• Okey atarak bitirirsen özel avantaj (masaya göre değişir).

[b]Ceza[/b]
• Elde kalan taşların puan toplamı ceza olarak eklenir.
• Okey atma hatası: +101 ceza.
• En düşük toplam puanı olan oyuncu kazanır."""

const RULES_KATLAMALI = """KATLAMALI 101 OKEY KURALLARI

[b]Genel Kurallar[/b]
Taşlar, dağıtım, per/çift tanımı, sıra yönü ve okey kuralı
KATLAMASIZ ile aynıdır. Aşağıdaki FARK geçerlidir:

[b]Katlamalı El Açma Kuralı (En Önemli Fark!)[/b]
• İlk açan oyuncu: ≥ 101 puan veya ≥ 5 çift.
• Sonraki her açacak oyuncu, ÖNCEKİ EL'İN açtığı puandan EN AZ 1 FAZLA puanla açmak zorundadır.
   → İlk açan 116 puanla açtıysa, ikincisi ≥ 117 puanla açmalı.
   → Üçüncü ise ≥ 118 ile açmalı. Böylece baraj sürekli katlanır.
• Çift açmada da aynı kural: 5 çiftle açıldıysa sonraki ≥ 6 çift açmalı.

[b]Barajı Aşamayan Oyuncu[/b]
• Katlamalı barajı karşılayamayan oyuncu, açış yapamaz; elindeki taşları biriktirmeye devam eder.
• Yanlış açma cezası (101 puan) yine geçerlidir.

[b]Elden Direkt Bitirme[/b]
• Tüm taşlar per/çift olarak geçerliyse hiç açmadan elden bitirilebilir.
• Bu durumda katlamalı baraj aranmaz.

[b]Ceza ve Kazanma[/b]
• Elde kalan taş puan toplamı + özel cezalar (masaya değişir).
• Yanlış açma, okey atma, her ceza KATLAMASIZ ile aynıdır.
• En düşük toplam puana sahip oyuncu kazanır."""

func show_rules(mode: int) -> void:
	if mode == Constants.GameMode.KATLAMASIZ:
		title = "Katlamasız 101 Okey — Kurallar"
		text_label.text = RULES_KATLAMASIZ
	else:
		title = "Katlamalı 101 Okey — Kurallar"
		text_label.text = RULES_KATLAMALI
