# Дипломный практикум в Yandex.Cloud
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:


### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
2. Подготовьте [backend](https://developer.hashicorp.com/terraform/language/backend) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)
3. Создайте конфигурацию Terrafrom, используя созданный бакет ранее как бекенд для хранения стейт файла. Конфигурации Terraform для создания сервисного аккаунта и бакета и основной инфраструктуры следует сохранить в разных папках.
4. Создайте VPC с подсетями в разных зонах доступности.
5. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
6. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://developer.hashicorp.com/terraform/language/backend) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий, стейт основной конфигурации сохраняется в бакете или Terraform Cloud
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

### Деплой инфраструктуры в terraform pipeline

1. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ на 80 порту к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ на 80 порту к тестовому приложению.
5. Atlantis или terraform cloud или ci/cd-terraform
---
### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---
## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)

---

# Решение

## Предисловие:

Стремился к оптимизации и автоматизации некоторых действий в проекте (по возможнсти). ~На 3 этапе проект собрался полностью повторно с нуля.~ Сделал почти весь проект и получилось что больше прощупал сначала всё (У меня плохо выходит что-то нагруженное править, проще с нуля переделать все для меня. Это, наверное, плохо), чем сделал, по итогу на базе того что прощупал сделал новую директорию и там полностью уже собрал новый проект учитывая черновой вариант первых двух наработок. Сейчас сделал единую папку secret содержащую некоторые переменные (естественно они в гит не попали), ключи (ssh, токен, id сервисных аккаунтов) и т.п. обращение к которым повторялось по мере разрабокти проекта поэтапно (файлы main в bootstrap, infra, k8s). Сделал больше для эстетической красоты проекта для себя, не нравилось создавать в каждой папке эти "переменные". Чуть оптимальнее разбросал файлы по директориям.

---

## Этап 1. Bootstrap (хранилище состояния Terraform)
- Создал сервисный аккаунт для Terraform и сгенерировал S3-ключи (sa-bootstrap ак использовал только для старта).
- Поднял S3-бакет `marchenko-final-tfstate` в Object Storage под Terraform state.
- Выдал IAM-права на бакет. Теперь `terraform apply/destroy` идут без ручных шагов, стейт хранится централизованно.
---
![Бакет](https://github.com/Takarigua/marchenko-final/blob/ef7fa82723e9eee86ec501ed363cf479e89da05b/screen/%D0%91%D0%B0%D0%BA%D0%B5%D1%82.png)
---
![Сервисные](https://github.com/Takarigua/marchenko-final/blob/bdc9b94a8895b025838890862bbf76bfd1afa017/screen/%D0%A1%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BD%D1%8B%D0%B5.png)

---

## Этап 2. Базовая инфраструктура (infra)
- Создал VPC и три подсети в зонах `ru-central1-a/b/d`.
- Настроил security group с базовыми правилами (22/80/443/6443 + полный egress).
- Состояние Terraform вынес в Object Storage (S3 backend). Зафиксировал outputs: `network_id`, `subnet_ids[]`, `security_group_id`.
---
![Сеть](https://github.com/Takarigua/marchenko-final/blob/5e0d14346e77756d6ce9721a6aaa10edba6e1650/screen/%D0%A1%D0%B5%D1%82%D1%8C.png)
---
![ГруппыБезопасности](https://github.com/Takarigua/marchenko-final/blob/5e0d14346e77756d6ce9721a6aaa10edba6e1650/screen/%D0%93%D1%83%D1%80%D0%BF%D0%BF%D1%8B%D0%91%D0%B5%D0%B7%D0%BE%D0%BF%D0%B0%D1%81%D0%BD%D0%BE%D1%81%D1%82%D0%B8.png)

---

## Этап 3. Kubernetes на своих ВМ (self-hosted)
- Поднял 3 ВМ (1 master + 2 worker) в разных зонах (`a/b/d`) через Terraform.
  Все ноды **preemptible**, **20% vCPU**, диски 20 ГБ — эконом-профиль.
- Автоматически сгенерировал Ansible-инвентарь для Kubespray (использую `access_ip` = приватный адрес). После дестроя/аплая он сам затягивает адреса в инвентарь.
- Развернул кластер через Kubespray (containerd, Calico, CoreDNS, etcd/kubeadm).
- Получил kubeconfig для локального доступа (сертификат apiserver включает публичный IP мастера).
- Проверка:
  - kubectl get nodes -o wide
  - kubectl get pods -A
---
![ВМ](https://github.com/Takarigua/marchenko-final/blob/66221b2aa582b4dbfc60063867c0c6641cbbd772/screen/%D0%92%D0%9C.png)
---
![ансибл](https://github.com/Takarigua/marchenko-final/blob/1949a314f8341589e0ec9f07921e0f3477938572/screen/Ansible.png)
---
![поды](https://github.com/Takarigua/marchenko-final/blob/1949a314f8341589e0ec9f07921e0f3477938572/screen/%D0%9F%D0%BE%D0%B4%D1%8B.png)

---

## Этап 4: Ingress + Мониторинг + Тестовое приложение
- Поставил ingress-nginx в k8s как DaemonSet с hostNetwork (экономный вариант без внешнего балансировщика). В итоге 80/443 слушаются на нодах, доступ извне есть.
- Развернул стек мониторинга через Helm-чарт kube-prometheus-stack (Prometheus, Alertmanager, Grafana). Grafana доступна по [https://grafana.<MASTER_IP>.nip.io](https://grafana.51.250.73.216.nip.io) (первичный логин/пароль: admin/admin).
- Задеплоил простое тестовое приложение на nginx, которое отдаёт статическую страницу, доступ по [http://app.<MASTER_IP>.nip.io](http://app.51.250.73.216.nip.io/).
---
![Кубконфиг](https://github.com/Takarigua/marchenko-final/blob/c0efd00c6c958b271a1e9fd97b3bff553f01da83/screen/%D0%9A%D1%83%D0%B1%D0%BA%D0%BE%D0%BD%D1%84%D0%B8%D0%B3.png)
---
![Ингресс](https://github.com/Takarigua/marchenko-final/blob/c0efd00c6c958b271a1e9fd97b3bff553f01da83/screen/%D0%98%D0%BD%D0%B3%D1%80%D0%B5%D1%81%D1%81.png)
---
![МониторингСтек](https://github.com/Takarigua/marchenko-final/blob/c0efd00c6c958b271a1e9fd97b3bff553f01da83/screen/%D0%9C%D0%BE%D0%BD%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D0%BD%D0%B3%D0%A1%D1%82%D0%B5%D0%BA.png)
---
![Тестприложение](https://github.com/Takarigua/marchenko-final/blob/c0efd00c6c958b271a1e9fd97b3bff553f01da83/screen/%D1%82%D0%B5%D1%81%D1%82-%D0%BF%D1%80%D0%B8%D0%BB%D0%BE%D0%B6%D0%B5%D0%BD%D0%B8%D0%B5.png)
---
![Графана](https://github.com/Takarigua/marchenko-final/blob/c0efd00c6c958b271a1e9fd97b3bff553f01da83/screen/%D0%93%D1%80%D0%B0%D1%84%D0%B0%D0%BD%D0%B0.png)
---
![Апп](https://github.com/Takarigua/marchenko-final/blob/c0efd00c6c958b271a1e9fd97b3bff553f01da83/screen/%D0%90%D0%BF%D0%BF.png)

---

## Этап 5. CI/CD и выкладка демо-сайта

- Сделал простой статический сайт (index.html) и добавил свою картинку в screen/hero.png.
- Написал Dockerfile на базе nginx:stable-alpine: копирую страницу и папку screen/ в образ.
- Собрал и выложил образ в Docker Hub: takarigua/marchenko-final-web.
- Настроил GitHub Actions (.github/workflows/docker-cicd.yml): при пуше в main — логинится в Docker Hub, билдит, пушит образ с тегом SHA и обновляет образ в деплойменте app/web.
- В Kubernetes использую Ingress NGINX (hostNetwork + nip.io), сервис app/web доступен по адресу: [http://app.<MASTER_IP>.nip.io/](http://app.51.250.73.216.nip.io/)
- Проверил, что CD отрабатывает: меняю index.html → пуш в main → в Actions зелёны
---
![Экшен](https://github.com/Takarigua/marchenko-final/blob/7b483129257b86170a45607703755e398addfcaa/screen/%D0%AD%D0%BA%D1%88%D0%B5%D0%BD.png)
---
![Докерхаб](https://github.com/Takarigua/marchenko-final/blob/7b483129257b86170a45607703755e398addfcaa/screen/%D0%94%D0%BE%D0%BA%D0%B5%D1%80%D1%85%D0%B0%D0%B1.png)
---
![Кластер2](https://github.com/Takarigua/marchenko-final/blob/7b483129257b86170a45607703755e398addfcaa/screen/%D0%9A%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%802.png)
---
![Апп2](https://github.com/Takarigua/marchenko-final/blob/d3fdf54b697e747f30cbdb1e80a815ea3d7bd54f/screen/%D0%90%D0%BF%D0%BF2.png)
