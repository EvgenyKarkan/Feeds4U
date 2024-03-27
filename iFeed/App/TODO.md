6. ❌ Check caching, URLCache - investigate it.
       --- How to cache for SFSafariViewController, and load webpage if offline?
       --- Good read https://pspdfkit.com/blog/2020/downloading-large-files-with-urlsession/
       
7. ❌ Entering a feed validation on alertview
```
func isValidURL(urlString: String) -> Bool {
    if let url = NSURL(string: urlString), url.host != nil {
        return true
    }
    return false
}
```
8. ❌ Entering a search query validation on alertview

9. ❌ Licenses in Settings, package plus search API
   ⚠️ Settings Bundle
    https://github.com/nmdias/FeedKit/blob/master/LICENSE
    https://github.com/JuliusBahr/SimpleSimilarity/blob/master/LICENSE
    
    https://github.com/krimpedance/KRProgressHUD/blob/master/LICENSE
    https://github.com/krimpedance/KRActivityIndicatorView/blob/master/LICENSE
    
    https://github.com/DBeath/feedsearch/blob/master/LICENSE
    https://github.com/DBeath/feedsearch-crawler/blob/master/LICENSE
    
    https://feedsearch.dev

10. ❌ Localization 

As of my last update, here is a list of the top 20 countries by population:

1. **China**: Approximately 1.41 billion
2. **India**: Approximately 1.39 billion
3. **United States**: Approximately 331 million
4. **Indonesia**: Approximately 276 million
5. **Pakistan**: Approximately 243 million
6. **Brazil**: Approximately 214 million
7. **Nigeria**: Approximately 211 million
8. **Bangladesh**: Approximately 169 million
9. **Russia**: Approximately 146 million
10. **Mexico**: Approximately 129 million
11. **Japan**: Approximately 126 million
12. **Ethiopia**: Approximately 121 million
13. **Philippines**: Approximately 113 million
14. **Egypt**: Approximately 104 million
15. **Vietnam**: Approximately 98 million
16. **DR Congo**: Approximately 101 million
17. **Turkey**: Approximately 88 million
18. **Iran**: Approximately 86 million
19. **Germany**: Approximately 84 million
20. **Thailand**: Approximately 70 million

Please note that these populations are approximate and can vary based on different sources and methodologies used for counting.

✅Chinese Simplified: approximately 1.1 billion speakers
✅Spanish: approximately 460 million speakers
✅English: approximately 379 million speakers
✅Hindi: approximately 341 million speakers
✅Arabic: approximately 315 million speakers
✅French: approximately 274 million people
Portuguese: approximately 215 million speakers
✅Russian: approximately 155 million speakers
Japanese: approximately 125 million speakers
Indonesian
Hausa (Nigeria)
Bangla (India, Bangladesh)
Punjabi Gurmukhi: approximately 95 million speakers (India + Pakistan)
Oromo (Ethiopia)
✅ Ukrainian

11. ❌ Automate with Fastlane


/// All Strings

/// ENGLISH 
Oops...
OK
It's not possible to read this feed. Try again later or check the URL to make sure it's valid.
It looks like this feed already exists.\n Enter a different one to continue.
Add a new feed to get started
Enter a new feed
Cancel
Add
Provide a webpage URL to search for its feeds
Search
Error
Explore feeds
Add a new feed
Search works best when you enter more than one word.
There aren't any results that match your search
Cute kittens
The URL you entered doesn't seem to be valid
The %@ error has occurred while trying to access the service
A data decoding error has occurred

/// Chinese 
When choosing between Simplified and Traditional Chinese for your app localization, consider your target audience:

Mainland China and Singapore: Use Simplified Chinese for users in mainland China and Singapore.
Taiwan, Hong Kong, Macau, and Overseas Chinese Communities: Use Traditional Chinese for users in Taiwan, Hong Kong, Macau, and many overseas Chinese communities.

/// Chinese Simplified:

Oops...
哎呀...
OK
确定
It's not possible to read this feed. Try again later or check the URL to make sure it's valid.
无法读取此源。请稍后重试或检查 URL 以确保其有效。
It looks like this feed already exists.\n Enter a different one to continue.
看起来这个源已经存在。\n 输入另一个以继续。
Add a new feed to get started
添加新源以开始
Enter a new feed
输入新源
Cancel
取消
Add
添加
Provide a webpage URL to search for its feeds
提供网页 URL 以搜索其源
Search
搜索
Error
错误
Explore feeds
探索源
Add a new feed
添加新源
Search works best when you enter more than one word.
输入多个词时，搜索效果最佳。
There aren't any results that match your search
没有与您的搜索匹配的结果
Cute kittens
可爱的小猫
The URL you entered doesn't seem to be valid
您输入的 URL 似乎无效
The %@ error has occurred while trying to access the service
在尝试访问服务时发生了 %@ 错误
A data decoding error has occurred
发生了数据解码错误

/// HINDI

Here are the translations into Hindi:

Oops...
ओह...
OK
ठीक है
It's not possible to read this feed. Try again later or check the URL to make sure it's valid.
इस फ़ीड को पढ़ना संभव नहीं है। बाद में पुन: प्रयास करें या URL की जांच करें ताकि यह सही हो।
It looks like this feed already exists.\n Enter a different one to continue.
ऐसा लगता है कि यह फ़ीड पहले से मौजूद है।\n जारी रखने के लिए एक अलग दर्ज करें।
Add a new feed to get started
शुरू करने के लिए एक नया फ़ीड जोड़ें
Enter a new feed
नया फ़ीड दर्ज करें
Cancel
रद्द करें
Add
जोड़ें
Provide a webpage URL to search for its feeds
उसके फ़ीड्स के लिए एक वेबपेज URL प्रदान करें
Search
खोजें
Error
त्रुटि
Explore feeds
फ़ीड्स का अन्वेषण करें
Add a new feed
नया फ़ीड जोड़ें
Search works best when you enter more than one word.
जब आप एक से अधिक शब्द दर्ज करते हैं तो खोज सबसे अच्छी तरह से काम करती है।
There aren't any results that match your search
ऐसा कोई भी परिणाम नहीं है जो आपकी खोज से मेल खाता हो
Cute kittens
प्यारे बिल्लियाँ
The URL you entered doesn't seem to be valid
आपके द्वारा दर्ज URL मान्य नहीं लगता
The %@ error has occurred while trying to access the service
सेवा तक पहुँचने के दौरान %@ त्रुटि आई है
A data decoding error has occurred
डेटा डिकोडिंग में त्रुटि आ गई है

/// Arabic

Here are the translations into Arabic:

Oops...
عفوًا...
OK
حسنًا
It's not possible to read this feed. Try again later or check the URL to make sure it's valid.
لا يمكن قراءة هذا التغذية. حاول مرة أخرى في وقت لاحق أو تحقق من عنوان URL للتأكد من صحته.
It looks like this feed already exists.\n Enter a different one to continue.
يبدو أن هذه التغذية موجودة بالفعل.\n أدخل واحدة مختلفة للمتابعة.
Add a new feed to get started
أضف تغذية جديدة للبدء
Enter a new feed
أدخل تغذية جديدة
Cancel
إلغاء
Add
إضافة
Provide a webpage URL to search for its feeds
قدم عنوان URL لصفحة الويب للبحث عن تغذيتها
Search
بحث
Error
خطأ
Explore feeds
استكشاف التغذيات
Add a new feed
إضافة تغذية جديدة
Search works best when you enter more than one word.
يعمل البحث بشكل أفضل عند إدخال أكثر من كلمة واحدة.
There aren't any results that match your search
لا توجد نتائج تطابق بحثك
Cute kittens
قطط لطيفة
The URL you entered doesn't seem to be valid
العنوان URL الذي أدخلته لا يبدو صحيحًا
The %@ error has occurred while trying to access the service
حدث خطأ %@ أثناء محاولة الوصول إلى الخدمة
A data decoding error has occurred
حدث خطأ في فك تشفير البيانات

/// SPANISH
Ups...
Aceptar
No es posible leer este feed. Inténtalo de nuevo más tarde o verifica la URL para asegurarte de que sea válida.
Parece que este feed ya existe.\n Ingresa uno diferente para continuar.
Agregar un nuevo feed para comenzar
Ingresar un nuevo feed
Cancelar
Agregar
Proporciona una URL de página web para buscar sus feeds
Buscar
Error
Explorar feeds
Agregar un nuevo feed
La búsqueda funciona mejor cuando ingresas más de una palabra.
No hay resultados que coincidan con tu búsqueda
Lindos gatitos
La URL que ingresaste parece no ser válida
Ha ocurrido un error %@ al intentar acceder al servicio
Ha ocurrido un error al decodificar los datos

/// Russian

Here are the translations into Russian:

Oops...
Упс...
OK
ОК
It's not possible to read this feed. Try again later or check the URL to make sure it's valid.
Невозможно прочитать эту ленту. Попробуйте снова позже или проверьте URL, чтобы убедиться, что он правильный.
It looks like this feed already exists.\n Enter a different one to continue.
Похоже, эта лента уже существует.\n Введите другую, чтобы продолжить.
Add a new feed to get started
Добавьте новую ленту, чтобы начать
Enter a new feed
Введите новую ленту
Cancel
Отмена
Add
Добавить
Provide a webpage URL to search for its feeds
Укажите URL веб-страницы для поиска ее лент
Search
Поиск
Error
Ошибка
Explore feeds
Исследуйте ленты
Add a new feed
Добавить новую ленту
Search works best when you enter more than one word.
Поиск работает лучше, когда вы вводите более одного слова.
There aren't any results that match your search
Нет результатов, соответствующих вашему поиску
Cute kittens
Милые котята
The URL you entered doesn't seem to be valid
Введенный вами URL, кажется, недействителен
The %@ error has occurred while trying to access the service
Произошла ошибка %@ при попытке доступа к сервису
A data decoding error has occurred
Произошла ошибка декодирования данных

/// UKRAINIAN

Here are the translations into Ukrainian:

Oops...
Упс...
OK
ОК
It's not possible to read this feed. Try again later or check the URL to make sure it's valid.
Неможливо прочитати цю стрічку. Спробуйте ще раз пізніше або перевірте URL, щоб переконатися, що він є правильним.
It looks like this feed already exists.\n Enter a different one to continue.
Схоже, що ця стрічка вже існує.\n Введіть іншу, щоб продовжити.
Add a new feed to get started
Додайте нову стрічку, щоб розпочати
Enter a new feed
Введіть нову стрічку
Cancel
Скасувати
Add
Додати
Provide a webpage URL to search for its feeds
Надайте URL веб-сторінки для пошуку її стрічок
Search
Пошук
Error
Помилка
Explore feeds
Досліджуйте стрічки
Add a new feed
Додайте нову стрічку
Search works best when you enter more than one word.
Пошук працює краще, коли ви вводите більше одного слова.
There aren't any results that match your search
Немає результатів, які відповідають вашому запиту
Cute kittens
Милі кошенята
The URL you entered doesn't seem to be valid
Введений вами URL, схоже, що не є дійсним
The %@ error has occurred while trying to access the service
Виникла помилка %@ під час спроби доступу до служби
A data decoding error has occurred
Виникла помилка декодування даних


/// French 

Here are the translations into French:

OK
D'accord

It's not possible to read this feed. Try again later or check the URL to make sure it's valid.
Il n'est pas possible de lire ce flux. Réessayez plus tard ou vérifiez l'URL pour vous assurer qu'elle est valide.

It looks like this feed already exists.\n Enter a different one to continue.
Il semble que ce flux existe déjà.\n Entrez-en un autre pour continuer.

Add a new feed to get started
Ajoutez un nouveau flux pour commencer

Enter a new feed
Entrez un nouveau flux

Cancel
Annuler

Add
Ajouter

Provide a webpage URL to search for its feeds
Fournissez une URL de page Web pour rechercher ses flux

Search
Chercher

Error
Erreur

Explore feeds
Explorer les flux

Add a new feed
Ajouter un nouveau flux

Search works best when you enter more than one word.
La recherche fonctionne mieux lorsque vous saisissez plus d'un mot.

There aren't any results that match your search
Il n'y a aucun résultat correspondant à votre recherche

Cute kittens
Mignons chatons

The URL you entered doesn't seem to be valid
L'URL que vous avez saisie ne semble pas être valide

The %@ error has occurred while trying to access the service
L'erreur %@ s'est produite lors de la tentative d'accès au service

A data decoding error has occurred
Une erreur de décodage des données s'est produite



