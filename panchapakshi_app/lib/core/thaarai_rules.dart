/// The 9-fold Thaarai (தாரை) cycle — transcribed from your workbook's
/// "தாரை" sheet. The category repeats every 9 stars across all 27
/// nakshatras (offset 0, 9, 18 are all ஜென்ம தாரை; 1, 10, 19 are all
/// சம்பத்து தாரை; and so on).
class ThaaraiCategory {
  final String tamil;
  final String effect;
  const ThaaraiCategory(this.tamil, this.effect);
}

class ThaaraiRules {
  /// Index 0..8, matching offset-from-birth-star mod 9.
  static const List<ThaaraiCategory> categories = [
    ThaaraiCategory('ஜென்ம தாரை', 'அலச்சல், டென்ஷன் தரும்'),
    ThaaraiCategory('சம்பத்து தாரை', 'சம்பத்து, சந்தோசம், தனவரவு, அனுகூலம்'),
    ThaaraiCategory('விபத்து தாரை', 'விபத்து, ஆபத்து, பயணம் பார்த்து செய்ய வேண்டும்'),
    ThaaraiCategory('க்ஷேம தாரை', 'சேமம், சௌபாக்கியம், சுகம், முதலீடுகள் செய்ய'),
    ThaaraiCategory('பிரத்தியக்கு தாரை', 'காரியத் தடை, மனசளிப்பை ஏற்படுத்தும்'),
    ThaaraiCategory('சாதக தாரை', 'சாதகம், தெய்வ அனுகூலம்'),
    ThaaraiCategory('வதை தாரை', 'வேதனை, வம்புசண்டையை ஏற்படுத்தும்'),
    ThaaraiCategory('மைத்ர தாரை', 'நட்பு, தனவரவு, நீண்ட ஆயுள்'),
    ThaaraiCategory('அதிமைத்ர தாரை', 'அதிகமான நட்பை கொடுத்து சளிப்பை தரும்'),
  ];
}
