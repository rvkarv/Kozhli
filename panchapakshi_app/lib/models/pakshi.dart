/// The five Panchapakshi birds and their fixed Pancha-bhoota (element).
enum Pakshi {
  vallooru('வல்லூறு', 'Vulture', 'நீலம்', 'Sky/Blue'),
  aandhai('ஆந்தை', 'Owl', 'நீர்', 'Water'),
  kaagam('காகம்', 'Crow', 'காற்று', 'Air'),
  kozhi('கோழி', 'Hen/Cock', 'நெருப்பு', 'Fire'),
  mayil('மயில்', 'Peacock', 'ஆகாயம்', 'Ether/Space');

  final String tamil;
  final String english;
  final String bhoothamTamil;
  final String bhoothamEnglish;

  const Pakshi(this.tamil, this.english, this.bhoothamTamil, this.bhoothamEnglish);
}

/// The five daily activities (தொழில்) every bird cycles through.
enum Thozhil {
  oon('ஊண்', 'Eating', ActivityStrength.good),
  nadai('நடை', 'Walking', ActivityStrength.neutral),
  arasu('அரசு', 'Ruling', ActivityStrength.best),
  thuyil('துயில்', 'Sleeping', ActivityStrength.bad),
  saavu('சாவு', 'Dying', ActivityStrength.worst);

  final String tamil;
  final String english;
  final ActivityStrength strength;

  const Thozhil(this.tamil, this.english, this.strength);
}

enum ActivityStrength { best, good, neutral, bad, worst }

/// Waxing (வளர்பிறை) vs Waning (தேய்பிறை) lunar fortnight.
enum Paksham { valarpirai, theipirai }

enum DayNight { day, night }
