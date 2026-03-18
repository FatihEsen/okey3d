# Okey 3D (Okey 101)

Godot 4 ile geliştirilmiş olan bu proje, klasik Türk tahta/taş oyunu "Okey 101" oyununun 3 boyutlu bir adaptasyonudur. 

## Özellikler

- **Dinamik Istaka Yönetimi:** Oyuncunun önündeki masada 3D olarak görselleştirilmiş iki katmanlı ıstaka barındırır.
- **Akıllı Otomatik Dizme (Seri ve Çift):** 
  - **Seri Diz:** Elindeki taşları renklere ve sayılara göre peş peşe dizip farklı renkli serilerin ya da bağlantısız taşların arasını birer boşluk ayırarak düzenler.
  - **Çift Diz:** 101 kuralına uygun şekilde elde bulduğunuz çiftleri yan yana ayırarak dizebilmenizi sağlar.
- **Oyun İçi UI ve Puanlama:**
  - Gerçek zamanlı arayüz sayesinde ıstakadaki geçerli serilerinizin (`RuleEngine` validasyonundan geçenlerin) genel puanını ve var olan çift sayısını canlı olarak görebilirsiniz.
  - "Seri Diz", "Çift Diz", "Seri Aç" ve "Çift Aç" gibi geleneksel oyun aksiyon butonları arayüze entegre edilmiştir.
- **Sürükle Bırak Etkileşimi:**
  - `RigidBody3D` kullanılarak taşları fare yardımıyla hafifçe havaya kaldırıp, ıstakada dilediğiniz (ya da en yakın boş) alana pürüzsüzce animasyonlu takas (`swap`) ile bırakabilirsiniz.

## Dosya Yapısı ve Mimari
Projenin temel omurgası, temiz nesne tabanlı mimari gözetilerek yazılmıştır:

- `scenes/Main.tscn`: Ana oyun sahnemiz. Işıklandırma, kamera açıları ve oyun sonu UI elemanlarını içerir.
- `scenes/objects/Table.tscn`: Merkezdeki oyun masasını oluşturur. Masaya ait script de başlangıçtaki dağıtım `(DeckManager)` operasyonlarını izler.
- `scripts/Rack.gd`: Istaka mantığı. Fiziksel 3D koordinat haritalaması, `drag & drop` sinyal dinleyicileri (Drag Started/Ended), boşluk tespit etme ve en yakın slota yerleştirme hesaplamaları burada yer alır.
- `scripts/RuleEngine.gd`: Bir taş grubunun "Seri" veya "Çift" kuralını karşılayıp karşılamadığını algılar.

## Geliştirme (Development)
Bu projeyi klonladıktan veya indirdikten sonra **Godot 4.x** editörüyle açarak doğrudan "Play" diyerek ana sahneden çalıştırabilirsiniz. Bağımlılık gerekmeyen taş-ıstaka motoru aktif halde test alanına eklidir.

*Fırtına gibi Okey 101 maçlarında başarılar!*
