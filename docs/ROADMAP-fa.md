# نقشه‌راه پروژه DevOps — Maktab Sharif SRS

## ۱. هدف پروژه

هدف این پروژه ساخت یک آزمایشگاه DevOps قابل‌انتقال از macOS به سرور Ubuntu است.
این آزمایشگاه باید بخش‌های اصلی یک زیرساخت واقعی را تمرین کند: مدیریت سرور،
امنیت شبکه، DNS و VPN، Kubernetes، استقرار برنامه، CI/CD، مانیتورینگ، لاگ و
پشتیبان‌گیری.

> وضعیت فعلی: محیط ما آزمایشگاهی و محلی است. هنوز سرور عمومی، IP عمومی و دامنه
> خریداری نشده است؛ بنابراین سرویس‌ها را مستقیماً روی اینترنت منتشر نمی‌کنیم.

## ۲. معماری فعلی آزمایشگاه

```text
macOS Apple Silicon
└── Multipass
    └── devops-ubuntu (Ubuntu 24.04 ARM64)
        ├── IP خصوصی: 192.168.252.2
        ├── RAM: حدود 2 GiB
        ├── CPU: 2 هسته
        ├── دیسک: حدود 12 GiB
        ├── Ansible target
        ├── UFW firewall
        └── Private DNS: dnsmasq / lab.internal
```

کنترل‌کننده‌ی Ansible روی macOS است و با SSH key به کاربر `lab` روی VM وصل می‌شود.

## ۳. چه کارهایی تاکنون انجام شده است؟

### فاز ۱ — آماده‌سازی محیط توسعه

- بررسی معماری Mac و انتخاب VM مناسب برای Apple Silicon.
- تأیید نصب Git و Ansible.
- ساخت repository در مسیر `/Users/abolfazl/devops-lab`.
- ساخت inventory و تنظیم `ansible.cfg`.

### فاز ۲ — ساخت VM خودکار

- نصب و استفاده از Multipass.
- ساخت VM به‌صورت خودکار با اسکریپت `scripts/create-vm.sh`.
- ایجاد SSH key در `~/.ssh/devops_lab_ed25519`.
- تولید خودکار inventory با IP VM.
- استفاده از cloud-init برای ساخت کاربر اولیه.

### فاز ۳ — اتصال و بررسی Ansible

- اتصال موفق Ansible به VM.
- پاسخ موفق `ping: pong`.
- شناسایی Ubuntu 24.04 و معماری `aarch64`.
- بررسی RAM و فضای دیسک.

### فاز ۴ — آماده‌سازی Ubuntu

- به‌روزرسانی packageها.
- نصب ابزارهای پایه: `curl`, `git`, `htop`, `jq`, `unzip`, `ufw`.

### فاز ۵ — مدیریت کاربر

- ساخت کاربر `viewer`.
- قفل‌کردن password این کاربر.
- اطمینان از اینکه عضو گروه `sudo` نیست.
- نگه‌داشتن کاربر `lab` برای مدیریت Ansible.

### فاز ۶ — فایروال

- فعال‌سازی UFW.
- سیاست پیش‌فرض: رد ورودی‌ها و اجازه‌ی خروجی‌ها.
- بازکردن SSH روی TCP/22.
- فعال‌کردن logging سطح low.
- آزمایش موفق اتصال Ansible بعد از فعال‌سازی فایروال.

### فاز ۷ — DNS خصوصی

- نصب و تنظیم `dnsmasq`.
- ایجاد دامنه‌ی داخلی `lab.internal`.
- ایجاد رکوردهای زیر:
  - `devops-ubuntu.lab.internal`
  - `vm.lab.internal`
- بازکردن TCP/53 و UDP/53 فقط برای شبکه‌ی `192.168.252.0/24`.
- تست موفق resolve به IP `192.168.252.2`.

### فاز ۸ — VPN آزمایشگاهی WireGuard

- نصب `wireguard-tools` روی Ubuntu.
- ساخت interface به نام `wg0` با آدرس `10.8.0.1/24`.
- فعال‌سازی IPv4 forwarding.
- بازکردن UDP/51820 فقط برای شبکه‌ی خصوصی Multipass.
- ثبت یک peer کلاینت با آدرس `10.8.0.2/32`.
- ساخت فایل کلاینت خارج از Git در `~/.ssh/devops_lab-wg0.conf`.
- آماده‌سازی DNS خصوصی برای پاسخ‌گویی روی آدرس VPN `10.8.0.1`.

وضعیت: **سرور آماده و فعال؛ handshake کلاینت macOS هنوز انجام نشده است** چون
ابزار WireGuard روی macOS در حال نصب/دانلود وابستگی‌هاست. این VPN فعلاً فقط
برای شبکه‌ی خصوصی آزمایشگاه است و IP عمومی ندارد.

## ۴. Commitهای فعلی

| Commit | توضیح |
|---|---|
| `74f6441` | ساخت محیط Ubuntu و Ansible |
| `b9011d1` | ساخت viewer و بررسی فایروال |
| `4410f2c` | فعال‌سازی UFW امن |
| `1a77a7d` | تنظیم DNS خصوصی |

## ۵. فازهای کامل پروژه بر اساس SRS

### فاز A — طراحی معماری و ظرفیت

**هدف:** طراحی شبکه، VMها، IPها و وابستگی سرویس‌ها.

خروجی‌ها:

- دیاگرام معماری.
- جدول VMها، CPU، RAM، Disk و IP.
- جدول پورت‌ها و جریان‌های شبکه.
- مشخص‌کردن سرویس‌هایی که public و private هستند.

### فاز B — آماده‌سازی VM و مدیریت پیکربندی

**ابزارها:** Ubuntu، SSH، Git، Ansible.

خروجی‌ها:

- VM آماده.
- کاربر مدیریتی امن.
- کاربر viewer.
- Playbookهای قابل تکرار.

### فاز C — امنیت شبکه و دسترسی

**ابزارها:** UFW، SSH، VPN، Private DNS، PAM.

ترتیب پیشنهادی:

1. تعریف سیاست default deny.
2. بازکردن پورت‌های ضروری.
3. راه‌اندازی VPN.
4. محدودکردن دسترسی سرویس‌های خصوصی به VPN.
5. راه‌اندازی PAM و دسترسی آن از VPN و DNS داخلی.

### فاز D — Kubernetes و ذخیره‌سازی

**ابزارها:** Kubernetes، NFS یا storage مناسب، NetworkPolicy.

خروجی‌ها:

- کلاستر Kubernetes.
- namespaceهای جداگانه.
- storage class یا NFS.
- NetworkPolicy برای محدودکردن ارتباط Podها.
- مستندات وضعیت Nodeها و سرویس‌ها.

> این فاز روی VM فعلی به دلیل RAM کم محدود است و بهتر است روی سرور قوی‌تر اجرا شود.

### فاز E — Git خصوصی، Registry خصوصی و CI/CD

**هدف:** هر تغییر کد به‌شکل خودکار build، test و deploy شود.

اجزا:

- Git خصوصی.
- Docker Registry خصوصی.
- pipeline برای build و test.
- انتشار image با tag مشخص.
- GitOps برای نگهداری وضعیت مطلوب در Git.

### فاز F — استقرار برنامه‌ها

برنامه‌های موردنیاز:

- Backend.
- Frontend.
- PostgreSQL cluster.
- Redis.
- WordPress با تنظیمات پیش‌فرض.
- Nginx برای cache فایل‌های ثابت مانند image و font.

برای هر سرویس باید deployment، service، config و secret جداگانه تعریف شود.

### فاز G — مانیتورینگ و Alerting

موارد مورد پایش:

- CPU، RAM، IOPS، Disk و Network ماشین‌ها.
- uptime سرویس‌ها.
- PostgreSQL و Redis.
- وضعیت Node، Pod و Service در Kubernetes.
- status code دامنه‌ها.
- زمان انقضای certificate.
- هشدار با Email، Slack یا Rocket.Chat.

### فاز H — لاگ و ELK

**اجزا:** Elasticsearch، Logstash و Kibana.

خروجی‌ها:

- جمع‌آوری لاگ سرویس‌ها.
- نمایش لاگ‌های Nginx.
- نمایش status code، cache status و upstream response time.
- گزارش ۵۰ درخواست اخیر.
- نمودار تعداد درخواست‌ها در زمان.

### فاز I — Backup و بازیابی

موارد پشتیبان‌گیری:

- PostgreSQL.
- داده‌های WordPress.
- تنظیمات Kubernetes و GitOps.
- تنظیمات DNS، VPN و PAM.
- فایل‌های مهم برنامه.

برای هر backup باید این موارد مشخص شوند:

- زمان‌بندی.
- مقصد ذخیره‌سازی.
- retention policy.
- رمزنگاری.
- alert در صورت شکست.
- تست restore.

### فاز J — انتقال به سرور واقعی و تحویل

- انتقال inventory از Multipass به سرور Ubuntu.
- بررسی IP عمومی و DNS provider.
- خرید و اتصال دامنه.
- دریافت certificate معتبر.
- محدودکردن SSH و فعال‌کردن VPN.
- اجرای تست‌های نهایی.
- تهیه مستندات، دیاگرام، اسکرین‌شات و گزارش تحویل.

## ۶. وضعیت پروژه

| فاز | وضعیت |
|---|---|
| A طراحی معماری | در حال تکمیل |
| B VM و Ansible | انجام شده برای lab |
| C UFW و DNS پایه | انجام شده برای lab |
| C VPN WireGuard آزمایشگاهی | سرور انجام شده؛ کلاینت pending |
| C PAM | انجام نشده |
| D Kubernetes و NFS | انجام نشده |
| E CI/CD و GitOps | انجام نشده |
| F برنامه‌ها و دیتابیس | انجام نشده |
| G Monitoring و Alerting | انجام نشده |
| H ELK و تحلیل Nginx | انجام نشده |
| I Backup و Restore | انجام نشده |
| J سرور عمومی و دامنه | وابسته به تهیه سرور و دامنه |

## ۷. گام بعدی پیشنهادی

1. بررسی و ثبت commit فعلی DNS.
2. نصب و تنظیم VPN روی lab، ترجیحاً WireGuard.
3. تست دسترسی VPN به DNS خصوصی.
4. طراحی PAM و تصمیم‌گیری درباره‌ی ابزار مناسب.
5. تهیه‌ی سرور Ubuntu قوی‌تر برای Kubernetes و سرویس‌های سنگین.

## ۸. محدودیت‌های آزمایشگاه فعلی

- VM فقط حدود 2 GiB RAM دارد.
- دیسک VM حدود 12 GiB است.
- دامنه‌ی عمومی و IP عمومی نداریم.
- ELK، Kubernetes چندنودی و PostgreSQL cluster واقعی برای این VM مناسب نیستند.
- این محیط برای یادگیری، automation و اثبات مفاهیم است؛ محیط production نیست.

## ۹. دستورات مهم

```bash
cd /Users/abolfazl/devops-lab

# وضعیت VM
multipass list

# اتصال Ansible
ansible ubuntu_lab -m ping

# اجرای بررسی سیستم
ansible-playbook playbooks/check-host.yml

# آماده‌سازی Ubuntu
ansible-playbook playbooks/prepare-ubuntu.yml

# ساخت viewer
ansible-playbook playbooks/create-viewer.yml

# مشاهده فایروال
ansible-playbook playbooks/firewall-baseline.yml

# فعال‌سازی فایروال
ansible-playbook playbooks/enable-firewall.yml

# تنظیم DNS خصوصی
ansible-playbook playbooks/private-dns.yml
```

## ۱۰. قواعد امنیتی

- رمز، private key و secret را داخل Git قرار ندهید.
- VM آزمایشگاهی را مستقیم روی اینترنت عمومی منتشر نکنید.
- قبل از تغییر SSH یا firewall همیشه مسیر دسترسی را آزمایش کنید.
- هر مرحله را با یک commit مستقل ذخیره کنید.
- Backup را فقط با تست restore معتبر بدانید.