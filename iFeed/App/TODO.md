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

Mandarin Chinese: approximately 1.1 billion speakers
Spanish: approximately 460 million speakers
English: approximately 379 million speakers
Hindi: approximately 341 million speakers
Arabic: approximately 315 million speakers
Portuguese: approximately 215 million speakers
Bengali: approximately 205 million speakers
Russian: approximately 155 million speakers
Japanese: approximately 125 million speakers
Punjabi: approximately 95 million speakers

"Enter a new feed" translate it to all languages you listed before

Mandarin Chinese: 输入新源 (Shūrù xīn yuán)
Spanish: Ingresar un nuevo feed
English: Enter a new feed
Hindi: एक नया फ़ीड दर्ज करें (Ek nayā fīḍ darj karen)
Arabic: أدخل خلاصة جديدة (Adkhil khulasa jadida)
Portuguese: Inserir um novo feed
Bengali: একটি নতুন ফিড লিখুন (Ekṭi natun phiḍ likhun)
Russian: Введите новостную ленту (Vvedite novostnuyu lentu)
Japanese: 新しいフィードを入力してください (Atarashii fīdo o nyūryoku shite kudasai)
Punjabi: ਇੱਕ ਨਵਾਂ ਫੀਡ ਦਾਖਲ ਕਰੋ (Ikk navāṃ fīḍ dākhil karo)

11. ❌ Automate with Fastlane
