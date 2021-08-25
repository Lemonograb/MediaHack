# MediaHack - Яндекс.Титры
 Приложение Яндекс.Титры для просмотра фильмов в оригинале, обучения английскому языку в удобном и интересном формате.
 Предоставляе сервис - компаньон для кинопоиска, позволяющий удобно смотреть фильмы в оригинале, работать с лексикой из фильмов и музыки.
 
## Запуск актуального сервера (Docker)
<code> sudo docker-compose build && sudo docker-compose up --detach app
Проксируем 8080 -> 80 по желанию
Прокидываем токен для переводчика, YA_TR_TOKEN

## Клиент
  Используем https://github.com/yonaskolb/XcodeGen для генерации проекта
  <code> sudo mkdir /usr/local/xcodegen && cp -r SettingPresets /usr/local/xcodegen
  В проекте добавляем схему:
  No scheme -> Manage schemes -> Autocreate schemas now -> MediaHack + MediaHack-TV
  Заменяем локалхост, если поднимали сервер в другом месте

### Используемый стек
  - Все на чистом Swift
  - Вебсокеты (нативное API из Foundation)
  - Combine
  - Xcodegen
  
## Сервер
  - Сервер написан на чистом swift(Vapor)
  - Для работы с вебсокетами используем библиотеку Vapor для ws
  - Yandex cloud (VPS, перевод)
  - Docker, nginx
