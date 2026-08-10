/// Thaarai (தாரை) rules transcribed from the workbook sheet
/// "தாரை விதி".
///
/// The category repeats every 9 stars, but the workbook also gives a
/// specific result/effect for each of the 27 positions. Therefore the
/// calculator must use the 1..27 ordinal from the birth nakshatra, not
/// only category % 9.
class ThaaraiCategory {
  final String tamil;
  final String effect;

  const ThaaraiCategory(this.tamil, this.effect);
}

class ThaaraiRules {
  /// 1-based ordinal from the birth nakshatra to the current nakshatra.
  ///
  /// Examples from the verified workbook:
  /// - பூரம் -> திருவாதிரை = 23rd = பிரத்யக்கு தாரை.
  /// - ஆயில்யம் -> திருவாதிரை = 25th = வதை தாரை.
  static const List<ThaaraiCategory> byOrdinal = [
    // 1
    ThaaraiCategory('ஜென்ம தாரை', 'அலச்சல், டென்ஷன் தரும்'),
    // 2
    ThaaraiCategory('சம்பத்து தாரை', 'சம்பத்து, சந்தோசம், தனவரவு, அனுகூலம்'),
    // 3
    ThaaraiCategory('விபத்து தாரை', 'விபத்து, ஆபத்து, பயணம் பார்த்து செய்ய வேண்டும்'),
    // 4
    ThaaraiCategory('க்ஷேம தாரை', 'சேமம், சௌபாக்கியம், சுகம், முதலீடுகள் செய்ய'),
    // 5
    ThaaraiCategory('பிரத்தியக்கு தாரை', 'காரியத் தடை'),
    // 6
    ThaaraiCategory('சாதக தாரை', 'சாதகம், தெய்வ அனுகூலம்'),
    // 7
    ThaaraiCategory('வதை தாரை', 'வேதனை'),
    // 8
    ThaaraiCategory('மைத்ர தாரை', 'நட்பு, தனவரவு, நீண்ட ஆயுள்'),
    // 9
    ThaaraiCategory('அதிமைத்ர தாரை', 'அதிகமான நட்பை கொடுத்து சளிப்பை தரும்'),

    // 10
    ThaaraiCategory('ஜென்ம தாரை', 'கர்மம் நடந்த பின் காரிய வெற்றி தரும்'),
    // 11
    ThaaraiCategory('சம்பத்து தாரை', 'நன்மையும் சுகத்தையும் தரும் ஆனால் சமுதாய பகையை தரும்'),
    // 12
    ThaaraiCategory('விபத்து தாரை', 'தர்ம சங்கடத்தை தரும்'),
    // 13
    ThaaraiCategory('க்ஷேம தாரை', 'நன்மை, ஆயுள் சிறக்க, பதவி உயர்வு பெற, முதலீடு செய்ய, தொழில் துவங்க, எது வேண்டுமானாலும் செய்யலாம்'),
    // 14
    ThaaraiCategory('பிரத்தியக்கு தாரை', 'காரியத் தடை, மனச்சளிப்பை ஏற்படுத்தும்'),
    // 15
    ThaaraiCategory('சாதக தாரை', 'நன்மை, சுபிக்ஷம், தெய்வ அனுகூலம் பெற, தொழில் துவங்க'),
    // 16
    ThaaraiCategory('வதை தாரை', 'வம்புசண்டையை ஏற்படுத்தும்'),
    // 17
    ThaaraiCategory('மைத்ர தாரை', 'அளவான நன்மையை தரும்'),
    // 18
    ThaaraiCategory('அதிமைத்ர தாரை', 'பண பகை தரும் (விநாயகர், ஆஞ்சநேயர் வழிபாடு)'),

    // 19
    ThaaraiCategory('ஜென்ம தாரை', 'கர்ம காரியம் நடக்கும்'),
    // 20
    ThaaraiCategory('சம்பத்து தாரை', 'நன்மை, சிறப்பு, சுபத்தை தரும்'),
    // 21
    ThaaraiCategory('விபத்து தாரை', 'மாறுபாடான நிலையையும் பாதிப்பையும் தரும்'),
    // 22
    ThaaraiCategory('க்ஷேம தாரை', 'வைணாசிக நட்சத்திரம் - தடையை ஏற்படுத்தும்'),
    // 23
    ThaaraiCategory('பிரத்தியக்கு தாரை', 'அதிருத்தியான செயலை ஏற்படுத்தும்'),
    // 24
    ThaaraiCategory('சாதக தாரை', 'சாதகமான நிலையை தரும், இடம் சார்ந்த விஷயங்களை அடைய அனுகூலத்தை தரும்'),
    // 25
    ThaaraiCategory('வதை தாரை', 'எல்லாவிதமான சோதனைகளையும் சங்கடங்களையும் தரும்'),
    // 26
    ThaaraiCategory('மைத்ர தாரை', 'ஜாதிப்பற்றை தரும், நலம், சுபிக்ஷம்'),
    // 27
    ThaaraiCategory('அதிமைத்ர தாரை', 'வணங்கும் நிலை, அபிஷேகத்தை தரும் நட்சத்திரம்'),
  ];

  /// Backwards-compatible 9-category view.
  static List<ThaaraiCategory> get categories => [
        byOrdinal[0],
        byOrdinal[1],
        byOrdinal[2],
        byOrdinal[3],
        byOrdinal[4],
        byOrdinal[5],
        byOrdinal[6],
        byOrdinal[7],
        byOrdinal[8],
      ];

  static ThaaraiCategory forOrdinal(int ordinal1to27) {
    if (ordinal1to27 < 1 || ordinal1to27 > 27) {
      throw ArgumentError.value(
        ordinal1to27,
        'ordinal1to27',
        'must be between 1 and 27',
      );
    }
    return byOrdinal[ordinal1to27 - 1];
  }
}
