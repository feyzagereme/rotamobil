# Rota360 Mobil Uygulaması — Gizlilik Politikası ve KVKK Aydınlatma Metni

**Son güncelleme tarihi:** [TARİH GİRİLECEK]

> ⚠️ **Önemli not:** Bu metin, App Store / Play Store başvurusu için makul bir başlangıç taslağı olarak hazırlanmıştır. Sağlık kurumu bağlamında çalıştığı ve sürücü konum takibi içerdiği için, gerçek/canlı kullanıma geçmeden önce bir avukat veya KVKK danışmanı tarafından gözden geçirilmesi önerilir. Köşeli parantez içindeki `[...]` alanlar mutlaka doldurulmalıdır.

---

## 1. Veri Sorumlusu

**Rota360** mobil uygulaması ("Uygulama"), aşağıda bilgileri yer alan veri sorumlusu tarafından işletilmektedir:

- **Unvan / Ad Soyad:** [ŞİRKET UNVANI VEYA GERÇEK KİŞİ ADI GİRİLECEK]
- **Adres:** [ADRES GİRİLECEK]
- **E-posta:** [İLETİŞİM E-POSTASI GİRİLECEK]
- **KVKK başvuruları için:** [KVKK BAŞVURU E-POSTASI / VERBİS NUMARASI VARSA GİRİLECEK]

Bu metin, 6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") m.10 uyarınca aydınlatma yükümlülüğünün yerine getirilmesi amacıyla hazırlanmıştır.

---

## 2. Uygulamanın Amacı ve Kapsamı

Rota360, [HASTANE ADI GİRİLECEK — örn. Tekirdağ Şehir Hastanesi] bünyesinde çalışan saha personelinin (sürücü/kurye) günlük teslimat/ziyaret rotalarını görüntülemesi, sırayla navigasyon yapması ve tamamlanan durakları işaretlemesi amacıyla kullanılan bir kurum içi saha operasyon uygulamasıdır. Uygulama, genel kamuya açık bir tüketici uygulaması değildir; yalnızca yetkilendirilmiş personel tarafından kullanılır.

**Misafir modu:** Uygulama, kayıt olmadan "misafir" olarak da kullanılabilir. Misafir modunda oluşturulan rota/adres verileri yalnızca kullanıcının kendi cihazında saklanır, sunucularımıza aktarılmaz.

---

## 3. İşlenen Kişisel Veri Kategorileri

| Kategori | Örnek Veri | Kaynağı |
|---|---|---|
| Kimlik ve hesap bilgileri | Kullanıcı adı, kullanıcı ID'si, atanmış araç bilgisi | Kullanıcının girişi |
| İşlem güvenliği bilgileri | Şifre (yalnızca şifrelenmiş/hash'lenmiş biçimde sunucuda tutulur, cihazda oturum belirteci — JWT token — saklanır) | Kullanıcının girişi |
| Konum verisi | Anlık GPS konumu (kullanım sırasında, yaklaşık her 3 dakikada bir sunucuya iletilir) | Cihaz konum servisleri (kullanıcı izniyle) |
| İletişim/bildirim verisi | Firebase Cloud Messaging cihaz belirteci (push bildirim token'ı) | Cihaz, bildirim izni verildiğinde |
| Operasyonel/rota verisi | Ziyaret edilecek adresler, adres kodları, durak tamamlanma durumu, rota geçmişi | Kurumun planlama sisteminden aktarılan, kimliksizleştirilmiş (yalnızca adres kodu + adres içeren) rota verisi |

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

Kişisel veriler; KVKK m.5/2-(c) "bir sözleşmenin kurulması veya ifasıyla doğrudan doğruya ilgili olması" (iş/görevlendirme ilişkisi kapsamında) ve m.5/2-(f) "veri sorumlusunun meşru menfaati" hukuki sebeplerine dayanılarak işlenmektedir. Konum verisinin işlenmesi, sürücünün **açık rızasına** ve cihaz üzerinden verdiği konum izni onayına dayanmaktadır; konum izni istenildiği zaman cihaz ayarlarından geri alınabilir.

---

## 6. Kişisel Verilerin Aktarılması

- Konum, hesap ve rota verileri, uygulamanın çalışması için gerekli sunucu altyapısına ([SUNUCU/HOSTING SAĞLAYICISI ADI GİRİLECEK — örn. Render, kurumun kendi sunucusu vb.]) aktarılır.
- Push bildirimler için cihaz token'ı Google Firebase Cloud Messaging altyapısına iletilir (Google LLC, ABD merkezli — yurt dışı veri aktarımı kapsamında değerlendirilir).
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

haklarına sahiptir. Bu haklara ilişkin taleplerinizi [KVKK BAŞVURU E-POSTASI] adresine iletebilirsiniz.

---

## 9. Konum İzni Hakkında

Uygulama, yalnızca **uygulama kullanımdayken** ("when in use") konum bilgisine erişir; arka planda sürekli konum takibi yapılmaz. Konum izni, cihaz işletim sistemi ayarlarından istendiği zaman iptal edilebilir; ancak bu durumda aktif rota takibi ve en yakın durak gösterimi gibi özellikler çalışmayabilir.

---

## 10. Çocukların Gizliliği

Uygulama, kurum personeli tarafından kullanılmak üzere tasarlanmıştır ve 18 yaş altı kullanıcılara yönelik değildir.

---

## 11. Değişiklikler

Bu politika zaman zaman güncellenebilir. Önemli değişiklikler olması hâlinde kullanıcılar uygulama içi bildirim ile bilgilendirilir.

---

**İletişim:** Bu politika veya kişisel verilerinizin işlenmesiyle ilgili sorularınız için [İLETİŞİM E-POSTASI] adresinden bize ulaşabilirsiniz.
