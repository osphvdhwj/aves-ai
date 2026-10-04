import 'dart:math';

class AiPrompt {
  final String text;
  final String category;

  const AiPrompt(this.text, this.category);
}

/// Static base library of example prompts shown on the empty AI search surface.
/// Prompts are picked at random per open so the surface never looks the same
/// twice. Dynamic prompts (albums, tags, dates) come from AiPromptService.
class PromptLibrary {
  static const List<AiPrompt> all = [
    // people
    AiPrompt('Photos of my friends', 'people'),
    AiPrompt('Selfies', 'people'),
    AiPrompt('Group photos', 'people'),
    AiPrompt('Photos with family', 'people'),
    AiPrompt('Candid portraits', 'people'),
    AiPrompt('Smiling faces', 'people'),
    AiPrompt('People laughing', 'people'),
    AiPrompt('Baby photos', 'people'),
    AiPrompt('Kids playing', 'people'),
    AiPrompt('Elderly relatives', 'people'),
    AiPrompt('Photos of couples', 'people'),
    AiPrompt('Portraits of one person', 'people'),
    AiPrompt('Birthday party photos', 'people'),
    AiPrompt('Wedding photos', 'people'),
    AiPrompt('Friends at a restaurant', 'people'),

    // places
    AiPrompt('At the beach', 'places'),
    AiPrompt('Mountains', 'places'),
    AiPrompt('City at night', 'places'),
    AiPrompt('Countryside', 'places'),
    AiPrompt('Forest walks', 'places'),
    AiPrompt('Desert landscapes', 'places'),
    AiPrompt('Lakes and rivers', 'places'),
    AiPrompt('Street scenes', 'places'),
    AiPrompt('Airport photos', 'places'),
    AiPrompt('Hotel rooms', 'places'),
    AiPrompt('Rooftops', 'places'),
    AiPrompt('Parks', 'places'),
    AiPrompt('Museums', 'places'),
    AiPrompt('Coffee shops', 'places'),
    AiPrompt('Hiking trails', 'places'),

    // nature
    AiPrompt('Sunsets', 'nature'),
    AiPrompt('Sunrises', 'nature'),
    AiPrompt('Clouds', 'nature'),
    AiPrompt('Starry skies', 'nature'),
    AiPrompt('Flowers', 'nature'),
    AiPrompt('Trees', 'nature'),
    AiPrompt('Snow scenes', 'nature'),
    AiPrompt('Rainy days', 'nature'),
    AiPrompt('Water reflections', 'nature'),
    AiPrompt('Autumn leaves', 'nature'),
    AiPrompt('Spring blossoms', 'nature'),
    AiPrompt('Wild animals', 'nature'),
    AiPrompt('Birds', 'nature'),
    AiPrompt('Insects', 'nature'),
    AiPrompt('Underwater scenes', 'nature'),

    // food
    AiPrompt('Food photos', 'food'),
    AiPrompt('Restaurant meals', 'food'),
    AiPrompt('Home cooking', 'food'),
    AiPrompt('Desserts', 'food'),
    AiPrompt('Coffee and drinks', 'food'),
    AiPrompt('Cocktails', 'food'),
    AiPrompt('Brunch', 'food'),
    AiPrompt('Pizza', 'food'),
    AiPrompt('Baked goods', 'food'),
    AiPrompt('Fresh fruit', 'food'),
    AiPrompt('Street food', 'food'),
    AiPrompt('Wine and cheese', 'food'),

    // animals
    AiPrompt('Pets', 'animals'),
    AiPrompt('Dogs', 'animals'),
    AiPrompt('Cats', 'animals'),
    AiPrompt('Farm animals', 'animals'),
    AiPrompt('Zoo photos', 'animals'),
    AiPrompt('Aquarium photos', 'animals'),
    AiPrompt('Butterflies', 'animals'),
    AiPrompt('Birds in flight', 'animals'),

    // activities
    AiPrompt('Cooking', 'activity'),
    AiPrompt('Traveling', 'activity'),
    AiPrompt('Playing sports', 'activity'),
    AiPrompt('Dancing', 'activity'),
    AiPrompt('Reading', 'activity'),
    AiPrompt('Working out', 'activity'),
    AiPrompt('Shopping', 'activity'),
    AiPrompt('Camping', 'activity'),
    AiPrompt('Swimming', 'activity'),
    AiPrompt('Skiing', 'activity'),
    AiPrompt('Driving', 'activity'),
    AiPrompt('Cycling', 'activity'),
    AiPrompt('Hiking', 'activity'),
    AiPrompt('Gardening', 'activity'),

    // events
    AiPrompt('Party photos', 'event'),
    AiPrompt('Concert photos', 'event'),
    AiPrompt('Sports event', 'event'),
    AiPrompt('Festivals', 'event'),
    AiPrompt('Fireworks', 'event'),
    AiPrompt('Parades', 'event'),
    AiPrompt('Ceremonies', 'event'),
    AiPrompt('Graduation photos', 'event'),

    // documents
    AiPrompt('Receipts', 'document'),
    AiPrompt('Screenshots', 'document'),
    AiPrompt('Documents', 'document'),
    AiPrompt('Business cards', 'document'),
    AiPrompt('Tickets and passes', 'document'),
    AiPrompt('Whiteboard photos', 'document'),
    AiPrompt('Books and pages', 'document'),
    AiPrompt('Signs and labels', 'document'),

    // quality
    AiPrompt('My best photos', 'quality'),
    AiPrompt('Sharp photos', 'quality'),
    AiPrompt('High resolution shots', 'quality'),
    AiPrompt('Blurry photos', 'quality'),
    AiPrompt('Dark photos', 'quality'),
    AiPrompt('Overexposed photos', 'quality'),
    AiPrompt('Videos', 'quality'),
    AiPrompt('Animated photos', 'quality'),
    AiPrompt('Panoramas', 'quality'),
    AiPrompt('Vertical portraits', 'quality'),

    // time
    AiPrompt('Last week', 'time'),
    AiPrompt('Last month', 'time'),
    AiPrompt('This summer', 'time'),
    AiPrompt('Last winter', 'time'),
    AiPrompt('Around holidays', 'time'),
    AiPrompt('Photos from this morning', 'time'),
    AiPrompt('Yesterday', 'time'),
    AiPrompt('Photos from years ago', 'time'),

    // mood
    AiPrompt('Happy moments', 'mood'),
    AiPrompt('Peaceful scenes', 'mood'),
    AiPrompt('Cosy photos', 'mood'),
    AiPrompt('Dramatic lighting', 'mood'),
    AiPrompt('Minimalist photos', 'mood'),
    AiPrompt('Colourful photos', 'mood'),
    AiPrompt('Black and white photos', 'mood'),
  ];

  static const List<String> categories = [
    'people', 'places', 'nature', 'food', 'animals', 'activity',
    'event', 'document', 'quality', 'time', 'mood',
  ];

  /// Pick [count] random prompts, optionally excluding texts already seen.
  static List<AiPrompt> pick(int count, {Set<String> exclude = const {}}) {
    final pool = all.where((p) => !exclude.contains(p.text)).toList();
    pool.shuffle(Random());
    return pool.take(count).toList();
  }
}
