# Травицкий Сергей
#  Дипломная работа по профессии «Системный администратор»

### Доступ к инфраструктуре: 
#### **Балансировщик: http://51.250.44.151/**  
#### **kibana: http://158.160.187.43:5601/**  
#### **zbbix: http://158.160.147.241/zabbix  Логин: Admin  Пароль: zabbix**  
#### **grafana http://158.160.147.241:3000  Логин: diplom  Пароль: diplom**  
 
Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---

<details>
<summary>ПОСТАВЛЕННАЯ ЗАДАЧА</summary>  

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  - для этого достаточно при создании ВМ указать name=example, hostname=examle !! 

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.

Настройка балансировщика:

1. Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

2. Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

3. Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

4. Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

Исходящий доступ в интернет для ВМ внутреннего контура через [NAT-шлюз](https://yandex.cloud/ru/docs/vpc/operations/create-nat-gateway).

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)

</details>

---

## **ВЫПОЛНЕНИЕ ДИПЛОМНОЙ РАБОТЫ**

[files](https://github.com/travickiy67/Diplom1/tree/main/files/filles) 
<details>
<summary>ПОДНЯТИЕ ИНФРАСТРУКТУРЫ</summary>  

## Создано шесть машин. Доступ к машинам возможен по ssh через бастион. Все програмное обеспечение устанавливается через ansible с использованием прокси команды. Ip адреса при при установке инфраструктуры и конфигурационных файлах не используются, используется fqdn имена виртуальных машин. Токен не используется, используется authorized_key.json. cloud_id и folder_id через переменную. Открыты только необходимые порты. Программы на машины установленны с помощью ansible (roles). установленно все что требовалось, дополнителен logstach и grafana.
  
*Создаем инфраструктуру используя terraform, meta даннуе не отображаются в терминале*  

![img](https://github.com/travickiy67/Diplom1/blob/main/img/terraform.png)
---

*Установка завершена*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/terraform2.png)
---

*Проверяем доступность хостов и устанавливаем  программы, используя ansible*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/ansible-ping.png)
---

*Установка без ошибок*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/ansible-install.png)
---

*Создано 6 машин*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/virtual-mashin.png)
---

*Балансировщик*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/nginx-balancer.png)
---

*Целевые группы*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/ngx-target-group.png)
---

*Группы бэкендов путь /*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/nginx-backend-group.png)
---

*Группы безопасности*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/sg.png)
---

*Роутер*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/nginx-router.png)
---

*Расписание снимков дисков*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/virtual-mashin1.png)
---

*Снимки дисков*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/snapchot.png)
---
*Диски*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/hdd.png)
---

*Карта сети*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/map_net.png)
---
*Карта балансировки*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/mashin/nginx-balancer1.png)
---

</details>
 

<details>
<summary>Работа сайта</summary>

*Проверка балансировки через curl*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/curl-web.png)
---

*Проверка WEB*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/web/web1.png)
---

![img](https://github.com/travickiy67/Diplom1/blob/main/img/web/web2.png)
---

</details>

<details>
<summary>ЛОГИРОВАНИЕ</summary> 

*Смотрим логи в kibana*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/logs/logs1.png)  
---

![img](https://github.com/travickiy67/Diplom1/blob/main/img/logs/logs2.png)
---

*Дашборд, активные соединения*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/logs/logs3.png)
---

</details> 

<details>
<summary>МОНИТОРИНГ ZABBIX</summary>

*Проверка подключения хостов. На мониторинг подключены все хосты*  

![img](https://github.com/travickiy67/Diplom1/blob/main/img/zabbix/zabbix1.png)
---

*Данные поступают со всех хостов, в том числе с web серверов*  

![img](https://github.com/travickiy67/Diplom1/blob/main/img/zabbix/zabbix3.png)  
---

*Дефолтовый дашборд*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/zabbix/default.png)  
---

*Графики мониторинга web серверов, количество активных соединений, время отклика, количество соединений за секунду, количество памяти занимающей сервером*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/zabbix/zabbix2.png)  
---

*Графики мениторинга kibana* 

![img](https://github.com/travickiy67/Diplom1/blob/main/img/zabbix/kibana.png)   
---

*Графики мониторинга elasticsearch*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/zabbix/elastic.png)  
---

*Графики мониторинга bastion*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/zabbix/bastion.png)
---
 
*Графики мониторинга zabbix-server*  

![img](https://github.com/travickiy67/Diplom1/blob/main/img/zabbix/zabbix_serber.png)  
---

*dashboard.list*  

![img](https://github.com/travickiy67/Diplom1/blob/main/img/zabbix/dashboards.png)
---

</details>

<details>
<summary>МОНИТОРИНГ GRAFANA</summary>

*Плагин корректно установился и zabbix появился в списке*

![img]()  

*Подключаем базу zabbix*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/grafana/datasource.png)  

*Grafana получает информацию от zabbix, и обнаруживает группы хостов подключонных к zabbix*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/grafana/datasource1.png)

*Визуализация количества подключений (сгенерировал дополнительно через curl), время отклика, ожидание подключения, количество плдключений в секунду*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/grafana/nginx.png)  

*Визуализация общих показателей серверов; процессор, память, диск, скорость передачи данных*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/grafana/nginx1.png)

*Визуализация показателей  остальных хостов*

![img](https://github.com/travickiy67/Diplom1/blob/main/img/grafana/hosts_all.png)

 
</detals>

