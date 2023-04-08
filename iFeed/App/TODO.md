1. ✅ FeedSearchService
2. ✅ FeedSearchDTO
3. ❌ UX to support `Search for Feeds` 
     (✅context menu, 
      ✅additional alert with textfield, 
      ✅network call, 
      modal screen with results, 
      alert if error, 
      on modal screen in each UI component add Add Feed butto, 
      perform a call, 
      reload feed list screen on appear)
4. ❌ Delete force unwrap in `feedForIndexPath`

5. ❌ Check caching, URLCache - investigate it.
       --- How to cache for SFSafariViewController, and load webpage if offline?
       --- Good read https://pspdfkit.com/blog/2020/downloading-large-files-with-urlsession/
       
6. Localization 

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

7. Entering a feed validation on alertview

func isValidURL(urlString: String) -> Bool {
    if let url = NSURL(string: urlString), url.host != nil {
        return true
    }
    return false
}

8. Licenses in Settings, package plus search API
    https://github.com/nmdias/FeedKit/blob/master/LICENSE
    https://github.com/JuliusBahr/SimpleSimilarity/blob/master/LICENSE
    
    Which Python package it uses ??
    https://feedsearch.dev
    https://github.com/DBeath/feedsearch/blob/master/LICENSE ??
    https://github.com/DBeath/feedsearch-crawler ??
