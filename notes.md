# AI Study Buddy

Turn your notes into flashcards and quizzes with AI, then remember them with spaced repetition.

Paste text, pick a PDF or snap a photo of your notes. Gemini writes the flashcards and quiz questions, and a spaced-repetition scheduler (SM-2) tells you what to review each day.

<!-- Add 3-4 screenshots here, for example:
<p>
  <img src="docs/screenshots/home.png" width="220" />
  <img src="docs/screenshots/review.png" width="220" />
  <img src="docs/screenshots/quiz.png" width="220" />
</p>
-->

## Features

**Create decks from your notes**
- Paste text, pick a PDF (text is extracted on the device), or take or choose a photo (text is read with OCR).
- Choose how many flashcards and quiz questions to generate.

**Study**
- Flip-card review with Again / Hard / Good / Easy ratings.
- Review the cards due in one deck, everything due across all decks, or practise a whole deck without changing its schedule.
- Multiple-choice quiz with explanations, a score, and a list of questions to revisit.
- Add, edit and delete your own cards.

**Stay on track**
- Daily goal, review streak and a 7-day activity chart on the home screen.
- Per-deck stats: cards, due, mastered and accuracy.
- Sort decks by newest, most due or A to Z. Rename, reset progress or delete decks.

**Made to be comfortable**
- Light, dark or automatic theme. Fonts chosen for readability.
- Saved decks and reviews work offline. Only generating a deck needs the internet.

## Tech stack

| Area | Choice |
| --- | --- |
| Framework | Flutter (Dart), Material 3 |
| State management | Riverpod |
| Navigation | go_router |
| Local storage | Hive |
| AI | Google Gemini (`google_generative_ai`) |
| PDF text | Syncfusion Flutter PDF |
| OCR | Google ML Kit text recognition |
| Pickers | file_picker, image_picker |
| Fonts | google_fonts (Atkinson Hyperlegible, Lexend) |

## How it works

1. **Generate:** your text (up to 15,000 characters) is sent to Gemini with a prompt that asks for flashcards and quiz questions as JSON. The response is validated and cleaned before it is saved.
2. **Schedule:** each card follows the SM-2 algorithm. A card you fail comes back the next day. A card you pass comes back after 1 day, then 6 days, then at growing intervals based on its ease factor.
3. **Store:** decks, cards and daily review counts are saved on the device with Hive. Nothing is uploaded except the text you choose to generate from.

## Project structure

```
lib/
├── main.dart            App start-up: .env, Hive, providers
├── app.dart             MaterialApp.router and theme mode
├── core/                Theme, colours, constants, router, utils
├── data/
│   ├── models/          StudyDeck, Flashcard, QuizQuestion (Hive)
│   ├── repositories/    DeckRepository
│   └── services/        Gemini, storage, PDF, OCR, Riverpod providers
├── domain/srs/          SM-2 algorithm
└── features/            splash, home, create_deck, deck_detail, review, settings
```

## Getting started

### Requirements
- Flutter (this project pins its version with [FVM](https://fvm.app); `.fvmrc` is included)
- JDK 17 for Android builds
- Android Studio (Android) or Xcode and CocoaPods (iOS)
- A Gemini API key from [Google AI Studio](https://aistudio.google.com)

### Setup
```bash
git clone <your-repo-url>
cd ai_study_buddy

fvm install            # installs the pinned Flutter version
fvm flutter pub get
```

Create a `.env` file in the project root (it is git-ignored, so never commit it):

```
GEMINI_API_KEY=your_key_here
```

Run the app:

```bash
fvm flutter run
```

If you change a Hive model, regenerate the adapters:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

### Build an APK
```bash
fvm flutter build apk --release
```
The file is created at `build/app/outputs/flutter-apk/app-release.apk`.

## Troubleshooting

- **"Gemini API key missing":** create the `.env` file shown above and restart the app. Saved decks and reviews work without it.
- **Build fails with `Java heap space`:** add this to `android/gradle.properties`, then run `cd android && ./gradlew --stop`:
  ```
  org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
  ```
  Use `-Xmx4G` on a machine with 8 GB of RAM.
- **Gradle or Java version errors:** use JDK 17 and set it per machine in `~/.gradle/gradle.properties` (`org.gradle.java.home=...`), not in the project file.
- **Scanned PDFs return no text:** PDF extraction reads embedded text only. Take a photo of the page instead and use the OCR option.

## Security note

The Gemini API key is read from a local `.env` file. If you publish an APK that includes the key, anyone can extract it. For a public release, call Gemini through a small backend proxy, or use a restricted key with a low quota and a billing alert.

## Roadmap

- [ ] Backend proxy for the AI key
- [ ] Import and export decks as JSON
- [ ] OCR for scanned PDFs
- [ ] Study reminders for due cards
- [ ] Unit tests for the scheduler, streaks and AI response parsing

## Author

**Junaid Akram**: Flutter developer. [GitHub](https://github.com/Whoami-jj) · [LinkedIn](https://linkedin.com/in/junaid-akram-1873a11a9/)

## License

Choose a licence (for example MIT) and add a `LICENSE` file, or delete this section if the project is private.