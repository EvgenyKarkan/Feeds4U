# SimpleSimilarity
SimpleSimilarity is an easy to use framework for semantic text search.

## Features
- Text corpus creation
- Textual search
- Algorithms for string processing that can be used in other applications
- Both corpus creation and textual search run on background queues. Your UI never locks up.

## Usage
First you have to create a text corpus. When the corpus is filled you can run queries against it.
These methods are part of the MatchingEngine class.

### Corpus creation
The text corpus consists of a (large) number of TextualData structs. The TextualData struct is the text plus some metadata.
You create TextualData instances and pass them to the Matching engine:

```
let textualData = allFeedItems.map { (feedItem) -> TextualData in
return TextualData(inputString: feedItem.title, origin: nil, originObject: feedItem)
}

matchingEngine.fillMatchingEngine(with: textualData, onlyRemoveFrequentStopwords: true, completion: completion)
```

As noted before the creation of the text corpus happens on a background thread, so you need to pass in a completion block to be notfied when the corpus creation is done.

### Textual search
After the corpus has been created you can query it.
SimpleSimilarity is not necessarily optimized for short queries or short entries in the text corpus. The query should contain at least 2 words. The entries in the text corpus should be sentences.

For textual search you have multiple options:

- Finding the best result
- Finding results better than a threshould

```
try? matchingEngine.result(betterThan: 0.005, for: query, resultsFound: resultsFound)
```

resultsFound is again a completion block that passes in the results found.

So as you can see the API is really simple and easy to use.

## Performance
Creating a text corpus with 15000 entries takes around 20 seconds on an iPhone 6S.

## Integration into your app
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Limitations
- The framework targets iOS at the moment but could be easily extended to run on mac OS
- SimpleSimilarity works best with Latin scripts at the moment. It would be great to get some feedback on the efficiency with i.e. Asian languages or Arabic.

## Contributions
Your contributions are most welcome.
