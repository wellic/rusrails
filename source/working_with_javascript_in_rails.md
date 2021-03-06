Работа с JavaScript в Rails
===========================

Это руководство раскрывает встроенный в Rails функционал Ajax/JavaScript (и даже чуть больше), который позволит вам с легкостью создать насыщенные и динамические приложения Ajax!

После прочтения этого руководства вы узнаете:

* Об основах Ajax.
* О ненавязчивом JavaScript.
* Как помогут встроенные хелперы Rails.
* Как обрабатывать Ajax на стороне сервера.
* О геме Turbolinks.

Введение в Ajax
---------------

Чтобы понять Ajax, нужно сперва понять, что обычно делает браузер.

Когда вы переходите на `http://localhost:3000` в своем браузере, браузер (ваш 'клиент') осуществляет запрос к серверу. Он парсит отклик, затем получает все связанные файлы ресурсов, такие как файлы JavaScript, таблицы стилей и изображения. Затем он собирает страницу. Если вы нажмете на ссылку, он сделает то же самое: получит страницу, получит файлы ресурсов, сложит их вместе, отобразит результаты. Это называется 'цикл запроса.'

JavaScript также может осуществлять запросы к серверу и парсить отклики. У него также есть возможность обновить информацию на странице. Объединив эти две силы, программист JavaScript может изготовить веб-страницу, обновляющую лишь части себя, без необходимости получения полных данных с сервера. Эту мощную технологию мы называем Ajax.

Rails поставляется по умолчанию с CoffeeScript, поэтому остальные примеры в этом руководстве будут на CoffeeScript. Все эти уроки, применимы и к чистому JavaScript.

К примеру, вот некоторый код CoffeeScript, осуществляющий запрос Ajax с использованием библиотеки jQuery:

```coffeescript
$.ajax(url: "/test").done (html) ->
  $("#results").append html
```

Этот код получает данные из "/test", а затем присоединяет результат к `div` с id `results`.

Rails предоставляет небольшую встроенную поддержку для создания веб-страниц с помощью такой техники. Вам редко придется писать такой код самим. Оставшаяся часть руководства покажет, как Rails может помочь создавать сайты схожим образом, но в основе лежит эта довольно простая техника.

Ненавязчивый JavaScript
-----------------------

Rails использует технику "ненавязчивый JavaScript" для управления присоединением JavaScript к DOM. Обычно он рассматривается как лучшая практика во фронтенд-сообществе, но иногда встречаются статьи, демонстрирующие иные способы.

Вот простейший способ написания JavaScript. Его называют 'встроенный JavaScript':

```html
<a href="#" onclick="this.style.backgroundColor='#990000'">Paint it red</a>
```

При нажатии, задний фон ссылки станет красным. Проблема в следующем: что будет, если у нас много JavaScript, который мы хотим запустить по щелчку?

```html
<a href="#" onclick="this.style.backgroundColor='#009900';this.style.color='#FFFFFF';">Paint it green</a>
```

Некрасиво, правда? Можно вытащить определение функции из обработчика щелчка, и перевести его в CoffeeScript:

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor
```

А затем на нашей странице:

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
```

Немного лучше, но как насчет нескольких ссылок, для которых нужен тот же эффект?

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
<a href="#" onclick="paintIt(this, '#009900', '#FFFFFF')">Paint it green</a>
<a href="#" onclick="paintIt(this, '#000099', '#FFFFFF')">Paint it blue</a>
```

Совсем не DRY, да? Это можно исправить, используя события. Мы добавим атрибут `data-*` нашим ссылкам, а затем привяжем обработчик на событие щелчка для каждой ссылки, имеющей этот атрибут:

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor

$ ->
  $("a[data-background-color]").click ->
    backgroundColor = $(this).data("background-color")
    textColor = $(this).data("text-color")
    paintIt(this, backgroundColor, textColor)
```

```html
<a href="#" data-background-color="#990000">Paint it red</a>
<a href="#" data-background-color="#009900" data-text-color="#FFFFFF">Paint it green</a>
<a href="#" data-background-color="#000099" data-text-color="#FFFFFF">Paint it blue</a>
```

Это называется 'ненавязчивым' JavaScript, так как мы больше не смешиваем JavaScript с HTML. Мы должным образом разделили ответственность, сделав будущие изменения простыми. Можно с легкостью добавить поведение для любой ссылки, добавив атрибут data. Можно пропустить весь наш JavaScript через минимайзер. Этот JavaScript можно подключить на каждой странице, что означает, что он будет загружен только при загружке первой страницы, затем будет кэширован для остальных страниц. Множество небольших преимуществ.

Команда Rails настойчиво рекомендует вам писать свой CoffeeScript (и JavaScript) в таком стиле, множество библиотек также соответствуют этому паттерну.

Встроенные хелперы
------------------

Rails предоставляет ряд вспомогательных методов для вьюх, написанных на Ruby, помогающих вам создавать HTML. Иногда хочется добавить немного Ajax к этим элементам, и Rails подсобит в таких случаях.

Так как JavaScript ненавязчив, "Ajax-хелперы" Rails фактически состоят из двух частей: часть JavaScript и часть Ruby.

[rails.js](https://github.com/rails/jquery-ujs/blob/master/src/rails.js) представляет часть для JavaScript, а хелперы вьюх на обычном Ruby добавляют подходящие теги в DOM. Затем CoffeeScript из rails.js смотрит на определенные атрибуты и добавляет соответствующие обработчики.

### form_for

[`form_for`](http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for) - это хелпер, помогающий писать формы. `form_for` принимает опцию `:remote`. Она работает следующим образом:

```erb
<%= form_for(@post, remote: true) do |f| %>
  ...
<% end %>
```

Это создаст следующий HTML:

```html
<form accept-charset="UTF-8" action="/posts" class="new_post" data-remote="true" id="new_post" method="post">
  ...
</form>
```

Обратите внимание на `data-remote='true'`. Теперь форма будет подтверждена с помощью Ajax вместо обычного браузерного механизма подтверждения.

Впрочем, вы не хотите просто сидеть с заполненной формой. Возможно, вы хотите что-то сделать при успешном подтверждении. Для этого привяжите что-нибудь к событию `ajax:success`. При неудаче используйте `ajax:error`. Посмотрите:

```coffeescript
$(document).ready ->
  $("#new_post").on("ajax:success", (e, data, status, xhr) ->
    $("#new_post").append xhr.responseText
  ).bind "ajax:error", (e, xhr, status, error) ->
    $("#new_post").append "<p>ERROR</p>"
```

Очевидно, что хочется чего-то большего, но ведь это только начало.

### form_tag

[`form_tag`](http://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-form_tag) очень похож на `form_for`. У него есть опция `:remote`, которую используют так:

```erb
<%= form_tag('/posts', remote: true) %>
```

Все остальное такое же, как и для `form_for`.

### link_to

[`link_to`](http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to) - это хелпер, помогающий создавать ссылки. У него есть опция `:remote`, которую используют следующим образом:

```erb
<%= link_to "a post", @post, remote: true %>
```

что создаст

```html
<a href="/posts/1" data-remote="true">a post</a>
```

Можно привязаться к тем же событиям Ajax, что и в `form_for`. Вот пример. Предположим, имеется список публикаций, которые можно удалить одним щелчком. Нужно создать некоторый HTML, например так:

```erb
<%= link_to "Delete post", @post, remote: true, method: :delete %>
```

и написать некоторый CoffeeScript:

```coffeescript
$ ->
  $("a[data-remote]").on "ajax:success", (e, data, status, xhr) ->
    alert "The post was deleted."
```

### button_to

[`button_to`](http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to) - это хелпер, помогающий создавать кнопки. У него есть опция `:remote`, которая вызывается так:

```erb
<%= button_to "A post", @post, remote: true %>
```

это создаст

```html
<form action="/posts/1" class="button_to" data-remote="true" method="post">
  <div><input type="submit" value="A post"></div>
</form>
```

Поскольку это всего лишь `<form>`, применима вся информация, что и для `form_for`.

Со стороны сервера
------------------

Ajax - это не только сторона клиента, необходимо также поработать на стороне сервера, чтобы добавить его поддержку. Часто людям нравится, когда на их запросы Ajax возвращается JSON, а не HTML. Давайте обсудим, что необходимо для этого сделать.

### Простой пример

Представьте, что у вас есть ряд пользователей, которых нужно отобразить, и предоставить форму на той же странице для создания нового пользователя. Экшн index вашего контроллера выглядит так:

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    @user = User.new
  end
  # ...
```

Вьюха для index (`app/views/users/index.html.erb`) содержит:

```erb
<b>Users</b>

<ul id="users">
<% @users.each do |user| %>
  <%= render user %>
<% end %>
</ul>

<br>

<%= form_for(@user, remote: true) do |f| %>
  <%= f.label :name %><br>
  <%= f.text_field :name %>
  <%= f.submit %>
<% end %>
```

Партиал `app/views/users/_user.html.erb` содержит следующее:

```erb
<li><%= user.name %></li>
```

Верхняя часть индексной страницы отображает пользователей. Нижняя часть представляет форму для создания нового пользователя.

Нижняя форма вызовет экшн create в контроллере Users. Так как у формы опция remote установлена true, запрос будет передан через post к контроллеру
users как запрос Ajax, ожидая JavaScript. Чтобы обслужить этот запрос, экшн create вашего контроллера должен выглядеть так:

```ruby
  # app/controllers/users_controller.rb
  # ......
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.js   {}
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
```

Обратите внимание на format.js в блоке `respond_to`; это позволяет контроллеру откликаться на ваши запросы Ajax. Далее необходим соответствующий файл вьюхи `app/views/users/create.js.erb`, создающий фактический код JavaScript, который будет отослан и исполнен на стороне клиента.

```erb
$("<%= escape_javascript(render @user) %>").appendTo("#users");
```

Turbolinks
----------

Rails 4 поставляется с [гемом Turbolinks](https://github.com/rails/turbolinks). Этот гем использует Ajax для ускорения рендеринга страницы во большинстве приложений.

### Как работает Turbolinks

Turbolinks добавляет обработчик щелчков на всех `<a>` на странице. Если ваш браузер поддерживает [PushState](https://developer.mozilla.org/en-US/docs/DOM/Manipulating_the_browser_history#The_pushState(\).C2.A0method),
Turbolinks сделает запрос Ajax для страницы, распарсит отклик и заменит полностью `<body>` страницы на `<body>` отклика. Затем он использует PushState для изменения URL на правильный, сохраняя семантику для обновления и предоставляя красивые URL.

Единственное, что необходимо сделать для включения Turbolinks - это добавить его в свой Gemfile, и поместить `//= require turbolinks` в свой манифест CoffeeScript, обычно это `app/assets/javascripts/application.js`.

Если хотите отключить Turbolinks для определенных ссылок, добавьте атрибут `data-no-turbolink` к тегу:

```html
<a href="..." data-no-turbolink>No turbolinks here</a>.
```

### События изменения страницы

При написании CoffeeScript, часто необходимо что-то сделать при загрузке страницы. С помощью jQuery вы писали что-то вроде этого:

```coffeescript
$(document).ready ->
  alert "page has loaded!"
```

Однако, поскольку Turbolinks переопределяет обычный процесс загрузки страницы, событие, на которое полагается вышеуказанный код, не произойдет. Если у вас есть подобный код, следует его изменить на следующий:

```coffeescript
$(document).on "page:change", ->
  alert "page has loaded!"
```

Подробности, включая другие возможные события, можно посмотреть [в Turbolinks README](https://github.com/rails/turbolinks/blob/master/README.md).

Другие ресурсы
--------------

Вот несколько полезных ссылок, которые позволят вам узнать больше:

* [вики jquery-ujs](https://github.com/rails/jquery-ujs/wiki)
* [список статей по jquery-ujs](https://github.com/rails/jquery-ujs/wiki/External-articles)
* [Rails 3 Remote Links and Forms: A Definitive Guide](http://www.alfajango.com/blog/rails-3-remote-links-and-forms/)
* [Railscasts: Unobtrusive JavaScript](http://railscasts.com/episodes/205-unobtrusive-javascript)
* [Railscasts: Turbolinks](http://railscasts.com/episodes/390-turbolinks)
