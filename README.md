# Projects

Bu repo, `/mnt/local/projects` ana klasorundeki proje klasorlerini takip etmek icin kullanilan yardimci script ve markdown ciktilarini tutar.

Bu repo alt klasorlerdeki projeleri takip etmez. `.gitignore` dosyasi sayesinde sadece takip scripti, markdown ciktilari ve bu `README.md` dosyasi GitHub'a gonderilir.

## Kurulum ve kullanim notu

Bu dizinde takip edilecek ana dosyalar sunlar olacak:

1. `projects-main-folder-structure.sh`
2. `projects-main-folder-structure-index.md`
3. `projects-main-folder-structure-link-list.md`
4. `README.md`
5. `.gitignore`

Script her zaman kendi bulundugu dizinde calisir. Baska bir yere tasindiginda, o yeni dizindeki proje klasorlerini tarar.

Calistirma:

```bash
chmod +x projects-main-folder-structure.sh
./projects-main-folder-structure.sh
```

Menu:

```text
1) Dizin taramasini yenile, index ve link listesini olustur
2) Link listesindeki tum linkleri yorum satiri yap
3) Link listesindeki tum yorumlari kaldir
4) Yorum satiri olmayan linkleri bu dizine git clone ile indir
5) Tum ana klasorlere .ignore-backup dosyasi ekle
0) Cikis
```

`1` secenegi mevcut dizindeki ana klasorleri tarar. Klasorun icinde `.git` varsa `origin` remote linkini okur. Sonra `projects-main-folder-structure-index.md` dosyasini GitHub, GitLab, Bitbucket, Diger ve Link Yok basliklari altinda numarali olarak yazar. Ayni anda `projects-main-folder-structure-link-list.md` dosyasini sadece clone linklerinden olusan sade liste olarak gunceller.

`projects-main-folder-structure-link-list.md` icinde bir linkin basina `# ` koyarsan, `4` secenegi o linki indirmez. `1` secenegi listeyi yenilerken daha once yorum yaptigin linkleri korur.

## 5. secenek: .ignore-backup dosyasi ekleme

`5` secenegi, scriptin bulundugu ana dizindeki tum birinci seviye klasorleri gezer ve her klasorun icine `.ignore-backup` adinda bos bir dosya ekler.

Ornek:

```text
/mnt/local/projects/ComfyUI/.ignore-backup
/mnt/local/projects/FFmpeg/.ignore-backup
/mnt/local/projects/ImageMagick/.ignore-backup
```

Bu islem rclone yedekleme mantigi icin kullanilabilir. Klasorun icinde `.ignore-backup` dosyasi varsa, o klasor yedekleme/backup surecinde ozel olarak ayirt edilebilir.

Bu secenek kesinlikle silme yapmaz. Var olan `.ignore-backup` dosyasinin uzerine de yazmaz. Sadece dosya yoksa ekler.

Davranis ozeti:

```text
Dosya yoksa: .ignore-backup olusturur.
Dosya varsa: dokunmaz, "zaten vardi" diye sayar.
Hata olursa: hata sayisina ekler.
Silme yoktur.
Uzerine yazma yoktur.
```

Calisma sonunda sana sonuc yazar:

```text
.ignore-backup sonucu: 134 klasor kontrol edildi, 20 yeni eklendi, 114 zaten vardi, 0 hata.
```

Yani tek tek kontrol etmek zorunda kalmazsin. Kac klasor kontrol edildi, kacina yeni dosya eklendi, kacinda zaten vardi, sorun var mi hepsini cikti olarak gorursun.

## Git kurulumu

Git kurulumu otomatik yapilmaz. Bu klasoru git ile takip etmek istediginde su sekilde kur:

```bash
git init
printf "*\n!projects-main-folder-structure.sh\n!projects-main-folder-structure-index.md\n!projects-main-folder-structure-link-list.md\n!README.md\n!.gitignore\n" > .gitignore
git add .gitignore README.md projects-main-folder-structure.sh projects-main-folder-structure-index.md projects-main-folder-structure-link-list.md
git commit -m "Add projects main folder structure tracker"
```

Boylece bu dizindeki diger proje klasorleri ve dosyalar git tarafindan takip edilmez; sadece script, iki otomatik markdown dosyasi, `README.md` ve `.gitignore` takip edilir.

## Neden .gitignore kullaniyoruz?

Bu ana klasorun altinda 100'den fazla proje klasoru olabilir. Bu klasorde `git init` yapinca Git normalde altindaki her dosyayi ve klasoru takip etmeye aday gorur. Yani `git status` calistirdiginda butun proje klasorleri `untracked` olarak gorunebilir.

Biz bunu istemiyoruz. Cunku bu repo sadece takip scriptini ve onun markdown ciktilarini saklamak icin var. Altindaki gercek proje klasorleri ayri projeler olabilir, kendi git repolari olabilir veya hic takip edilmemesi gerekebilir.

Bu yuzden `.gitignore` dosyasina once her seyi kapatan bir kural yaziyoruz:

```gitignore
*
```

Bu su demek:

```text
Bu klasordeki her seyi Git takip etmesin.
```

Sonra takip edilmesini istedigimiz dosyalari `!` isaretiyle tekrar aciyoruz:

```gitignore
!projects-main-folder-structure.sh
!projects-main-folder-structure-index.md
!projects-main-folder-structure-link-list.md
!README.md
!.gitignore
```

Buradaki `!` su anlama gelir:

```text
Bu dosyayi ignore etme, Git takip edebilsin.
```

Yani tam `.gitignore` dosyasi boyle olmali:

```gitignore
*
!projects-main-folder-structure.sh
!projects-main-folder-structure-index.md
!projects-main-folder-structure-link-list.md
!README.md
!.gitignore
```

Kontrol etmek icin:

```bash
git status
```

Bu komutta 100+ proje klasorunu gormemen gerekir. Sadece bizim izin verdigimiz dosyalar gorunmeli.

Daha detayli kontrol icin:

```bash
git status --ignored
```

Bu komut ignore edilen dosyalari da gosterir. Orada diger proje klasorlerini ignore edilmis olarak gorebilirsin. Bu normal ve istedigimiz davranistir.
