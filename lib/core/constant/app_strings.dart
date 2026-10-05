class AppStrings {
  AppStrings._();

  static const appName = 'AI Study Buddy';
  static const tagline = 'Turn your notes into knowledge';

  // Home
  static const myDecks = 'My Decks';
  static const createDeck = 'Create Deck';
  static const noDecks = 'No decks yet';
  static const noDecksSub = 'Tap + to create your first study deck';

  // Create
  static const newDeck = 'New Study Deck';
  static const sourceType = 'Where are your notes?';
  static const pasteText = 'Paste Text';
  static const pickPdf = 'Pick PDF';
  static const takePhoto = 'Take Photo';
  static const deckTitle = 'Deck Title';
  static const generate = 'Generate with AI';
  static const generating = 'AI is reading your notes...';
  static const generatingSub = 'This usually takes 10–20 seconds';

  // Errors
  static const errorGeneric = 'Something went wrong. Please try again.';
  static const errorApiKey = 'Gemini API key missing. Check your .env file.';
  static const errorEmpty = 'Please provide some study material.';
}
