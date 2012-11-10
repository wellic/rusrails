# Обсерверы

Обсерверы похожи на колбэки, но с важными отличиями. В то время как колбэки внедряют в модель свой код, непосредственно не связанный с нею, обсерверы позволяют добавить ту же функциональность, без изменения кода модели. Например, можно утверждать, что модель `User` не должна включать код для рассылки писем с подтверждением регистрации. Всякий раз, когда используются колбэки с кодом, прямо не связанным с моделью, возможно, Вам захочется вместо них создать обсервер.

### Создание обсерверов

Например, рассмотрим модель `User`, в которой хотим отправлять электронное письмо всякий раз, когда создается новый пользователь. Так как рассылка писем непосредственно не связана с целями нашей модели, создадим обсервер, содержащий код, реализующий эту функциональность.

```bash
$ rails generate observer User
```

генерирует `app/models/user_observer.rb`, содержащий класс обсервера `UserObserver`:

```ruby
class UserObserver < ActiveRecord::Observer
end
```

Теперь можно добавить методы, вызываемые в нужных случаях:

```ruby
class UserObserver < ActiveRecord::Observer
  def after_create(model)
    # код для рассылки подтверждений email...
  end
end
```

Как в случае с классами колбэков, методы обсервера получают рассматриваемую модель как параметр.

### Регистрация обсерверов

По соглашению, обсерверы располагаются внутри директории `app/models` и регистрируются в вашем приложении в файле `config/environment.rb`. Например, `UserObserver` будет сохранен как `app/models/user_observer.rb` и зарегистрирован в `config/environment.rb` таким образом:

```ruby
# Activate observers that should always be running.
config.active_record.observers = :user_observer
```

Естественно, настройки в `config/environments` имеют преимущество перед `config/environment.rb`. Поэтому, если вы предпочитаете не запускать обсервер для всех сред, можете его просто зарегистрировать для определенной среды.

### Совместное использование обсерверов

По умолчанию Rails просто убирает "Observer" из имени обсервера для поиска модели, которую он должен рассматривать. Однако, обсерверы также могут быть использованы для добавления обращения более чем к одной модели, это возможно, если явно определить модели, который должен рассматривать обсервер.

```ruby
class MailerObserver < ActiveRecord::Observer
  observe :registration, :user

  def after_create(model)
    # code to send confirmation email...
  end
end
```

В этом примере метод `after_create` будет вызван всякий раз, когда будет создан `Registration` или `User`. Отметьте, что этот новый `MailerObserver` также должен быть зарегистрирован в `config/environment.rb`, чтобы вступил в силу.

```ruby
# Activate observers that should always be running.
config.active_record.observers = :mailer_observer
```