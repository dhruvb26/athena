## Athena

Official repository for Athena. 

### Setup
Create a ```Debug.xcconfig``` file in Athena📁 and add the following keys

```
OPENAI_API_KEY=
GEMINI_API_KEY=
```

### Linter
Install ```swiftformat``` from Homebrew and run the following command from the root folder
```
swiftformat . --swiftversion 6
```

### Roadmap
- [x] Add swift-log to all files
- [x] Use async/await instead of completion handlers
- [x] Remove unnecessary completion handlers
- [x] Add quiz item fetching and notification scheduling logic
- [ ] Use FirebaseMessaging for push notifications
- [ ] Create flows for every major action