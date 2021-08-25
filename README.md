# MediaHack
## Запуск актуального сервера (Docker)
<code> sudo docker-compose build && sudo docker-compose up --detach app

Проксируем 8080 -> 80 по желанию

## Клиент
Используем https://github.com/yonaskolb/XcodeGen для генерации проекта
<code> sudo mkdir /usr/local/xcodegen && cp -r SettingPresets /usr/local/xcodegen
В проекте добавляем схему:
No scheme -> Manage schemes -> Autocreate schemas now -> MediaHack + MediaHack-TV
  
## Используемый стек
- Все на чистом Swift
- Yandex cloud (VPS, перевод)
- Вебсокеты (нативное API из Foundation)
- Docker, nginx, Vapor
