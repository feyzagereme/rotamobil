# Rota360 Mobil Uygulaması — Gizlilik Politikası ve KVKK Aydınlatma Metni

**Son güncelleme tarihi:** 9 Ağustos 2026

---

## 1. Veri Sorumlusu

**Rota360** mobil uygulaması ("Uygulama"), aşağıda bilgileri yer alan veri sorumlusu tarafından işletilmektedir:

- **Unvan / Ad Soyad:** Arjin Özceylan (şahıs)
- **Adres:** Turgutalp Mahallesi, Hacıyamak Caddesi, No: 22, Soma / Manisa
- **E-posta:** 360.rotaa@gmail.com
- **KVKK başvuruları için:** 360.rotaa@gmail.com

Bu metin, 6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") m.10 uyarınca aydınlatma yükümlülüğünün yerine getirilmesi amacıyla hazırlanmıştır.

---

## 2. Uygulamanın Amacı ve Kapsamı

Rota360, birden fazla durağı en kısa/en hızlı şekilde dolaşmak isteyen herkesin ücretsiz olarak kullanabileceği bir rota planlama ve optimizasyon uygulamasıdır. Kayıt olmadan "misafir" modunda kullanılabildiği gibi, kurumsal bir hesapla giriş yapan personel için de atanmış rota/durak listelerini görüntüleme imkânı sunar.

**Misafir modu:** Misafir modunda oluşturulan rota/adres verileri yalnızca kullanıcının kendi cihazında saklanır, sunucularımıza aktarılmaz. Rota hesaplaması için (trafik bilgisi dahil) yalnızca girilen durak koordinatları, kimliğinizle ilişkilendirilmeden, rota hesaplama hizmeti sağlayan üçüncü bir servise (TomTom) iletilir.

**Kurumsal/personel girişi:** Bir kuruma bağlı personel hesabıyla giriş yapıldığında, aşağıdaki 3. bölümde açıklanan ek veri kategorileri (konum, hesap bilgisi vb.) işlenir.

---

## 3. İşlenen Kişisel Veri Kategorileri

| Kategori | Örnek Veri | Kaynağı |
|---|---|---|
| Kimlik ve hesap bilgileri | Kullanıcı adı, kullanıcı ID'si, atanmış araç bilgisi | Personel girişi (yalnızca kurumsal hesaplar); mobil uygulama için bulut tabanlı sunucu ve veritabanında (bkz. Bölüm 6) saklanır |
| İşlem güvenliği bilgileri | Şifre (yalnızca şifrelenmiş/hash'lenmiş biçimde sunucuda tutulur, cihazda oturum belirteci — JWT token — saklanır) | Personel girişi |
| Konum verisi | Anlık GPS konumu (yaklaşık her 3 dakikada bir sunucuya iletilir) | Cihaz konum servisleri — **yalnızca kurumsal hesapla giriş yapıldığında**, kullanıcı izniyle. Misafir modunda cihaz konumu hiç okunmaz. |
| İletişim/bildirim verisi | Firebase Cloud Messaging cihaz belirteci (push bildirim token'ı) | Cihaz, bildirim izni verildiğinde |
| Operasyonel/rota verisi | Ziyaret edilecek adresler, durak tamamlanma durumu, rota geçmişi | Misafir modunda yalnızca cihazda; mobil uygulamada kurumun bulut tabanlı sunucu altyapısı üzerinden |

> **Not:** Hasta adı, T.C. kimlik numarası, telefon numarası gibi hastaya ait kimliği belirleyici özel nitelikli veriler bu uygulamaya **aktarılmaz**; bu veriler kurumun kendi iç/lokal sisteminde kalır. Uygulamaya yalnızca adres ve kurum içi adres kodu (örn. "M001") ulaşır.

---

## 4. Kişisel Verilerin İşlenme Amaçları

- Sürücü hesabının kimlik doğrulaması ve oturum güvenliğinin sağlanması
- Günlük rota/durak listesinin sürücüye gösterilmesi ve navigasyonun sağlanması
- Sürücünün anlık konumunun, aktif teslimat/ziyaret süresince operasyonel takip ve en yakın durağın belirlenmesi amacıyla işlenmesi
- Rota tamamlanma durumunun ve geçmişinin kayıt altına alınması
- Rota/durak güncellemeleri hakkında push bildirim gönderilmesi
- Uygulamanın teknik olarak çalışır ve güvenli tutulması

---

## 5. Hukuki Sebep

Misafir kullanıcılar için kişisel veri işlenmesi, uygulamanın temel işlevini (rota hesaplama) yerine getirebilmesi amacıyla KVKK m.5/2-(f) "veri sorumlusunun meşru menfaati" hukuki sebebine dayanır ve veriler cihazda kalır. Kurumsal personel için ise KVKK m.5/2-(c) "bir sözleşmenin kurulması veya ifasıyla doğrudan doğruya ilgili olması" (iş/görevlendirme ilişkisi) hukuki sebebine dayanılır. Konum verisinin işlenmesi her durumda kullanıcının **açık rızasına** ve cihaz üzerinden verdiği konum izni onayına dayanır; izin istenildiği zaman cihaz ayarlarından geri alınabilir.

---

## 6. Kişisel Verilerin Aktarılması

- **Mobil uygulama (kurumsal personel girişi):** Hesap, rota ve konum verileri, uygulamamızın çalıştırdığı bir sunucu üzerinden işlenir; bu sunucu Render (Render Services, Inc., ABD merkezli) bulut altyapısında barındırılır, veritabanı ise Neon (Neon, Inc., ABD merkezli) tarafından sağlanan bulut tabanlı bir PostgreSQL veritabanıdır. Bu nedenle kurumsal hesap verileri **yurt dışına aktarılmaktadır**. Sunucu ile uygulama arasındaki iletişim HTTPS ile şifrelenir.
- **Web/masaüstü istemcisi (kurum içi kullanım):** Kurumun kendi bilgisayarında/ağında yerel bir arayüz olarak çalışır; şu an mobil uygulamayla aynı bulut sunucusuna bağlanmaktadır. Hastane içi tamamen yerel bir sunucu/veritabanı ve bulutla senkronizasyon mimarisi planlanmakta olup henüz devreye alınmamıştır; bu mimari tamamlandığında bu politika güncellenecektir.
- Rota hesaplaması/haritada gerçek yol geometrisinin çizilmesi için durak koordinatları, kimlikle ilişkilendirilmeden TomTom (TomTom International B.V.) rota hesaplama servisine iletilir. Bu, hem misafir modunda hem kurumsal personel girişinde (atanmış rotanın haritada gösterilmesi sırasında) geçerlidir.
- Kurumsal panelden (yönetici/dispatcher tarafından) rota optimizasyonu istendiğinde, durak koordinatları kimlikle ilişkilendirilmeden Google Maps Platform (Distance Matrix API, Google LLC, ABD merkezli — yurt dışı veri aktarımı kapsamında değerlendirilir) servisine iletilir.
- Push bildirimler için cihaz token'ı Google Firebase Cloud Messaging altyapısına iletilir (Google LLC, ABD merkezli — yurt dışı veri aktarımı kapsamında değerlendirilir).
- Hata/performans izleme için teknik hata kayıtları Sentry (Functional Software, Inc., ABD merkezli) altyapısına iletilebilir.
- Veriler, kanunen yetkili kamu kurum ve kuruluşları haricinde üçüncü taraflarla **pazarlama, reklam veya başka bir ticari amaçla paylaşılmaz, satılmaz.**

---

## 7. Verilerin Saklanma Süresi

Kişisel veriler, yukarıda belirtilen amaçların gerektirdiği süre boyunca ve ilgili mevzuatta öngörülen zamanaşımı süreleri saklı kalmak kaydıyla saklanır. Kullanıcı hesabının silinmesi talebi üzerine, mevzuattan doğan zorunlu saklama yükümlülükleri hariç olmak üzere veriler silinir/anonimleştirilir.

---

## 8. İlgili Kişinin (Veri Sahibinin) Hakları

KVKK m.11 uyarınca her veri sahibi:

- Kişisel verisinin işlenip işlenmediğini öğrenme,
- İşlenmişse buna ilişkin bilgi talep etme,
- İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme,
- Yurt içinde/yurt dışında aktarıldığı üçüncü kişileri bilme,
- Eksik/yanlış işlenmişse düzeltilmesini isteme,
- KVKK'da öngörülen şartlar çerçevesinde silinmesini/yok edilmesini isteme,
- Yapılan işlemlerin, verilerin aktarıldığı üçüncü kişilere bildirilmesini isteme,
- Otomatik sistemlerle analiz sonucu aleyhe bir sonucun ortaya çıkmasına itiraz etme,
- Kanuna aykırı işlenme sebebiyle zarara uğraması hâlinde zararın giderilmesini talep etme

haklarına sahiptir. Bu haklara ilişkin taleplerinizi 360.rotaa@gmail.com adresine iletebilirsiniz.

---

## 9. Konum İzni Hakkında

Uygulama, yalnızca kurumsal hesapla giriş yapıldığında ve **uygulama kullanımdayken** ("when in use") konum bilgisine erişir; arka planda sürekli konum takibi yapılmaz. Misafir modunda cihaz konumu hiçbir şekilde okunmaz. Konum izni, cihaz işletim sistemi ayarlarından istendiği zaman iptal edilebilir.

---

## 10. Çocukların Gizliliği

Uygulama genel kullanıcılara açık olmakla birlikte, 13 yaş altı çocuklardan bilerek veri toplanmaz.

---

## 11. Değişiklikler

Bu politika zaman zaman güncellenebilir. Önemli değişiklikler olması hâlinde kullanıcılar uygulama içi bildirim ile bilgilendirilir.

---

**İletişim:** Bu politika veya kişisel verilerinizin işlenmesiyle ilgili sorularınız için 360.rotaa@gmail.com adresinden bize ulaşabilirsiniz.
